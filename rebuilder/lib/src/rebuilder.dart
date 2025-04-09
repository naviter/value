import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:value/value.dart';

abstract class _RebuilderBase extends StatefulWidget {
  const _RebuilderBase(this.values, this.rebuildWhen, this.builder, this.noDataBuilder);

  final List<ReadonlyValue> values;
  final ReadonlyValue? rebuildWhen; // optional stream for triggering widget rebuilds
  final Function builder;
  final Widget Function(BuildContext context)? noDataBuilder;

  @override _RebuilderBaseState createState() => _RebuilderBaseState<_RebuilderBase>();
}

class _RebuilderBaseState<TWidget extends _RebuilderBase> extends State<TWidget> {
  late ValueSubscription subscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    subscription = obtainSubscription();
  }

  @protected
  ValueSubscription obtainSubscription() => widget.rebuildWhen != null
    ? widget.rebuildWhen!.listen(_valueChanged)
    : combine(widget.values, () => _valueChanged(null), sendNow: true);

  void _valueChanged(dynamic _) {
    Timer.run((){
      if (mounted && !_isDisposed)
        setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentValues = widget.values.map((element) => element.value).toList();
    return widget.noDataBuilder != null && currentValues.any((dynamic element) => element == null)
      ? widget.noDataBuilder!(context)
      : Function.apply(widget.builder, [context, ...currentValues]) as Widget;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<List<ReadonlyValue>>('values', widget.values))
      ..add(DiagnosticsProperty<Function>('builder', widget.builder))
      ..add(DiagnosticsProperty<Function>('noDataBuilder', widget.noDataBuilder));
  }

  @override
  void dispose() {
    _isDisposed = true;
    subscription.cancel();
    super.dispose();
  }}


class Rebuilder<T> extends _RebuilderBase {
  Rebuilder({
    required ReadonlyValue<T> value,
    ReadonlyValue? rebuildWhen,
    required Widget Function(BuildContext context, T) builder,
    Widget Function(BuildContext context)? noDataBuilder,
  }) : super([value], rebuildWhen, builder, noDataBuilder);

  late final ReadonlyValue<T> value = values.single as ReadonlyValue<T>;

  @override _RebuilderState createState() => _RebuilderState<Rebuilder>();
}

class _RebuilderState<T> extends _RebuilderBaseState<Rebuilder> {
  @override ValueSubscription obtainSubscription() => widget.rebuildWhen != null
    ? widget.rebuildWhen!.listen(_valueChanged)
    : widget.value.listen(_valueChanged);

  @override
  Widget build(BuildContext context) {
    final dynamic snapshot = widget.value.value;

    return snapshot != null || widget.noDataBuilder == null
      // ignore: avoid_dynamic_calls
      ? widget.builder(context, snapshot) as Widget
      : widget.noDataBuilder?.call(context) ?? SizedBox();
  }
}


class Rebuilder2<T1, T2> extends _RebuilderBase {
  Rebuilder2({
    required ReadonlyValue<T1> value1,
    required ReadonlyValue<T2> value2,
    ReadonlyValue? rebuildWhen,
    required Widget Function(BuildContext context, T1, T2) builder,
    Widget Function(BuildContext context)? noDataBuilder,
  }) : super([value1, value2], rebuildWhen, builder, noDataBuilder);
}


class Rebuilder3<T1, T2, T3> extends _RebuilderBase {
  Rebuilder3({
    required ReadonlyValue<T1> value1,
    required ReadonlyValue<T2> value2,
    required ReadonlyValue<T3> value3,
    ReadonlyValue? rebuildWhen,
    required Widget Function(BuildContext context, T1, T2, T3) builder,
    Widget Function(BuildContext context)? noDataBuilder,
  }) : super([value1, value2, value3], rebuildWhen, builder, noDataBuilder);
}


class Rebuilder4<T1, T2, T3, T4> extends _RebuilderBase {
  Rebuilder4({
    required ReadonlyValue<T1> value1,
    required ReadonlyValue<T2> value2,
    required ReadonlyValue<T3> value3,
    required ReadonlyValue<T4> value4,
    ReadonlyValue? rebuildWhen,
    required Widget Function(BuildContext context, T1, T2, T3, T4) builder,
    Widget Function(BuildContext context)? noDataBuilder,
  }) : super([value1, value2, value3, value4], rebuildWhen, builder, noDataBuilder);
}


