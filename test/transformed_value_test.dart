import 'package:flutter_test/flutter_test.dart';
import 'package:value/value.dart';

void main() {
  test("TransformedValue basic test", () async {
    final original = Value(1);
    final transformed = original.transform((x) => x + 1);

    original.value = 2;
    expect(transformed.value, 3);
  });

  test("TransformedListValue basic test", () async {
    final original = ListValue([1, 2, 3]);
    final transformed = original.transformList((x) => x + 1);

    original.value = [3, 2, 1];
    final result = transformed.value;
    expect(result[0], 4);
    expect(result[1], 3);
    expect(result[2], 2);
  });
}