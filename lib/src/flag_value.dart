import 'dart:async';

import 'value.dart';

/// Automatically sets itself to false after [timeout]
class FlagValue extends Value<bool> {
  FlagValue(this.timeout, [bool initialValue = false])
  : super(initialValue, distinctMode: true) {
    if (initialValue)
      _timer = Timer(timeout, () => set(false));
  }

  final Duration timeout;
  Timer? _timer;

  @override
  set value(bool update) {
    super.value = update;

    _timer?.cancel();
    if (update)
      _timer = Timer(timeout, () => set(false));
  }
}