import 'value.dart';

abstract class ReadonlyMapValue<K, T> extends ReadonlyValue<Map<K, T>> {
  T? operator [] (K key) => value[key];
  int get length => value.length;
  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;
}

class MapValue<K, T> extends ReadonlyMapValue<K, T> with PauseResumeForValue<Map<K, T>> implements Value<Map<K, T>> {
  MapValue([Map<K, T>? initialValue, this.debugName])
  : _value = initialValue != null ? Map.from(initialValue) : {};

  Map<K, T> _value;
  @override Map<K, T> get value => _value;
  @override set value(Map<K, T> update) => set(update);
  @deprecated @override final distinctMode = false; // not used in MapValue
  @override String? debugName;

  @override
  Future<void> set(Map<K, T> update, {bool sendNotifications = true}) async {
    _value = Map<K, T>.from(update);
    if (sendNotifications)
      notifyListeners();
  }

  void operator []=(K key, T update) {
    _value[key] = update;
    notifyListeners();
  }

  bool containsKey(K key) => _value.containsKey(key);
  void remove(K key) { _value.remove(key); notifyListeners(); }
  void clear() { _value.clear(); notifyListeners(); }

  void removeWhere(bool Function(K key, T value) test) {
    if (_value.entries.any((element) => test(element.key, element.value))) {
      _value.removeWhere(test);
      notifyListeners();
    }
  }
}