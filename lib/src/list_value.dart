import 'value.dart';

//* List value
mixin ReadonlyListValue<T> on ReadonlyValue<List<T>> {
  T operator [] (int i) => value[i];
  int get length => value.length;
  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;
}

class ListValue<T> extends ReadonlyValue<List<T>> with ReadonlyListValue<T>, PauseResumeForValue<List<T>> implements Value<List<T>> {
  ListValue([Iterable<T>? initialValue, this.debugName])
    : _value = initialValue != null ? List.from(initialValue) : [];

  List<T> _value;
  @override List<T> get value => _value;
  @override set value(List<T> update) { _value = List<T>.from(update); notifyListeners(); }
  @override void set(List<T> update, {bool sendNotifications = true}) {
    _value = List<T>.from(update);

    if (sendNotifications)
      notifyListeners();
  }

  @deprecated @override final distinctMode = false; // not used in ListValue
  @override final String? debugName;

  void operator []= (int i, T update) {
    _value[i] = update;
    notifyListeners(); // unawaited
  }
  void add(T item) { _value.add(item); notifyListeners(); }
  void addIfMissing(T item) { if (!_value.contains(item)) _value.add(item); notifyListeners(); }
  void addAll(Iterable<T> items) { _value.addAll(items); notifyListeners(); }
  void remove(T item) { _value.remove(item); notifyListeners(); }
  void clear() { _value.clear(); notifyListeners(); }
  bool contains(T item) => _value.contains(item);

  void replaceOrAdd(T oldItem, T newItem) {
    final index = _value.indexOf(oldItem);
    if (index >= 0)
      this[index] = newItem;
    else {
      _value.add(newItem);
      notifyListeners();
    }
  }

  void replaceWhereOrAdd(bool Function(T item) test, T newItem) {
    final index = _value.indexWhere(test);
    if (index >= 0)
      this[index] = newItem;
    else {
      _value.add(newItem);
      notifyListeners();
    }
  }

  void removeWhere(bool Function(T item) test) {
    _value.removeWhere(test);
    notifyListeners();
  }

  void removeWhereType<K extends T>() {
    _value.removeWhere((element) => element is K);
    notifyListeners();
  }

  void addOrRemove(T item, bool condition) {
    if (condition && !_value.contains(item)) {
      _value.add(item);
      notifyListeners();
    }
    else if (!condition && _value.contains(item)) {
      _value.remove(item);
      notifyListeners();
    }
  }
}