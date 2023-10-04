import 'package:flutter_test/flutter_test.dart';
import 'package:value/value.dart';

void main() {
  test("CombinedValue basic test", () async {
    final x = Value<int>(1);
    final y = Value<int>(40);
    final z = CombinedValue2(x, y, (v1, v2) => (v1 + v2).toString());

    x.value = 2;
    expect(z.value, "42");
  });


  test("combine2() cancel subscription test", () async {
    final x = Value<int>(1);
    final y = Value<int>(40);
    var actionsCounter = 0;
    final subscription = combine2<int, int>(x, y, action: (a, b) => actionsCounter++);

    x.value = 42;
    subscription.cancel();
    await Future<void>.delayed(Duration(milliseconds: 10));
    x.value = 137;

    expect(actionsCounter, 1);
  });

  test("Limit updates by triggeredBy", () async {
    final x = Value<int>(0);
    final y = Value<int>(40);
    var counter = 0;
    final subscription = combine2<int, int>(
      x,
      y,
      action: (a, b) {
        // print("a: $a, b: $b");
        counter++;
      },
      triggeredBy: [x],
    );

    x.value = 1;
    x.value = 2;
    x.value = 3;
    x.value = 4;
    y.value = 10;
    y.value = 11;
    y.value = 12;
    x.value = 5;

    subscription.cancel();
    await Future<void>.delayed(Duration(milliseconds: 10));
    expect(counter, 5);
  });
}