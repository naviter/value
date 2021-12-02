// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:value/value.dart';

void main() {
  test("TimeoutValue test", () async {
    final x = Value<int>(1);
    final y = x.timeout(Duration(milliseconds: 500));

    final originSubscription = x.listen((value) => print("origin: $value"));
    final subscription1 = y.listen((value) => print("sub1: $value"));
    final subscription2 = y.listen((value) => print("sub2: $value"));
    final subscription3 = y.listen((value) => print("sub3: $value"));

    await Future<void>.delayed(Duration(milliseconds: 100));
    await x.set(2);
    await Future<void>.delayed(Duration(milliseconds: 100));
    await x.set(3);
    await Future<void>.delayed(Duration(milliseconds: 100));
    await x.set(4);

    await Future<void>.delayed(Duration(seconds: 1));
    print("x: $x"); // should be 4
    print("y: $y"); // should be null

    await originSubscription.cancel();
    await subscription1.cancel();
    await subscription2.cancel();
    await subscription3.cancel();
  });
}