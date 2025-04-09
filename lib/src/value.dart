import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

abstract class ReadonlyValue<T> {
  /// Current value of Value
  T get value;

  String? get debugName;

  /// [listener] is called every time the Value is updated
  ValueSubscription listen(
    FutureOr<void> Function(T) listener, {
      bool sendNow = false,
      void Function()? onCancel,
      String? debugName,
    }) {

    final listenerObj = _Listener(listener, Trace.current(), debugName);
    _listeners.add(listenerObj);

    if (sendNow)
      listener(value);

    return SingleValueSubscription<T>._(this, listenerObj.method, onCancel: onCancel);
  }

  final _listeners = <_Listener<T>>[];

  /// True, when there is at least one listener
  bool get hasListeners => _listeners.isNotEmpty;

  Type get underlyingType => T;

  // Pause/resume listeners functionality
  var _isPausedCounter = 0;
  bool _hadUpdatesDuringPause = false;

  // ignore: avoid_print, prefer_function_declarations_over_variables
  static void Function(String emoji, String text) log = (emoji, text) => print("$emoji $text");

  /// If executing listener takes more than specified, log entry is published
  static bool reportDelays = false;
  static Duration reportedListenerExecutionDelay = const Duration(milliseconds: 100);

  /// Notifies listeners if not in paused mode
  void notifyListeners() => _maybeNotifyListeners(value);

  Future<void> _maybeNotifyListeners(T update) async {
    if (_isPausedCounter > 0)
      _hadUpdatesDuringPause = true;
    else
      await _notifyListeners(update);
  }

  late final String _debugNameText = debugName != null ? "[$debugName] " : ""; // Internal helper for delay reports

  /// Actually invokes listeners, do not call directly
  Future<void> _notifyListeners(T update) async {
    if (_listeners.isEmpty)
      return;

    final valueUpdated = DateTime.now();

    await Future.delayed(Duration.zero); // Breaks sync execution intentionally, otherwise listeners are called to early, inside synchronous context.

    if (reportDelays) {
      final start = DateTime.now();
      final startDelay = start.difference(valueUpdated);
      if (startDelay > reportedListenerExecutionDelay) {
        final listenerNames = _listeners.where((x) => x.debugName != null).map((x) => x.debugName).toList();
        final listenerNamesText = listenerNames.isNotEmpty ? "(${listenerNames.join(", ")}${_listeners.length > listenerNames.length ? ",..." : ""})" : "";
        log("🕜", "Delayed ${_listeners.length} listener${_listeners.length > 1 ? "s" : ""}$listenerNamesText ${startDelay.inMilliseconds} ms for $_debugNameText${_formatValue(update)}");
      }
    }

    await Future.wait(_listeners.map((listener) async {
      try {
        final start = DateTime.now();

        await listener.method(update);

        if (reportDelays) {
          final duration = DateTime.now().difference(start);
          if (duration > reportedListenerExecutionDelay) {
            log("⏳", "Listener ${listener.debugName ?? ""} took ${duration.inMilliseconds} ms for $_debugNameText${_formatValue(update)}");
          }
        }
      }
      catch(e) {
        log("⚡", "Unhandled exception in ${listener.debugName ?? ""} Value listener for $_debugNameText${_formatValue(update)}: $e");
        _logTrace(listener);

        if (e is Error)
          log("📛", e.stackTrace.toString());
      }
    }));
  }

  String _formatValue(T x) => "<$T>${x is List ? "[${x.length} items]" : x is Map ? "{${x.length} items}" : x}";

  static const _ignoredPackages = ["value", "utils", "test_api", "dart"];

  void _logTrace(_Listener listener) {
    final frames = listener.stackTrace.frames;

    late bool isFlutterTest;
    try {
      isFlutterTest = Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      isFlutterTest = false;
    }
    if (isFlutterTest)  { // extended logging for tests
      for (final frame in frames)
        log(" ⤷", frame.toString());
    }
    else {
      if (frames.isNotEmpty) {
        for (final frame in frames) {
          if (frame.isCore)
            continue;

          if (_ignoredPackages.any((element) => frame.package?.startsWith(element) == true))
            continue;

          log(" ⤷", frame.toString());
        }
      }
      else
        log(" ⤷", "No StackTrace info available");
    }
  }

  Future<void> waitFor(T match, {Duration? timeout}) async {
    if (value == match)
      return;

    final completer = Completer<void>();
    final subscription = this.listen((update){
      if (update == match && !completer.isCompleted)
        completer.complete();
    }, sendNow: true);

    await (timeout != null
      ? completer.future.timeout(timeout)
      : completer.future);

    subscription.cancel();
  }

  @override String toString() => value.toString();
}

class _Listener<T> {
  _Listener(this.method, this.stackTrace, this.debugName);

  final FutureOr<void> Function(T) method;
  final Trace stackTrace;
  final periodStopwatch = Stopwatch(); // tracks period of listener calls
  int? averagePeriod;
  String? debugName;
}

