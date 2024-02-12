import 'dart:async';

import 'value.dart';

abstract class _CombinedValue<R> extends ReadonlyValue<R> {
  _CombinedValue(this._values, this.combiner, this.distinctMode);
  final List<ReadonlyValue> _values;
  final Function combiner;
  final bool distinctMode;

  @override R get value => Function.apply(combiner, _values.map((v) => v.value).toList()) as R;

  @override
  CombinedValueSubscription listen(FutureOr<void> Function(R) action, {bool sendNow = false, void Function()? onCancel}) {
    assert(onCancel == null, "onCancel is not supported in CombinedValueSubscription");

    /// Last known state of all the values
    final states = <ReadonlyValue, dynamic>{};
    late R previousValue;

    R calculateState() => Function.apply(combiner, states.values.toList()) as R;

    FutureOr<void> handler() async {
      final update = calculateState();

      if (!distinctMode || update != previousValue) {
        previousValue = update;
        await action(update);
      }
    }

    for (final value in _values)
      states[value] = value.value;

    previousValue = calculateState();

    if (sendNow)
      Timer.run(() => _tryCallListener(() async => action(previousValue)));

    return CombinedValueSubscription._(_values.map((value) => value.listen((dynamic update) {
      states[value] = update;
      _tryCallListener(handler);
    })).toList());
  }
}

class CombinedValue2<T1, T2, R> extends _CombinedValue<R> {
  CombinedValue2(
    ReadonlyValue<T1> value1,
    ReadonlyValue<T2> value2,
    R Function(T1, T2) combiner,
    {bool distinctMode = false,}
  )
  : super([value1, value2], combiner, distinctMode);
}

class CombinedValue3<T1, T2, T3, R> extends _CombinedValue<R> {
  CombinedValue3(
    ReadonlyValue<T1> value1,
    ReadonlyValue<T2> value2,
    ReadonlyValue<T3> value3,
    R Function(T1, T2, T3) combiner,
    {bool distinctMode = false,}
  )
  : super([value1, value2, value3], combiner, distinctMode);
}

class CombinedValue4<T1, T2, T3, T4, R> extends _CombinedValue<R> {
  CombinedValue4(
    ReadonlyValue<T1> value1,
    ReadonlyValue<T2> value2,
    ReadonlyValue<T3> value3,
    ReadonlyValue<T4> value4,
    R Function(T1, T2, T3, T4) combiner,
    {bool distinctMode = false,}
  )
  : super([value1, value2, value3, value4], combiner, distinctMode);
}

class CombinedValue5<T1, T2, T3, T4, T5, R> extends _CombinedValue<R> {
  CombinedValue5(
    ReadonlyValue<T1> value1,
    ReadonlyValue<T2> value2,
    ReadonlyValue<T3> value3,
    ReadonlyValue<T4> value4,
    ReadonlyValue<T5> value5,
    R Function(T1, T2, T3, T4, T5) combiner,
    {bool distinctMode = false,}
  )
  : super([value1, value2, value3, value4, value5], combiner, distinctMode);
}

class CombinedValue6<T1, T2, T3, T4, T5, T6, R> extends _CombinedValue<R> {
  CombinedValue6(
    ReadonlyValue<T1> value1,
    ReadonlyValue<T2> value2,
    ReadonlyValue<T3> value3,
    ReadonlyValue<T4> value4,
    ReadonlyValue<T5> value5,
    ReadonlyValue<T6> value6,
    R Function(T1, T2, T3, T4, T5, T6) combiner,
    {bool distinctMode = false,}
  )
  : super([value1, value2, value3, value4, value5, value6], combiner, distinctMode);
}


CombinedValueSubscription _combine(List<ReadonlyValue> values, List<ReadonlyValue>? triggeredBy, bool sendNow, Function action) {
  /// Last known state of all the values
  final states = <ReadonlyValue, dynamic>{};

  /// Handler is applied on last known state instead of current value state
  dynamic handler() => Function.apply(action, states.values.toList());

  /// Initialization of states
  for (final value in values)
    states[value] = value.value;

  if (sendNow)
    _tryCallListener(handler);

  return CombinedValueSubscription._(values.map((value) => value.listen((dynamic update) {
    states[value] = update;

    if (triggeredBy == null || triggeredBy.contains(value))
      _tryCallListener(handler);
  })).toList());
}

ValueSubscription combine2<T1, T2>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  {
    required FutureOr<void> Function(T1, T2) action,
    List<ReadonlyValue>? triggeredBy,
    bool sendNow = false,
  }) {
  return _combine(
      [value1, value2],
      triggeredBy,
      sendNow,
      action,
    );
}

ValueSubscription combine3<T1, T2, T3>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  ReadonlyValue<T3> value3,
  {
    required FutureOr<void> Function(T1, T2, T3) action,
    List<ReadonlyValue>? triggeredBy,
    bool sendNow = false,
  }) =>
    _combine(
      [value1, value2, value3],
      triggeredBy,
      sendNow,
      action,
    );

ValueSubscription combine4<T1, T2, T3, T4>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  ReadonlyValue<T3> value3,
  ReadonlyValue<T4> value4,
  {
    required FutureOr<void> Function(T1, T2, T3, T4) action,
    List<ReadonlyValue>? triggeredBy,
    bool sendNow = false,
  }) =>
    _combine(
      [value1, value2, value3, value4],
      triggeredBy,
      sendNow,
      action,
    );

