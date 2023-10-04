// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:value/value.dart';

void main() {
  test("ThrottleValue test", () async {
    const steps = 10;
    var yHasFinalUpdate = false;
    var yUpdatesCount = 0;

    final x = Value<int?>(1, distinctMode: false);
    final y = x.throttle(Duration(milliseconds: 50));

    x.listen((value) => print("🔹 x: $value"));
    y.listen((value) {
      print("🔸 y: $value");
      expect(value, y.value);

      yUpdatesCount++;

      if (value == steps)
        yHasFinalUpdate = true;
    });

    for (var step = 1; step <= steps; step++) {
      await Future<void>.delayed(Duration(milliseconds: 10));
      x.value = step;
    }

    await Future<void>.delayed(Duration(milliseconds: 50));
    expect(y.value, steps);

    await Future<void>.delayed(Duration(milliseconds: 50));

    print("Final state check");
    print("🔹 x: $x");
    print("🔸 y: $y");

    expect(y.value, steps);
    expect(x.value, steps);
    expect(yHasFinalUpdate, true);
    expect(yUpdatesCount < steps/2, true);
    expect(yUpdatesCount > 2, true);
  }, skip: "Unreliable execution on build server");
}