mixin PauseResumeForValue<T> on ReadonlyValue<T> {
  void pauseListeners() => _isPausedCounter++;

  void resumeListeners({bool sendMissedNotifications = true}) {
    if (_isPausedCounter > 0)
      _isPausedCounter--;

    if (_isPausedCounter == 0 && sendMissedNotifications && _hadUpdatesDuringPause) {
      _hadUpdatesDuringPause = false;
      scheduleMicrotask(() => _notifyListeners(value));
    }
  }
}

mixin WriteonlyValue<T> {
  set value(T update);
  void set(T update); // Shortcut for setter. Convenient in some cases
}


class ConstValue<T> extends ReadonlyValue<T> {
  ConstValue(this._value, {this.debugName});
  static ConstValue<bool> get alwaysTrue => ConstValue<bool>(true);
  static ConstValue<bool> get alwaysFalse => ConstValue<bool>(false);

  final T _value;
  @override T get value => _value;

  @override final String? debugName;
}


//* Regular value
class Value<T> extends ReadonlyValue<T> with PauseResumeForValue<T>, WriteonlyValue<T> {
  Value(this._value, {this.distinctMode = true, this.debugName});

  T _value;
  @nonVirtual @override T get value => _value;
  @override set value(T update) {
    if(!distinctMode || _value != update){
      _value = update;
      _maybeNotifyListeners(update); // intentionally unawaited
    }
  }

  /// When true, listeners are notified only if underlying value was changed (!= previous value).
  /// Should be set to false for List, Map and mutable classes, where equivalence by value is not implemented
  final bool distinctMode;

  @override final String? debugName;

  /// Sets a new value
  @override
  void set(T update, {bool sendNotifications = true}) {
    if (sendNotifications)
      value = update;
    else
      _value = update;
  }
}

extension ValueSetAndWait<T> on Value<T> {
  /// Sets new value and awaits for all first-level listeners. To be used in tests primarly.
  Future<void> setAndWait(T update) async {
    if(!distinctMode || _value != update) {
      set(update, sendNotifications: false);
      await _maybeNotifyListeners(update);
    }
  }
}


//* Value subscriptions
/// Subscription discriptor. Call [cancel()] on dispose or when the Value is not needed any more
abstract class ValueSubscription {
  ValueSubscription(this.onCancel);
  bool get isCancelled => _isCancelled;
  bool _isCancelled = false;

  final void Function()? onCancel; // called AFTER removing the listener
  @mustCallSuper void cancel() {
    if (!_isCancelled)
      _isCancelled = true;
      onCancel?.call();
  }
}

class SingleValueSubscription<T> extends ValueSubscription {
  SingleValueSubscription._(this._value, this._listener, {void Function()? onCancel}) : super(onCancel);

  final ReadonlyValue<T> _value;
  final Function _listener;

  @override void cancel() {
    _value._listeners.removeWhere((element) => element.method == _listener);
    super.cancel();
  }
}

extension ToggleBoolValueExtension on Value<bool> {
  void toggle() => value = !value;
}


/// Stream -> ReadonlyValue converter
class StreamValue<T> extends ReadonlyValue<T> {
  StreamValue(this._stream, {this.errorBuilder, required T initialValue, this.distinctMode = true, this.debugName}) {
    _value = initialValue;
    notifyListeners();
  }

  static Future<StreamValue<T>> createAsync<T>(
    Stream<T> stream, {
    T Function(Object error)? errorBuilder,
    required Future<T> initialValueFuture,
    bool distinctMode = true,
    String? debugName,
  }) async
    => StreamValue(stream, errorBuilder: errorBuilder, initialValue: await initialValueFuture, distinctMode: distinctMode, debugName: debugName);

  @override T get value => _value;
  late T _value;

  final Stream<T> _stream;
  StreamSubscription? _streamSubscription;
  final bool distinctMode;
  @override final String? debugName;

  final T Function(Object error)? errorBuilder;

  @override
  ValueSubscription listen(
    FutureOr<void> Function(T) listener, {
    bool sendNow = false,
    void Function()? onCancel,
    String? debugName,
  }) {
    _listeners.add(_Listener(listener, Trace.current(), debugName));

    _streamSubscription ??= _stream
      .handleError((Object error) {
        ReadonlyValue.log("🛑", "StreamValue absorbed an error from stream. $error");
        if (errorBuilder != null) {
          _value = errorBuilder!(error);
          notifyListeners(); // unawaited
        }
      })
      .listen((update) {
        if(!distinctMode || update != _value) {
          _value = update;
          notifyListeners(); // unawaited
        }
      });

    if (sendNow && _value != null)
      Timer.run(() => listener(_value!));

    return SingleValueSubscription<T>._(this, listener, onCancel: () async {
      if (_listeners.isEmpty) {
         await _streamSubscription?.cancel();

      onCancel?.call();

        //ReadonlyValue.log("🎯", "Cancelled stream in StreamValue");
      }
    });
  }
}