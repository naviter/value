import 'dart:async';

import 'value.dart';

class TimeoutValue<T> extends Value<T?> {
  TimeoutValue(this.timeout, {bool distinctMode = true})
    : super(null, distinctMode: distinctMode);

  final Duration timeout;
  Timer? _timer;

  @override
  set value(T? update) {
    super.value = update;

    _timer?.cancel();
    if (update != null)
      _timer = Timer(timeout, () => set(null));
  }
}



//! Using TimeoutValue on Value with distinctMode=true can cause unwanted timing out if original value is updated with the same value periodically
class _TimeoutExtensionValue<T> extends ReadonlyValue<T?> {
  _TimeoutExtensionValue(this.origin, this.duration);

  final ReadonlyValue<T> origin;
  final Duration duration;

  @override T? get value => isTimedOut ? null : origin.value;
  bool get isTimedOut => _activeTimersCounter == 0;
  int _activeTimersCounter = 0;

  @override ValueSubscription listen(FutureOr<void> Function(T?) listener, {bool sendNow = false, void Function()? onCancel}) {
    Timer? timer;

    return origin.listen((update) async {
      if(timer != null) {
        timer!.cancel();
        _activeTimersCounter--;
      }

      timer = Timer(duration, () {
        _activeTimersCounter--;
        listener(null);
      });
      _activeTimersCounter++;

      await listener(update);
    }, sendNow: sendNow, onCancel: onCancel);
  }
}


extension TimeoutExtension<T> on ReadonlyValue<T> {
  _TimeoutExtensionValue<T> timeout(Duration timeout) => _TimeoutExtensionValue<T>(this, timeout);
}