import 'dart:async';

import 'list_value.dart';
import 'value.dart';

class _TransformedValue<T, R> extends ReadonlyValue<R> {
  _TransformedValue(this.origin, this.transformer, this.distinctMode);

  final ReadonlyValue<T> origin;
  final R Function(T) transformer;
  bool distinctMode;
  @override String? get debugName => origin.debugName != null ? "Transform:${origin.debugName}" : null;

  @override R get value => transformer(origin.value);

  @override ValueSubscription listen(FutureOr<void> Function(R) listener, {bool sendNow = false, void Function()? onCancel, String? debugName}) {
    R? previousValue;

    return origin.listen((newValue) async {
      final transformedValue = transformer(newValue);
      if (!distinctMode || transformedValue != previousValue) {
        previousValue = transformedValue;
        await listener(transformedValue);
      }
    }, sendNow: sendNow, onCancel: onCancel, debugName: debugName);
  }
}

class _TransformedListValue<T, R> extends ReadonlyValue<List<R>> with ReadonlyListValue<R> {
  _TransformedListValue(this.origin, this.transformer);

  final ReadonlyValue<List<T>> origin;
  final R Function(T) transformer;
  @override String? get debugName => origin.debugName != null ? "TransformList:${origin.debugName}" : null;

  @override List<R> get value => _transformList(origin.value);

  @override ValueSubscription listen(FutureOr<void> Function(List<R>) listener, {bool sendNow = false, void Function()? onCancel, String? debugName})
    => origin.listen((newValue) => listener(_transformList(newValue)), sendNow: sendNow, onCancel: onCancel, debugName: debugName);

  List<R> _transformList(List<T> source) => source.map(transformer).toList();
}

class _FilteredListValue<T> extends ReadonlyValue<List<T>> with ReadonlyListValue<T> {
  _FilteredListValue(this.origin, this.filter, this.sort);

  final ReadonlyValue<List<T>> origin;
  final bool Function(T) filter;
  final int Function(T, T)? sort;
  @override String? get debugName => origin.debugName != null ? "FilterList:${origin.debugName}" : null;

  @override List<T> get value => _filterList(origin.value);

  @override ValueSubscription listen(FutureOr<void> Function(List<T>) listener, {bool sendNow = false, void Function()? onCancel, String? debugName})
    => origin.listen((newValue) => listener(_filterList(newValue)), sendNow: sendNow, onCancel: onCancel, debugName: debugName);

  List<T> _filterList(List<T> source) {
    final filteredList = source.where(filter).toList();

    if (sort != null)
      filteredList.sort(sort);
    return filteredList;
  }
}


class _TransformedValueWithMethodUpdate<T, R> extends _TransformedValue<T, R> with PauseResumeForValue<R> implements Value<R> {
  _TransformedValueWithMethodUpdate(super.origin, super.transformer, this.updateMethod, super.distinctMode);

  final FutureOr<void> Function(R) updateMethod;

  @override set value(R newValue) => updateMethod(newValue);
  @override Future<void> set(R update, {bool sendNotifications = true}) async {
    if (!sendNotifications)
      throw UnimplementedError("sendNotifications == false is not implmemented in transformWithMethodUpdate");
    return updateMethod(update);
  }

  @override void notifyListeners() => updateMethod(value);
}


class _TwoWayTransformedValue<T, R> extends _TransformedValueWithMethodUpdate<T, R> {
  _TwoWayTransformedValue(this.origin, R Function(T) transformer, this.backTransformer, bool distinctMode)
    : super(origin, transformer, (update) => origin.value = backTransformer(update), distinctMode);

  final T Function(R) backTransformer;

  // ignore: overridden_fields, origin is generalized ReadonlyValue -> Value, because two way transform makes no sense for ReadonlyValue
  @override final Value<T> origin;
}


//* Extensions
extension TransformExtension<T> on ReadonlyValue<T> {
  ReadonlyValue<R> transform<R>(R Function(T) transformer, {bool distinctMode = true})
    => _TransformedValue(this, transformer, distinctMode);

  Value<R> transformWithMethodUpdate<R>(R Function(T) transformer, FutureOr<void> Function(R) update, {bool distinctMode = true})
    => _TransformedValueWithMethodUpdate(this, transformer, update, distinctMode);
}

extension InvertBooleanValueExtension on ReadonlyValue<bool> {
  ReadonlyValue<bool> invert({bool distinctMode = true}) => transform((x) => !x, distinctMode: distinctMode);
}

extension TwoWayTransformExtension<T> on Value<T> {
  Value<R> twoWayTransform<R>(R Function(T) transformer, T Function(R) backTransformer, {bool distinctMode = true})
    => _TwoWayTransformedValue(this, transformer, backTransformer, distinctMode);
}

extension TransformedListExtension<T> on ReadonlyListValue<T> {
  ReadonlyListValue<R> transformList<R>(R Function(T) transformer)
    => _TransformedListValue(this, transformer);

  ReadonlyListValue<T> filter(bool Function(T) filter, {int Function(T, T)? sort})
    => _FilteredListValue(this, filter, sort);
}