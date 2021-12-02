import 'dart:async';

import 'package:meta/meta.dart';

import 'value.dart';

abstract class _CombinedValue<R> extends ReadonlyValue<R> {
  _CombinedValue(this._values, this.combiner);
  final List<ReadonlyValue> _values;
  final Function combiner;

  @override R get value => Function.apply(combiner, _values.map<dynamic>((v) => v.value).toList()) as R;

  @override CombinedValueSubscription listen(FutureOr<void> Function(R) listener, {bool sendNow = false, Future<void> Function() onCancel}) {
    FutureOr<void> handler(dynamic _) => listener(value);

    if(sendNow)
      handler(null); // unawaited

    return CombinedValueSubscription._(_values.map((v) => v.listen(handler)).toList());
  }
}

class CombinedValue2<T1, T2, R> extends _CombinedValue<R> {
  CombinedValue2(
    ReadonlyValue<T1> value1,
    ReadonlyValue<T2> value2,
    R Function(T1, T2) combiner
  )
  : super([value1, value2], combiner);
}

class CombinedValue3<T1, T2, T3, R> extends _CombinedValue<R> {
  CombinedValue3(
    ReadonlyValue<T1> value1,
    ReadonlyValue<T2> value2,
    ReadonlyValue<T3> value3,
    R Function(T1, T2, T3) combiner
  )
  : super([value1, value2, value3], combiner);
}

class CombinedValue4<T1, T2, T3, T4, R> extends _CombinedValue<R> {
  CombinedValue4(
    ReadonlyValue<T1> value1,
    ReadonlyValue<T2> value2,
    ReadonlyValue<T3> value3,
    ReadonlyValue<T4> value4,
    R Function(T1, T2, T3, T4) combiner
  )
  : super([value1, value2, value3, value4], combiner);
}

class CombinedValue5<T1, T2, T3, T4, T5, R> extends _CombinedValue<R> {
  CombinedValue5(
    ReadonlyValue<T1> value1,
    ReadonlyValue<T2> value2,
    ReadonlyValue<T3> value3,
    ReadonlyValue<T4> value4,
    ReadonlyValue<T5> value5,
    R Function(T1, T2, T3, T4, T5) combiner
  )
  : super([value1, value2, value3, value4, value5], combiner);
}

class CombinedValue6<T1, T2, T3, T4, T5, T6, R> extends _CombinedValue<R> {
  CombinedValue6(
    ReadonlyValue<T1> value1,
    ReadonlyValue<T2> value2,
    ReadonlyValue<T3> value3,
    ReadonlyValue<T4> value4,
    ReadonlyValue<T5> value5,
    ReadonlyValue<T6> value6,
    R Function(T1, T2, T3, T4, T5, T6) combiner
  )
  : super([value1, value2, value3, value4, value5, value6], combiner);
}


CombinedValueSubscription _combine(List<ReadonlyValue> values, List<ReadonlyValue> triggeredBy, bool sendNow, Function action) {
  FutureOr<void> handler(dynamic _) => Function.apply(action, values.map<dynamic>((v) => v.value).toList());
  if (sendNow)
    handler(null); // unawaited

  return CombinedValueSubscription._((triggeredBy ?? values).map((value) => value.listen(handler)) .toList());
}

ValueSubscription combine2<T1, T2>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  {
    @required FutureOr<void> Function(T1, T2) action,
    List<ReadonlyValue> triggeredBy,
    bool sendNow = false,
  }) => _combine([value1, value2], triggeredBy, sendNow, action);

ValueSubscription combine3<T1, T2, T3>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  ReadonlyValue<T3> value3,
  {
    @required FutureOr<void> Function(T1, T2, T3) action,
    List<ReadonlyValue> triggeredBy,
    bool sendNow = false,
  }) => _combine([value1, value2, value3], triggeredBy, sendNow, action);

ValueSubscription combine4<T1, T2, T3, T4>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  ReadonlyValue<T3> value3,
  ReadonlyValue<T4> value4,
  {
    @required FutureOr<void> Function(T1, T2, T3, T4) action,
    List<ReadonlyValue> triggeredBy,
    bool sendNow = false,
  }) => _combine([value1, value2, value3, value4], triggeredBy, sendNow, action);

ValueSubscription combine5<T1, T2, T3, T4, T5>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  ReadonlyValue<T3> value3,
  ReadonlyValue<T4> value4,
  ReadonlyValue<T5> value5,
  {
    @required FutureOr<void> Function(T1, T2, T3, T4, T5) action,
    List<ReadonlyValue> triggeredBy,
    bool sendNow = false,
  }) => _combine([value1, value2, value3, value4, value5], triggeredBy, sendNow, action);

ValueSubscription combine6<T1, T2, T3, T4, T5, T6>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  ReadonlyValue<T3> value3,
  ReadonlyValue<T4> value4,
  ReadonlyValue<T5> value5,
  ReadonlyValue<T6> value6,
  {
    @required FutureOr<void> Function(T1, T2, T3, T4, T5, T6) action,
    List<ReadonlyValue> triggeredBy,
    bool sendNow = false,
  }) => _combine([value1, value2, value3, value4, value5, value6], triggeredBy, sendNow, action);

ValueSubscription combine7<T1, T2, T3, T4, T5, T6, T7>(
  ReadonlyValue<T1> value1,
  ReadonlyValue<T2> value2,
  ReadonlyValue<T3> value3,
  ReadonlyValue<T4> value4,
  ReadonlyValue<T5> value5,
  ReadonlyValue<T6> value6,
  ReadonlyValue<T7> value7,
  {
    @required FutureOr<void> Function(T1, T2, T3, T4, T5, T6, T7) action,
    List<ReadonlyValue> triggeredBy,
    bool sendNow = false,
  }) => _combine([value1, value2, value3, value4, value5, value6, value7], triggeredBy, sendNow, action);

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
    @required FutureOr<void> Function(T1, T2, T3, T4, T5, T6, T7, T8) action,
    List<ReadonlyValue> triggeredBy,
    bool sendNow = false,
  }) => _combine([value1, value2, value3, value4, value5, value6, value7, value8], triggeredBy, sendNow, action);

ValueSubscription combine(List<ReadonlyValue> values, FutureOr<void> Function() action) {
  FutureOr<void> handler(dynamic _) => action();
  return CombinedValueSubscription._(values.map((value) => value.listen(handler)).toList());
}


class CombinedValueSubscription extends ValueSubscription {
  CombinedValueSubscription._(this._singleSubscriptions);

  final List<ValueSubscription> _singleSubscriptions;

  @override Future<void> cancel() async {
    for(final subscription in _singleSubscriptions.where((s) => !s.isCancelled))
      await subscription.cancel();

    await super.cancel();
  }
}
