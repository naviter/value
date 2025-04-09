import 'package:flutter/foundation.dart';
import 'package:value/value.dart';

class _ListenableValue<T> implements Listenable {
  _ListenableValue(this.origin);

  final ReadonlyValue<T> origin;
  final _subscriptions = <VoidCallback, ValueSubscription>{};

  @override
  void addListener(VoidCallback listener)
    => _subscriptions[listener] = origin.listen((_) => listener());

  @override
  void removeListener(VoidCallback listener)
    => _subscriptions.remove(listener);
}

extension ValueAsListenable<T> on ReadonlyValue<T> {
  Listenable toListenable() => _ListenableValue<T>(this);
}