import 'dart:async';

import 'value.dart';

extension ThrottleExtension<T> on ReadonlyValue<T> {
  ReadonlyValue<T> throttle(Duration period, {DateTime Function() currentTimeProvider, T Function(List<T>) averager})
    => _ThrottleValue(this, period, currentTimeProvider: currentTimeProvider);
}

extension DoubleAveragedThrottleExtension on ReadonlyValue<double> {
  ReadonlyValue<double> averagedThrottle(Duration period, {DateTime Function() currentTimeProvider})
    => _ThrottleValue(this, period, currentTimeProvider: currentTimeProvider, averager: _averager);

  double _averager(List<double> _buffer) {
    final filtered = _buffer.where((element) => element != null && element.isFinite).toList();
    return filtered.isNotEmpty
      ? filtered.reduce((a, b) => a + b) / filtered.length
      : null;
  }
}

class _ThrottleValue<T> extends ReadonlyValue<T> {
  _ThrottleValue(this.origin, this.period, {this.currentTimeProvider, this.averager});

  final ReadonlyValue<T> origin;
  final Duration period;
  final DateTime Function() currentTimeProvider;

  /// If averager is not provided, only the last update in period is propagated further
  final T Function(List<T>) averager;

  @override T get value => origin.value;
  DateTime _lastUpdated;

  final _buffer = <T>[];

  @override ValueSubscription listen(FutureOr<void> Function(T) listener, {bool sendNow = false}) {
    return origin.listen((newValue) async {
      if (averager != null && newValue != null)
        _buffer.add(newValue);

      final now = currentTimeProvider?.call() ?? DateTime.now();

      if (_lastUpdated != null) {
        if (now.isBefore(_lastUpdated)) { // Jump back in time
          _buffer.clear();
          _lastUpdated = now;
          await listener(newValue);
          return;
        }
        else if (now.isBefore(_lastUpdated.add(period)))
          return; // Throttle the result
      }

      _lastUpdated = now;
      final valueToSend = averager == null || _buffer.length <= 1 ? newValue : (averager.call(_buffer) ?? newValue);
      _buffer.clear();
      await listener(valueToSend);
    }, sendNow: sendNow);
  }
}