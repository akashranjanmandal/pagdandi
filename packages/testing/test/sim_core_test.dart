import 'package:test/test.dart';
import 'package:testing/testing.dart';

void main() {
  group('FakeClock', () {
    test('advance moves wall and monotonic time together', () {
      final c = FakeClock(DateTime.utc(2026, 10, 27, 9));
      c.advance(const Duration(minutes: 2));
      expect(c.now(), DateTime.utc(2026, 10, 27, 9, 2));
      expect(c.elapsed(), const Duration(minutes: 2));
    });

    test('jumpWall changes wall time only', () {
      final c = FakeClock(DateTime.utc(2026, 10, 27, 9));
      c.jumpWall(DateTime.utc(2020));
      expect(c.now(), DateTime.utc(2020));
      expect(c.elapsed(), Duration.zero);
    });

    test('cannot move backwards', () {
      final c = FakeClock(DateTime.utc(2026));
      expect(() => c.advance(const Duration(seconds: -1)), throwsArgumentError);
    });
  });

  group('SimScheduler', () {
    late FakeClock clock;
    late SimScheduler sim;
    setUp(() {
      clock = FakeClock(DateTime.utc(2026));
      sim = SimScheduler(clock);
    });

    test('runs events in time order and advances the clock to each', () {
      final log = <String>[];
      sim
        ..after(
          const Duration(seconds: 5),
          () => log.add('b@${clock.elapsed().inSeconds}'),
        )
        ..after(
          const Duration(seconds: 2),
          () => log.add('a@${clock.elapsed().inSeconds}'),
        );
      sim.runFor(const Duration(seconds: 10));
      expect(log, ['a@2', 'b@5']);
      expect(clock.elapsed(), const Duration(seconds: 10));
    });

    test('events at the same time run in scheduling order', () {
      final log = <int>[];
      for (var i = 0; i < 3; i++) {
        sim.after(const Duration(seconds: 1), () => log.add(i));
      }
      sim.runFor(const Duration(seconds: 1));
      expect(log, [0, 1, 2]);
    });

    test('events scheduled by events run if still inside the window', () {
      final log = <String>[];
      sim.after(const Duration(seconds: 1), () {
        log.add('first');
        sim.after(const Duration(seconds: 1), () => log.add('second'));
      });
      sim.runFor(const Duration(seconds: 5));
      expect(log, ['first', 'second']);
    });

    test('events beyond the window stay queued', () {
      final log = <String>[];
      sim.after(const Duration(seconds: 8), () => log.add('late'));
      sim.runFor(const Duration(seconds: 5));
      expect(log, isEmpty);
      sim.runFor(const Duration(seconds: 5));
      expect(log, ['late']);
    });
  });
}