ValueSubscription combine5<T1, T2, T3, T4, T5>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  ReadonlyValue<T3> value3,
  ReadonlyValue<T4> value4,
  ReadonlyValue<T5> value5,
  {
    required FutureOr<void> Function(T1, T2, T3, T4, T5) action,
    List<ReadonlyValue>? triggeredBy,
    bool sendNow = false,
  }) =>
    _combine(
      [value1, value2, value3, value4, value5],
      triggeredBy,
      sendNow,
      action,
    );

ValueSubscription combine6<T1, T2, T3, T4, T5, T6>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  ReadonlyValue<T3> value3,
  ReadonlyValue<T4> value4,
  ReadonlyValue<T5> value5,
  ReadonlyValue<T6> value6, {
  required FutureOr<void> Function(T1, T2, T3, T4, T5, T6) action,
  List<ReadonlyValue>? triggeredBy,
  bool sendNow = false,
}) =>
    _combine(
      [value1, value2, value3, value4, value5, value6],
      triggeredBy,
      sendNow,
      action,
    );

ValueSubscription combine7<T1, T2, T3, T4, T5, T6, T7>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  ReadonlyValue<T3> value3,
  ReadonlyValue<T4> value4,
  ReadonlyValue<T5> value5,
  ReadonlyValue<T6> value6,
  ReadonlyValue<T7> value7, {
  required FutureOr<void> Function(T1, T2, T3, T4, T5, T6, T7) action,
  List<ReadonlyValue>? triggeredBy,
  bool sendNow = false,
}) =>
    _combine(
      [value1, value2, value3, value4, value5, value6, value7],
      triggeredBy,
      sendNow,
      action,
    );

ValueSubscription combine8<T1, T2, T3, T4, T5, T6, T7, T8>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  ReadonlyValue<T3> value3,
  ReadonlyValue<T4> value4,
  ReadonlyValue<T5> value5,
  ReadonlyValue<T6> value6,
  ReadonlyValue<T7> value7,
  ReadonlyValue<T8> value8,
  {
    required FutureOr<void> Function(T1, T2, T3, T4, T5, T6, T7, T8) action,
    List<ReadonlyValue>? triggeredBy,
    bool sendNow = false,
  }) =>
    _combine(
      [value1, value2, value3, value4, value5, value6, value7, value8],
      triggeredBy,
      sendNow,
      action,
    );


ValueSubscription combine9<T1, T2, T3, T4, T5, T6, T7, T8, T9>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  ReadonlyValue<T3> value3,
  ReadonlyValue<T4> value4,
  ReadonlyValue<T5> value5,
  ReadonlyValue<T6> value6,
  ReadonlyValue<T7> value7,
  ReadonlyValue<T8> value8,
  ReadonlyValue<T9> value9,
  {
    required FutureOr<void> Function(T1, T2, T3, T4, T5, T6, T7, T8, T9) action,
    List<ReadonlyValue>? triggeredBy,
    bool sendNow = false,
  }) =>
    _combine(
      [value1, value2, value3, value4, value5, value6, value7, value8, value9],
      triggeredBy,
      sendNow,
      action,
    );

ValueSubscription combine10<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  ReadonlyValue<T3> value3,
  ReadonlyValue<T4> value4,
  ReadonlyValue<T5> value5,
  ReadonlyValue<T6> value6,
  ReadonlyValue<T7> value7,
  ReadonlyValue<T8> value8,
  ReadonlyValue<T9> value9,
  ReadonlyValue<T10> value10,
  {
    required FutureOr<void> Function(T1, T2, T3, T4, T5, T6, T7, T8, T9, T10) action,
    List<ReadonlyValue>? triggeredBy,
    bool sendNow = false,
  }) =>
    _combine(
      [value1, value2, value3, value4, value5, value6, value7, value8, value9, value10],
      triggeredBy,
      sendNow,
      action,
    );

/// Triggers action() on every update of every Value.
/// ! accessing Value.value in handler gives it's current state, but not the state at the moment when handler execution was scheduled
ValueSubscription combine(List<ReadonlyValue> values, FutureOr<void> Function() action, {bool sendNow = false}) {
  FutureOr<void> handler(dynamic _) => action();
  if (sendNow)
    handler(null); // unawaited
  return CombinedValueSubscription._(values.map((value) => value.listen(handler)).toList());
}


class CombinedValueSubscription extends ValueSubscription {
  CombinedValueSubscription._(this._singleSubscriptions, {void Function()? onCancel}) : super(onCancel);

  final List<ValueSubscription> _singleSubscriptions;

  @override
  void cancel() {
    for(final subscription in _singleSubscriptions.where((s) => !s.isCancelled))
      subscription.cancel();

    super.cancel();
  }
}

Future<void> _tryCallListener(FutureOr Function() handler) async {
  try {
    await handler();
  }
  catch (e) {
    ReadonlyValue.log("⚡", "Unhandled exception in combined value listener: $e");

    if (e is Error)
      ReadonlyValue.log("📛", e.stackTrace.toString());
  }
}