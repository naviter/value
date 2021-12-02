import 'dart:async';

import 'list_value.dart';
import 'value.dart';


//* Extensions
extension TransformExtension<T> on ReadonlyValue<T> {
  ReadonlyValue<R> transform<R>(R Function(T) transformer, {bool distinctMode = true})
    => _TransformedValue(this, transformer, distinctMode: distinctMode);

  Value<R> transformWithMethodUpdate<R>(R Function(T) transformer, FutureOr<void> Function(R) update, {bool distinctMode = true})
    => _TransformedValueWithMethodUpdate(this, transformer, update, distinctMode: distinctMode);
}

extension TwoWayTransformExtension<T> on Value<T> {
  Value<R> twoWayTransform<R>(R Function(T) transformer, T Function(R) backTransformer) => _TwoWayTransformedValue(this, transformer, backTransformer);
}

extension TransformedListExtension<T> on ReadonlyListValue<T> {
  ReadonlyListValue<R> transformList<R>(R Function(T) transformer, {bool Function(T) filter, int Function(R, R) sort})
    => _TransformedListValue(this, transformer, filter: filter, sort: sort);
}


//* Implementation
class _TransformedValue<T, R> extends ReadonlyValue<R> {
  _TransformedValue(this.origin, this.transformer, {this.distinctMode = true});

  final ReadonlyValue<T> origin;
  final R Function(T) transformer;
  bool distinctMode;

  @override R get value => transformer(origin.value);
  R _previousValue;

  @override ValueSubscription listen(FutureOr<void> Function(R) listener, {bool sendNow = false, Future<void> Function() onCancel}) {
    return origin.listen((newValue) async {
      R transformedValue;
      if (!distinctMode || (transformedValue = transformer(newValue)) != _previousValue) {
        await listener(transformedValue);
        _previousValue = transformedValue;
      }
    }, sendNow: sendNow);
  }
}

class _TransformedListValue<T, R> extends ReadonlyListValue<R> {
  _TransformedListValue(this.origin, this.transformer, {this.filter, this.sort});

  final ReadonlyValue<List<T>> origin;
  final R Function(T) transformer;
  final bool Function(T) filter;
  final int Function(R, R) sort;

  @override List<R> get value => _transformList(origin.value);

  @override ValueSubscription listen(FutureOr<void> Function(List<R>) listener, {bool sendNow = false, Future<void> Function() onCancel})
    => origin.listen((newValue) => listener(_transformList(newValue)), sendNow: sendNow);

  List<R> _transformList(List<T> source) {
    if (source == null)
      return null;

    final filteredList = filter != null ? source.where(filter) : source;
    final transformedList = filteredList.map(transformer).toList();
    if (sort != null)
      transformedList.sort(sort);
    return transformedList;
  }
}


class _TransformedValueWithMethodUpdate<T, R> extends _TransformedValue<T, R> with PauseResumeForValue<R> implements Value<R> {
  _TransformedValueWithMethodUpdate(this.origin, R Function(T) transformer, this.updateMethod, {bool distinctMode = true})
    : super(origin, transformer, distinctMode: distinctMode);

  final FutureOr<void> Function(R) updateMethod;

  // ignore: overridden_fields
  @override final ReadonlyValue<T> origin;

  @override R get value => transformer(origin.value);
  @override Future<void> set(R update) async => updateMethod(update);
  @override Future<void> notifyListeners([R update]) async => updateMethod(update);
}


class _TwoWayTransformedValue<T, R> extends _TransformedValueWithMethodUpdate<T, R> {
  _TwoWayTransformedValue(this.origin, R Function(T) transformer, this.backTransformer, {bool distinctMode = true})
    : super(origin, transformer, (update) async => origin.set(backTransformer(update)), distinctMode: distinctMode);

  final T Function(R) backTransformer;

  // ignore: overridden_fields, origin is generalized ReadonlyValue -> Value, because two way transform makes no sense for ReadonlyValue
  @override final Value<T> origin;

  @override Future<void> notifyListeners([R update]) async => origin.notifyListeners(backTransformer(update));
}