class Rebuilder5<T1, T2, T3, T4, T5> extends _RebuilderBase {
  Rebuilder5({
    required ReadonlyValue<T1> value1,
    required ReadonlyValue<T2> value2,
    required ReadonlyValue<T3> value3,
    required ReadonlyValue<T4> value4,
    required ReadonlyValue<T5> value5,
    ReadonlyValue? rebuildWhen,
    required Widget Function(BuildContext context, T1, T2, T3, T4, T5) builder,
    Widget Function(BuildContext context)? noDataBuilder,
  }) : super([value1, value2, value3, value4, value5], rebuildWhen, builder, noDataBuilder);
}


class Rebuilder6<T1, T2, T3, T4, T5, T6> extends _RebuilderBase {
  Rebuilder6({
    required ReadonlyValue<T1> value1,
    required ReadonlyValue<T2> value2,
    required ReadonlyValue<T3> value3,
    required ReadonlyValue<T4> value4,
    required ReadonlyValue<T5> value5,
    required ReadonlyValue<T6> value6,
    ReadonlyValue? rebuildWhen,
    required Widget Function(BuildContext context, T1, T2, T3, T4, T5, T6) builder,
    Widget Function(BuildContext context)? noDataBuilder,
  }) : super([value1, value2, value3, value4, value5, value6], rebuildWhen, builder, noDataBuilder);
}

class Rebuilder7<T1, T2, T3, T4, T5, T6, T7> extends _RebuilderBase {
  Rebuilder7({
    required ReadonlyValue<T1> value1,
    required ReadonlyValue<T2> value2,
    required ReadonlyValue<T3> value3,
    required ReadonlyValue<T4> value4,
    required ReadonlyValue<T5> value5,
    required ReadonlyValue<T6> value6,
    required ReadonlyValue<T7> value7,
    ReadonlyValue? rebuildWhen,
    required Widget Function(BuildContext context, T1, T2, T3, T4, T5, T6, T7) builder,
    Widget Function(BuildContext context)? noDataBuilder,
  }) : super([value1, value2, value3, value4, value5, value6, value7], rebuildWhen, builder, noDataBuilder);
}

class Rebuilder8<T1, T2, T3, T4, T5, T6, T7, T8> extends _RebuilderBase {
  Rebuilder8({
    required ReadonlyValue<T1> value1,
    required ReadonlyValue<T2> value2,
    required ReadonlyValue<T3> value3,
    required ReadonlyValue<T4> value4,
    required ReadonlyValue<T5> value5,
    required ReadonlyValue<T6> value6,
    required ReadonlyValue<T7> value7,
    required ReadonlyValue<T8> value8,
    ReadonlyValue? rebuildWhen,
    required Widget Function(BuildContext context, T1, T2, T3, T4, T5, T6, T7, T8) builder,
    Widget Function(BuildContext context)? noDataBuilder,
  }) : super([value1, value2, value3, value4, value5, value6, value7, value8], rebuildWhen, builder, noDataBuilder);
}

class Rebuilder9<T1, T2, T3, T4, T5, T6, T7, T8, T9> extends _RebuilderBase {
  Rebuilder9({
    required ReadonlyValue<T1> value1,
    required ReadonlyValue<T2> value2,
    required ReadonlyValue<T3> value3,
    required ReadonlyValue<T4> value4,
    required ReadonlyValue<T5> value5,
    required ReadonlyValue<T6> value6,
    required ReadonlyValue<T7> value7,
    required ReadonlyValue<T8> value8,
    required ReadonlyValue<T9> value9,
    ReadonlyValue? rebuildWhen,
    required Widget Function(BuildContext context, T1, T2, T3, T4, T5, T6, T7, T8, T9) builder,
    Widget Function(BuildContext context)? noDataBuilder,
  }) : super([value1, value2, value3, value4, value5, value6, value7, value8, value9], rebuildWhen, builder, noDataBuilder);
}

class Rebuilder10<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10> extends _RebuilderBase {
  Rebuilder10({
    required ReadonlyValue<T1> value1,
    required ReadonlyValue<T2> value2,
    required ReadonlyValue<T3> value3,
    required ReadonlyValue<T4> value4,
    required ReadonlyValue<T5> value5,
    required ReadonlyValue<T6> value6,
    required ReadonlyValue<T7> value7,
    required ReadonlyValue<T8> value8,
    required ReadonlyValue<T9> value9,
    required ReadonlyValue<T10> value10,
    ReadonlyValue? rebuildWhen,
    required Widget Function(BuildContext context, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10) builder,
    Widget Function(BuildContext context)? noDataBuilder,
  }) : super([value1, value2, value3, value4, value5, value6, value7, value8, value9, value10], rebuildWhen, builder, noDataBuilder);
}