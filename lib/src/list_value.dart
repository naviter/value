import 'value.dart';

//* List value
abstract class ReadonlyListValue<T> extends ReadonlyValue<List<T>> {
  T operator [] (int i) => value[i];
  int get length => value.length;
  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;
}

class ListValue<T> extends ReadonlyListValue<T> with PauseResumeForValue<List<T>> implements Value<List<T>> {
  ListValue({Iterable<T> initialValue, this.distinctMode = false})
    : _value = initialValue != null ? List.from(initialValue) : [];

  final List<T> _value;
  @override List<T> get value => _value;
  
  @override
  Future<void> set(List<T> update) async {
    _value..clear()
      ..addAll(update);

    await notifyListeners();
  }

  @override final bool distinctMode;

  void operator []= (int i, T update) {
    if (!distinctMode || update != _value[i]) {
      _value[i] = update;
      notifyListeners(); // unawaited
    }
  }

  Future<void> add(T item) { _value.add(item); return notifyListeners(); }
  Future<void> addAll(Iterable<T> items) { _value.addAll(items); return notifyListeners(); }
  Future<void> remove(T item) { _value.remove(item); return notifyListeners(); }
  Future<void> clear() { _value.clear(); return notifyListeners(); }
  bool contains(T item) => _value.contains(item);

  Future<void> replaceOrAdd(T oldItem, T newItem) async {
    final index = _value.indexOf(oldItem);
    if (index >= 0)
      this[index] = newItem;
    else
      _value.add(newItem);

    await notifyListeners();
  }

  Future<void> replaceWhereOrAdd(bool Function(T item) test, T newItem) async {
    final index = _value.indexWhere(test);
    if (index >= 0)
      this[index] = newItem;
    else
      _value.add(newItem);

    await notifyListeners();
  }

  Future<void> removeWhere(bool Function(T item) test) async {
    _value.removeWhere(test);
    await notifyListeners();
  }

  Future<void> removeWhereType<K extends T>() async {
    _value.removeWhere((element) => element is K);
    await notifyListeners();
  }

  Future<void> addOrRemove(T item, bool condition) async {
    if (condition && !_value.contains(item))
      _value.add(item);
    else if (!condition && _value.contains(item))
      _value.remove(item);

    await notifyListeners();
  }
}