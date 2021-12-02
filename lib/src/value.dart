import 'dart:async';

import 'package:meta/meta.dart';

abstract class ReadonlyValue<T> {
  /// Current value of Value
  T get value;

  /// [listener] is called every time the Value is updated
  ValueSubscription listen(FutureOr<void> Function(T) listener, {bool sendNow = false}) {
    _listeners.add(listener);

    if (sendNow)
      _notifyListeners(); // unawaited

    return SingleValueSubscription._(this, listener);
  }

  final _listeners = <Function>[];

  /// True, when there is at least one listener
  bool get hasListeners => _listeners.isNotEmpty;

  // Pause/resume listeners functionality
  bool get isPaused => _isPaused;
  bool _isPaused = false;
  bool _hadUpdatesDuringPause = false;

  /// Notifies listeners if not in paused mode
  Future<void> notifyListeners([T update]) async {
    if (isPaused)
      _hadUpdatesDuringPause = true;
    else
      await _notifyListeners(update);
  }

  /// Actually invokes listeners, do not call directly
  @protected
  Future<void> _notifyListeners([T update]) async {
    if (_listeners.isEmpty)
      return;

    final listeners = List<FutureOr<void> Function(T)>.from(_listeners);  // copy to avoid concurrent modification error from listen() call
    await Future.wait(listeners.map((listener) async {
      // ignore: avoid_print
      final handlerTimer = Timer(Duration(seconds: 10), () => print("⚠ Slow value handler for value $value of type $T"));
      try {
        await listener(update ?? value);
      }
      catch (e) {
        // ignore: avoid_print
        print("⚡ Unhandled exception in Value listener for value $value of type $T: $e");

        if (e is Error)
          // ignore: avoid_print
          print(e.stackTrace.toString());
      }
      finally {
        handlerTimer.cancel();
      }
    }));
  }

  @override String toString() => value.toString();
}


//* Regular value
class Value<T> extends ReadonlyValue<T> with PauseResumeForValue<T> {
  Value(this._value, {this.distinctMode = true});

  T _value;
  @override T get value => _value;
  // set value(T update) => set(update);

  /// When true, listeners are notified only if underlying value was changed (!= previous value).
  /// Should be set to false for List, Map and mutable classes, where equivalence by value is not implemented
  final bool distinctMode;

  /// Sets a new value and awaits all the listeners to complete
  Future<void> set(T update) async {
    if(!distinctMode || _value != update){
      _value = update;
      await notifyListeners(update);
    }
  }
}

mixin PauseResumeForValue<T> on ReadonlyValue<T> {
  void pauseListeners() => _isPaused = true;

  Future<void> resumeListeners({bool sendMissedNotifications = true}) async {
    _isPaused = false;

    if (sendMissedNotifications && _hadUpdatesDuringPause) {
      _hadUpdatesDuringPause = false;
      await _notifyListeners();
    }
  }
}


//* Value subscriptions
/// Subscription discriptor. Call [cancel()] on dispose or when the Value is not needed any more
abstract class ValueSubscription {
  ValueSubscription();
  bool get isCancelled => _isCancelled;
  bool _isCancelled = false;

  @mustCallSuper Future<void> cancel() async => _isCancelled = true;
}

class SingleValueSubscription extends ValueSubscription {
  SingleValueSubscription._(this._value, this._listener);

  final ReadonlyValue _value;
  final Function _listener;

  @override Future<void> cancel() async {
    if (_value._listeners.contains(_listener))
      _value._listeners.remove(_listener);

    await super.cancel();
  }
}

extension ToggleBoolValueExtension on Value<bool> {
  Future<void> toggle() => set(!value);
}


/// Stream -> ReadonlyValue converter
class StreamValue<T> extends ReadonlyValue<T> {
  StreamValue(this._stream, {this.errorBuilder, this.distinctMode = true});

  @override T get value => _value;
  T _value;


  final Stream<T> _stream;
  StreamSubscription _streamSubscription;
  bool distinctMode;
  final T Function(Object error) errorBuilder;

  @override ValueSubscription listen(FutureOr<void> Function(T) listener, {bool sendNow = false, Future<void> Function() onCancel}) {
    _listeners.add(listener);

    _streamSubscription ??= _stream
      .handleError((Object error) {
        // ignore: avoid_print
        print("🛑 StreamValue absorbed an error from stream. $error");
        if (errorBuilder != null) {
          _value = errorBuilder(error);
          notifyListeners(_value); // unawaited
        }
      })
      .listen((update) {
        if(!distinctMode || update != _value) {
          _value = update;
          notifyListeners(_value); // unawaited
        }
      });

    if (sendNow)
      notifyListeners(_value);

    return _StreamValueSubscription._(this, listener, onCancel: () async {
      if (_listeners.isEmpty) {
        await _streamSubscription?.cancel();

      await onCancel?.call();

        // // ignore: avoid_print
        // print("🎯 Cancelled stream in StreamValue");
      }
    });
  }
}

class _StreamValueSubscription extends SingleValueSubscription {
  _StreamValueSubscription._(ReadonlyValue value, Function listener, {this.onCancel}) : super._(value, listener);

  final Future<void> Function() onCancel;

  @override Future<void> cancel() async {
    await super.cancel();
    await onCancel?.call();
  }
}