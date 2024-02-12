import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

abstract class ReadonlyValue<T> {
  /// Current value of Value
  T get value;

  /// [listener] is called every time the Value is updated
  ValueSubscription listen(
    FutureOr<void> Function(T) listener, {
      bool sendNow = false,
      void Function()? onCancel,
    }) {

    final listenerObj = _Listener(listener, Trace.current());
    _listeners.add(listenerObj);

    if (sendNow)
      listener(value);

    return SingleValueSubscription<T>._(this, listenerObj.method, onCancel: onCancel);
  }

  final _listeners = <_Listener<T>>[];

  /// True, when there is at least one listener
  bool get hasListeners => _listeners.isNotEmpty;

  // Pause/resume listeners functionality
  bool get isPaused => _isPaused;
  bool _isPaused = false;
  bool _hadUpdatesDuringPause = false;

  // ignore: avoid_print, prefer_function_declarations_over_variables
  static void Function(String emoji, String text) log = (emoji, text) => print("$emoji $text");

  /// If executing listener takes more than specified, log entry is published
  static Duration reportedListenerExecutionDelay = const Duration(milliseconds: 200);
  static bool logSlowListeners = false; // Create log entries for every slowly executed listener
  static int _globalActiveListenersCount = 0;

  /// Notifies listeners if not in paused mode
  void notifyListeners() => _maybeNotifyListeners(value);

  Future<void> _maybeNotifyListeners(T update) async {
    if (isPaused)
      _hadUpdatesDuringPause = true;
    else
      await _notifyListeners(update);
  }

  /// Actually invokes listeners, do not call directly
  Future<void> _notifyListeners(T update) async {
    if (_listeners.isEmpty)
      return;

    var activeListenersCount = _listeners.length;
    _globalActiveListenersCount += activeListenersCount;
    final completer = Completer<void>();

    for (final listener in _listeners) {
      scheduleMicrotask(() async { // unawaited
        try {
          late final Stopwatch executionSw;
          late final int period;

          if (logSlowListeners) {
            listener.periodStopwatch.start();
            period = listener.periodStopwatch.elapsedMilliseconds;
            listener.averagePeriod ??= period;
            listener.averagePeriod = listener.averagePeriod! + (period - listener.averagePeriod!) ~/ 25;
            listener.periodStopwatch.reset();
            executionSw = Stopwatch()..start();
          }

          await listener.method(update);

          if (logSlowListeners) {
            final executionDelay = executionSw.elapsed;

            if (executionDelay > reportedListenerExecutionDelay) {
              log("⏳", "Value handler for ${_formatValue(update)} took ${executionDelay.inMilliseconds} ms, period $period current / ${listener.averagePeriod} avg ms, total listeners: $_globalActiveListenersCount");
              // logTrace(listener);
            }
          }
        }
        catch (e) {
          log("⚡", "Unhandled exception in Value listener for ${_formatValue(update)}: $e");
          logTrace(listener);

          if (e is Error)
            log("📛", e.stackTrace.toString());
        }
        finally {
          activeListenersCount--;
          _globalActiveListenersCount--;
          if (activeListenersCount == 0)
            completer.complete();
        }
      });
    }

    return completer.future;
  }

  String _formatValue(T valueCached) => "<$T>${T != valueCached.runtimeType ? "/<${valueCached.runtimeType}>" : ""}${valueCached is List ? "[${valueCached.length} items]" : valueCached is Map ? "{${valueCached.length} items}" : valueCached}";

  static const _ignoredPackages = ["value", "utils", "test_api", "dart"];

  void logTrace(_Listener listener) {
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

  @override String toString() => value.toString();
}

class _Listener<T> {
  _Listener(this.method, this.stackTrace);

  final FutureOr<void> Function(T) method;
  final Trace stackTrace;
  final periodStopwatch = Stopwatch(); // tracks period of listener calls
  int? averagePeriod;
}

mixin PauseResumeForValue<T> on ReadonlyValue<T> {
  //! There is a potential problem in multiple entering paused state
  void pauseListeners() => _isPaused = true;

  void resumeListeners({bool sendMissedNotifications = true}) {
    _isPaused = false;

    if (sendMissedNotifications && _hadUpdatesDuringPause) {
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
  ConstValue(this._value);
  static ConstValue<bool> get alwaysTrue => ConstValue<bool>(true);
  static ConstValue<bool> get alwaysFalse => ConstValue<bool>(false);

  final T _value;
  @override T get value => _value;
}


//* Regular value
class Value<T> extends ReadonlyValue<T> with PauseResumeForValue<T>, WriteonlyValue<T> {
  Value(this._value, {this.distinctMode = true});

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
    final runOnCancel = !isCancelled;
    _isCancelled = true;

    if (runOnCancel)
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
  StreamValue(this._stream, {this.errorBuilder, required T initialValue, this.distinctMode = true}) {
    _value = initialValue;
    notifyListeners();
  }

  static Future<StreamValue<T>> createAsync<T>(
    Stream<T> stream, {
    T Function(Object error)? errorBuilder,
    required Future<T> initialValueFuture,
    bool distinctMode = true,
  }) async
    => StreamValue(stream, errorBuilder: errorBuilder, initialValue: await initialValueFuture, distinctMode: distinctMode);

  @override T get value => _value;
  late T _value;

  final Stream<T> _stream;
  StreamSubscription? _streamSubscription;
  bool distinctMode;
  final T Function(Object error)? errorBuilder;

  @override
  ValueSubscription listen(
    FutureOr<void> Function(T) listener, {
    bool sendNow = false,
    void Function()? onCancel,
  }) {
    _listeners.add(_Listener(listener, Trace.current()));

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