import 'package:core_common/core_common.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';
import 'package:trek_core/trek_core.dart';

class _Log implements Logger {
  final lines = <String>[];
  @override
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => lines.add('${level.name}:$message');
}

void main() {
  late FakeClock clock;
  late FakeHeartbeatSink sink;
  late _Log log;

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 10, 27, 14));
    sink = FakeHeartbeatSink();
    log = _Log();
  });

  HeartbeatLoop loop({Duration period = const Duration(seconds: 10)}) =>
      HeartbeatLoop(sink: sink, clock: clock, logger: log, period: period);

  test('beats at once on start, so the guard never sees a gap', () {
    fakeAsync((async) {
      loop().start();
      async.flushMicrotasks();
      expect(sink.beats, hasLength(1));
    });
  });

  test('then beats every period with the current time', () {
    fakeAsync((async) {
      loop().start();
      for (var i = 0; i < 3; i++) {
        clock.advance(const Duration(seconds: 10));
        async.elapse(const Duration(seconds: 10));
      }
      expect(sink.beats, hasLength(4));
      expect(sink.beats.last, DateTime.utc(2026, 10, 27, 14, 0, 30));
    });
  });

  test('beats well inside the guard 30 second timeout by default', () {
    expect(loop().period, lessThanOrEqualTo(const Duration(seconds: 15)));
  });

  test('stop ends the beating', () {
    fakeAsync((async) {
      final l = loop()..start();
      async.elapse(const Duration(seconds: 10));
      l.stop();
      final n = sink.beats.length;
      async.elapse(const Duration(minutes: 5));
      expect(sink.beats, hasLength(n));
    });
  });

  test('a failing sink is logged and the loop keeps going', () {
    fakeAsync((async) {
      sink.error = StateError('host gone');
      final l = loop()..start();
      async.elapse(const Duration(seconds: 20));
      expect(log.lines.where((l) => l.startsWith('warn')), isNotEmpty);
      sink.error = null;
      async.elapse(const Duration(seconds: 10));
      expect(sink.beats, isNotEmpty);
      l.stop();
    });
  });

  test('starting twice does not double the beats', () {
    fakeAsync((async) {
      loop()
        ..start()
        ..start();
      async.elapse(const Duration(seconds: 10));
      expect(sink.beats, hasLength(2));
    });
  });

  test('stop without start is harmless', () {
    loop().stop();
  });
}
