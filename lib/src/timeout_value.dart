import 'dart:async';

import 'value.dart';

extension TimeoutExtension<T> on ReadonlyValue<T> {
  _TimeoutValue<T> timeout(Duration timeout, {T valueOnTimeout}) => _TimeoutValue<T>(this, timeout, valueOnTimeout: valueOnTimeout);
}

class _TimeoutValue<T> extends ReadonlyValue<T> {
  _TimeoutValue(this.origin, this.duration, {this.valueOnTimeout});

  final ReadonlyValue<T> origin;
  final Duration duration;
  final T valueOnTimeout;
  bool get isTimedOut => _timer?.isActive == false;
  Timer _timer;

  @override T get value => isTimedOut ? valueOnTimeout : origin.value;

  @override ValueSubscription listen(FutureOr<void> Function(T) listener, {bool sendNow = false}) {
    return origin.listen((T update) async {
      _timer?.cancel();
      _timer = Timer(duration, () => listener(valueOnTimeout));

      await listener(update);
    }, sendNow: sendNow);
  }
}