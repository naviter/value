import 'package:flutter_test/flutter_test.dart';
import 'package:value/value.dart';

import 'value_test.dart';

void main() {
  test("FlagValue basic test", () async {
    final flag = FlagValue(Duration(milliseconds: 100));
    expect(flag.value, false);

    flag.value = true;
    await delay(50);
    expect(flag.value, true);

    await delay(150);
    expect(flag.value, false);
  });
}