// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:value/value.dart';

void main() {
  test("Basic TimeoutValue test", () async {
    const steps = 10;
    var updatesCounter = 0;
    final x = TimeoutValue<int?>(Duration(milliseconds: 20));

    x.listen((update) {
      // print(update);
      updatesCounter++;
    });

    for (var step = 1; step <= steps; step++) {
      await Future<void>.delayed(Duration(milliseconds: 5));
      x.value = 42;
    }
    expect(updatesCounter, 1);
    await Future<void>.delayed(Duration(milliseconds: 30));
    expect(updatesCounter, 2);
  });

  test("TimeoutExtensionValue test", () async {
    var yHasNullUpdate = false;
    final x = Value<int?>(1, distinctMode: false);
    final y = x.timeout(Duration(milliseconds: 50));

    // x.listen((value) => print("x: $value"));
    y.listen((value) {
      // print("y: $value");
      expect(value, y.value);

      if (value == null)
        yHasNullUpdate = true;
    });

    await Future<void>.delayed(Duration(milliseconds: 10));
    x.value = 2;
    await Future<void>.delayed(Duration(milliseconds: 10));
    x.value = 3;
    await Future<void>.delayed(Duration(milliseconds: 10));
    x.value = 4;

    expect(y.value, 4);

    await Future<void>.delayed(Duration(milliseconds: 100));
    expect(yHasNullUpdate, true);

    expect(x.value, 4);
    expect(y.value, null);

    // print("Final state");
    // print("x: $x");
    // print("y: $y");
  });

  test("Multiple subscribers to TimeoutExtensionValue", () async {
    var nullCounter = 0;
    final x =  Value<int?>(1, distinctMode: false);
    final y = x.timeout(Duration(milliseconds: 30));
    y.listen((p0) { print("Listener 1: $p0"); if (p0 == null) nullCounter++; });
    y.listen((p0) { print("Listener 2: $p0"); if (p0 == null) nullCounter++; });
    y.listen((p0) { print("Listener 3: $p0"); if (p0 == null) nullCounter++; });

    x.value = 2;
    await Future<void>.delayed(Duration(milliseconds: 10));
    x.value = 3;

    await Future<void>.delayed(Duration(milliseconds: 50));
    x.value = 4;
    await Future<void>.delayed(Duration(milliseconds: 50));
    expect(nullCounter, 6);
  });
}