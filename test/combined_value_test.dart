import 'package:flutter_test/flutter_test.dart';
import 'package:value/value.dart';

// ignore_for_file: cascade_invocations, avoid_print
void main() {
  test("CombinedValue test", () async {
    final x = Value<int>(1);
    final y = Value<int>(40);
    final z = CombinedValue2<int, int, String>(x, y, (v1, v2) => (v1 + v2).toString());

    await x.set(2);
    expect(z.value, "42");
  });


  test("combine2() cancel subscription test", () async {
    final x = Value<int>(1);
    final y = Value<int>(40);
    var actionsCounter = 0;
    final subscription = combine2<int, int>(x, y, action: (a, b) => actionsCounter++);

    await x.set(42);
    await subscription.cancel();
    await x.set(137);

    expect(actionsCounter, 1);
  });
}