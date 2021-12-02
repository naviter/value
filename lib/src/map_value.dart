import 'value.dart';

abstract class ReadonlyMapValue<K, T> extends ReadonlyValue<Map<K, T>> {
  T operator [] (K key) => value[key];
  int get length => value.length;
  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;
}

class MapValue<K, T> extends ReadonlyMapValue<K, T> with PauseResumeForValue<Map<K, T>> implements Value<Map<K, T>> {
  MapValue([Map<K, T> initialValue, this.distinctMode = true])
    : _value = initialValue != null ? Map.from(initialValue) : {};

  final Map<K, T> _value;
  @override Map<K, T> get value => _value;

  @override
  Future<void> set(Map<K, T> update) async {
    _value..clear()
      ..addAll(update);

    await notifyListeners();
  }

  @override bool distinctMode;

  void operator []= (K key, T update) {
    if (!distinctMode || update != _value[key]) {
      _value[key] = update;
      notifyListeners(); // unawaited
    }
  }

  bool containsKey(K key) => _value.containsKey(key);
  void remove(K key) { _value.remove(key); notifyListeners(); }
  void clear() { _value.clear(); notifyListeners(); }
}