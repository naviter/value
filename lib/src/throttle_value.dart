import 'dart:async';

import 'list_value.dart';
import 'map_value.dart';
import 'value.dart';

mixin _ThrottleValueBase<T> on ReadonlyValue<T> {
  ReadonlyValue<T> get origin;
  Duration get period;
  @override T get value => origin.value;
  @override String? get debugName => origin.debugName != null ? "Throttle:${origin.debugName}" : null;

  @override ValueSubscription listen(FutureOr<void> Function(T) listener, {bool sendNow = false, void Function()? onCancel, String? debugName}) {
    Timer? followUpTimer;
    DateTime? lastListenerCalled;

    return origin.listen((newValue) async {
      followUpTimer?.cancel();
      final now = DateTime.now();

      Future<void> sendUpdate() async {
        lastListenerCalled = now;
        await listener(newValue);
      }

      final timestampToCallListener = lastListenerCalled?.add(period);

      if (timestampToCallListener != null && timestampToCallListener.isAfter(now)) {
        // Skip sending result now, but send it with _followUpTimer
        followUpTimer = Timer(timestampToCallListener.difference(now), sendUpdate); // after "period"
      }
      else
        await sendUpdate();
    }, sendNow: sendNow, onCancel: onCancel, debugName: debugName);
  }
}


class _ThrottleValue<T> extends ReadonlyValue<T> with _ThrottleValueBase<T> {
  _ThrottleValue(this.origin, this.period);

  @override final ReadonlyValue<T> origin;
  @override final Duration period;
}
extension ThrottleExtension<T> on ReadonlyValue<T> {
  //! Multiple listeners in theory can have different updates coming, because of separate timer instances
  ReadonlyValue<T> throttle(Duration period) => _ThrottleValue(this, period);
}


class _ThrottleListValue<T> extends ReadonlyValue<List<T>> with ReadonlyListValue<T>, _ThrottleValueBase<List<T>>{
  _ThrottleListValue(this.origin, this.period);

  @override final ReadonlyListValue<T> origin;
  @override final Duration period;
}
extension ThrottleListExtension<T> on ReadonlyListValue<T> {
  //! Multiple listeners in theory can have different updates coming, because of separate timer instances
  ReadonlyListValue<T> throttleList(Duration period) => _ThrottleListValue(this, period);
}


class _ThrottleMapValue<K, V> extends ReadonlyMapValue<K, V> with _ThrottleValueBase<Map<K, V>> {
  _ThrottleMapValue(this.origin, this.period);

  @override final ReadonlyMapValue<K, V> origin;
  @override final Duration period;
}
extension ThrottleMapExtension<K, V> on ReadonlyMapValue<K, V> {
  //! Multiple listeners in theory can have different updates coming, because of separate timer instances
  ReadonlyMapValue<K, V> throttleMap(Duration period) => _ThrottleMapValue(this, period);
}