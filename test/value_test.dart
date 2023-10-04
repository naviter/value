
import 'package:flutter_test/flutter_test.dart';
import 'package:value/value.dart';

final _globalStopwatch = Stopwatch()..start();
// ignore: avoid_print
void log(String text) => print("${_globalStopwatch.elapsedMicroseconds} $text");

Future<void> delay(int i) async => Future<void>.delayed(Duration(milliseconds: i));
// void delaySync(int i) {
//   final sw = Stopwatch()..start();
//   while (sw.elapsedMilliseconds < i) {}
// }
// void schedule(Future future) async => unawaited(Future(future));

void main() {
  ReadonlyValue.log = (emoji, text) => log("$emoji $text");
  ReadonlyValue.reportedListenerExecutionDelay = Duration(milliseconds: 50);

  test("Basic listeners test", () async {
    final x = Value(0, distinctMode: false);
    var counter = 0;

    x.listen((update) async {
      // log("x: $update");
      await delay(1);
      counter++;
    });

    x.value = 1;
    x.value = 2;
    x.value = 3;

    await delay(5);
    expect(counter, 3);

    await x.setAndWait(137);
    expect(counter, 4);
  });

  test("Exception thrown in a Value listener", () async {
    final x = Value(0, distinctMode: false);
    var counter = 0;

    x.listen((update) async {
      log("Listener called");
      counter++;
      throw Exception("Exception message");
    });

    await x.setAndWait(1);
    await x.setAndWait(2);
    expect(counter, 2);
  });
}
