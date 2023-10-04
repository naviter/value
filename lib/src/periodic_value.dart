import 'dart:async';

import 'value.dart';

class PeriodicValue extends ReadonlyValue<DateTime> {
  PeriodicValue(this.duration)
  : _lastPublishedValue = DateTime.now();

  final Duration duration;
  Timer? _timer;

  @override DateTime get value => _lastPublishedValue;
  DateTime _lastPublishedValue;

  @override ValueSubscription listen(FutureOr<void> Function(DateTime) listener, {bool sendNow = false, void Function()? onCancel}) {
    if(_timer == null)
      _resetTimeout();

    return super.listen(listener, sendNow: sendNow, onCancel: (){
      if (!hasListeners)
        _timer?.cancel();

      onCancel?.call();
    });
  }

  void _resetTimeout() {
    _timer?.cancel();
    _timer = Timer.periodic(duration, (_) {
      final now = DateTime.now();
      _lastPublishedValue = now;
      notifyListeners();
    });
  }
}