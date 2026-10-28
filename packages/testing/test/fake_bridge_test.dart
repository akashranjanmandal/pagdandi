import 'package:test/test.dart';
import 'package:testing/testing.dart';

void main() {
  test('commands from the UI reach the core', () async {
    final b = FakeBridge();
    final got = <String>[];
    b.core.commands.listen(got.add);
    await b.ui.send('a');
    expect(got, ['a']);
  });

  test('commands sent before the core listens are queued, in order', () async {
    final b = FakeBridge();
    await b.ui.send('a');
    await b.ui.send('b');
    final got = <String>[];
    b.core.commands.listen(got.add);
    await pumpEventQueue();
    await b.ui.send('c');
    expect(got, ['a', 'b', 'c']);
  });

  test('states from the core reach the UI', () async {
    final b = FakeBridge();
    final got = <String>[];
    b.ui.states.listen(got.add);
    await b.core.publish('s1');
    expect(got, ['s1']);
  });

  test('a UI that connects later gets the latest state at once', () async {
    final b = FakeBridge();
    await b.core.publish('s1');
    await b.core.publish('s2');
    final got = <String>[];
    b.ui.states.listen(got.add);
    await pumpEventQueue();
    expect(got, ['s2']);
  });

  test('both directions are recorded for assertions', () async {
    final b = FakeBridge();
    await b.ui.send('c');
    await b.core.publish('s');
    expect(b.sentCommands, ['c']);
    expect(b.publishedStates, ['s']);
  });
}
