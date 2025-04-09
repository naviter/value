import 'dart:async';

import 'list_value.dart';
import 'map_value.dart';
import 'value.dart';

mixin _DebounceValueBase<T> on ReadonlyValue<T> {
  ReadonlyValue<T> get origin;
  Duration get duration;
  @override T get value => origin.value;
  @override String? get debugName => origin.debugName != null ? "Debounce:${origin.debugName}" : null;

  @override ValueSubscription listen(FutureOr<void> Function(T) listener, {bool sendNow = false, void Function()? onCancel, String? debugName}) {
    Timer? timer;

    return origin.listen((newValue) async {
      timer?.cancel();
      timer = Timer(duration, () => listener(newValue));
    }, sendNow: sendNow, onCancel: onCancel, debugName: debugName);
  }
}


class _DebounceValue<T> extends ReadonlyValue<T> with _DebounceValueBase<T> {
  _DebounceValue(this.origin, this.duration);

  @override final ReadonlyValue<T> origin;
  @override final Duration duration;
}
extension DebounceExtension<T> on ReadonlyValue<T> {
  //! Multiple listeners in theory can have different updates coming, because of separate timer instances
  ReadonlyValue<T> debounce(Duration duration) => _DebounceValue(this, duration);
}


class _DebounceListValue<T> extends ReadonlyValue<List<T>> with ReadonlyListValue<T>, _DebounceValueBase<List<T>> {
  _DebounceListValue(this.origin, this.duration);

  @override final ReadonlyListValue<T> origin;
  @override final Duration duration;
}
extension DebounceListExtension<T> on ReadonlyListValue<T> {
  //! Multiple listeners in theory can have different updates coming, because of separate timer instances
  ReadonlyListValue<T> debounceList(Duration duration) => _DebounceListValue(this, duration);
}


class _DebounceMapValue<K, V> extends ReadonlyMapValue<K, V> with _DebounceValueBase<Map<K, V>> {
  _DebounceMapValue(this.origin, this.duration);

  @override final ReadonlyMapValue<K, V> origin;
  @override final Duration duration;
}
extension DebounceMapExtension<K, V> on ReadonlyMapValue<K, V> {
  //! Multiple listeners in theory can have different updates coming, because of separate timer instances
  ReadonlyMapValue<K, V> debounceMap(Duration duration) => _DebounceMapValue(this, duration);
}