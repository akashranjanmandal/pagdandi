import 'package:core_common/core_common.dart';
import 'package:test/test.dart';

class _Clock implements Clock {
  _Clock(this.wall, this.mono);
  DateTime wall;
  Duration mono;
  @override
  DateTime now() => wall;
  @override
  Duration elapsed() => mono;
}

class _Gps implements GpsTimeSource {
  GpsTimeReading? reading;
  @override
  GpsTimeReading? get latest => reading;
}

void main() {
  final t0 = DateTime.utc(2026, 10, 27, 9);
  late _Clock clock;
  late _Gps gps;
  late TrustedClock trusted;

  setUp(() {
    clock = _Clock(t0, const Duration(hours: 5));
    gps = _Gps();
    trusted = TrustedClock(system: clock, gps: gps);
  });

  test('without a GPS reading it uses system time and flags it untrusted', () {
    final ts = trusted.now();
    expect(ts.time, t0);
    expect(ts.gpsTrusted, isFalse);
  });

  test('with a fresh reading it returns GPS time and flags it trusted', () {
    gps.reading = GpsTimeReading(
      gpsTime: DateTime.utc(2026, 10, 27, 9, 0, 7),
      monotonicAtReading: clock.mono,
    );
    final ts = trusted.now();
    expect(ts.time, DateTime.utc(2026, 10, 27, 9, 0, 7));
    expect(ts.gpsTrusted, isTrue);
  });

  test('GPS time advances with the monotonic clock', () {
    gps.reading = GpsTimeReading(
      gpsTime: DateTime.utc(2026, 10, 27, 9, 0, 7),
      monotonicAtReading: clock.mono,
    );
    clock.mono += const Duration(minutes: 3);
    expect(trusted.now().time, DateTime.utc(2026, 10, 27, 9, 3, 7));
  });

  test('a changed system wall clock does not move trusted time', () {
    gps.reading = GpsTimeReading(
      gpsTime: DateTime.utc(2026, 10, 27, 9),
      monotonicAtReading: clock.mono,
    );
    clock.wall = DateTime.utc(2020); // user changes the date
    clock.mono += const Duration(seconds: 30);
    expect(trusted.now().time, DateTime.utc(2026, 10, 27, 9, 0, 30));
  });

  test('a reading older than maxAge falls back to flagged system time', () {
    gps.reading = GpsTimeReading(
      gpsTime: DateTime.utc(2026, 10, 27, 9),
      monotonicAtReading: clock.mono,
    );
    clock.mono += const Duration(minutes: 31);
    final ts = trusted.now();
    expect(ts.gpsTrusted, isFalse);
    expect(ts.time, clock.wall);
  });

  test(
    'a reading from before a reboot (monotonic went backwards) is ignored',
    () {
      gps.reading = GpsTimeReading(
        gpsTime: DateTime.utc(2026, 10, 27, 9),
        monotonicAtReading: const Duration(hours: 9),
      );
      expect(trusted.now().gpsTrusted, isFalse);
    },
  );

  test('skew reports system minus trusted time when GPS is trusted', () {
    gps.reading = GpsTimeReading(
      gpsTime: DateTime.utc(2026, 10, 27, 9, 0, 10),
      monotonicAtReading: clock.mono,
    );
    expect(trusted.systemSkew, const Duration(seconds: -10));
  });

  test('skew is null without a trusted reading', () {
    expect(trusted.systemSkew, isNull);
  });
}
