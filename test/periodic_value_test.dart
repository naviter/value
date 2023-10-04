import 'package:flutter_test/flutter_test.dart';
import 'package:value/value.dart';

void main() {
  test("PeriodicValue test", () async {
    final x = PeriodicValue(Duration(milliseconds: 10));
    var counter = 0;
    x.listen((_) => counter++);
    await Future<void>.delayed(Duration(milliseconds: 55));
    expect(counter, 5);
  });
}