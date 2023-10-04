import 'package:flutter_test/flutter_test.dart';
import 'package:value/value.dart';

void main() {
  Future<void> delay(int milliseconds) => Future<void>.delayed(Duration(milliseconds: milliseconds));

  test("DebounceValue test", () async {
    final x = Value<int>(0);
    final collectedValues = <int>[];
    final subscription = x.debounce(Duration(milliseconds: 500)).listen(collectedValues.add);

    await delay(100);
    x.value = 1;
    await delay(100);
    x.value = 2;
    await delay(100);
    x.value = 3;

    await Future<void>.delayed(Duration(milliseconds: 600));
    x.value = 4;

    await Future<void>.delayed(Duration(seconds: 1));
    subscription.cancel();
    expect(collectedValues[0], 3);
    expect(collectedValues[1], 4);
    expect(collectedValues.length, 2);
  });
}