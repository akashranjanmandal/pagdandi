import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:test/test.dart';

LocationFix fix({double? alt = 3102}) => LocationFix(
  latitude: 27.041,
  longitude: 88.2663,
  accuracyM: 8,
  gpsTime: DateTime.utc(2026, 10, 27, 14, 32),
  altitudeM: alt,
);

SosReport report({
  LocationFix? f,
  bool trusted = true,
  int battery = 41,
  bool noFix = false,
}) => SosReport(
  name: 'Akash',
  fix: noFix ? null : (f ?? fix()),
  time: Timestamp(
    time: DateTime.utc(2026, 10, 27, 14, 33),
    gpsTrusted: trusted,
  ),
  batteryPercent: battery,
);

void main() {
  group('SOS message', () {
    test(
      'carries who, position, accuracy, altitude, GPS time, battery, link',
      () {
        final m = formatSosMessage(report());
        expect(m, contains('SOS'));
        expect(m, contains('Akash'));
        expect(m, contains('27.0410, 88.2663'));
        expect(m, contains('±8 m'));
        expect(m, contains('3102 m'));
        expect(m, contains('2026-10-27 14:32 UTC'));
        expect(m, contains('battery 41%'));
        expect(m, contains('https://maps.google.com/?q=27.041,88.2663'));
      },
    );

    test('omits altitude when the fix has none', () {
      expect(
        formatSosMessage(report(f: fix(alt: null))),
        isNot(contains(' alt ')),
      );
    });

    test('without any fix it still sends and says the position is unknown', () {
      final m = formatSosMessage(report(noFix: true));
      expect(m, contains('Position unknown'));
      expect(m, contains('Akash'));
      expect(m, isNot(contains('maps.google.com')));
    });

    test('flags the time when it is only the phone clock', () {
      final m = formatSosMessage(report(noFix: true, trusted: false));
      expect(m, contains('(phone clock)'));
      expect(
        formatSosMessage(report(noFix: true)),
        isNot(contains('(phone clock)')),
      );
    });

    test('is short enough for one multipart SMS (under 320 characters)', () {
      expect(formatSosMessage(report()).length, lessThan(320));
    });
  });

  group('cancel message', () {
    test('says the person is OK and the SOS is cancelled', () {
      final m = formatCancelMessage(
        name: 'Akash',
        time: Timestamp(
          time: DateTime.utc(2026, 10, 27, 14, 40),
          gpsTrusted: true,
        ),
      );
      expect(m, contains('Akash'));
      expect(m, contains('cancelled'));
      expect(m, contains('2026-10-27 14:40 UTC'));
    });

    test('flags a phone-clock time', () {
      final m = formatCancelMessage(
        name: 'A',
        time: Timestamp(time: DateTime.utc(2026), gpsTrusted: false),
      );
      expect(m, contains('(phone clock)'));
    });
  });

  group('BackoffPolicy', () {
    const b = BackoffPolicy();
    test('starts at 30 seconds and doubles', () {
      expect(b.delayFor(1), const Duration(seconds: 30));
      expect(b.delayFor(2), const Duration(seconds: 60));
      expect(b.delayFor(3), const Duration(seconds: 120));
    });

    test('is capped at 10 minutes and never overflows', () {
      expect(b.delayFor(8), const Duration(minutes: 10));
      expect(b.delayFor(500), const Duration(minutes: 10));
    });

    test('a first delay longer than the cap is still capped', () {
      const odd = BackoffPolicy(
        initial: Duration(minutes: 20),
      );
      expect(odd.delayFor(1), const Duration(minutes: 10));
    });

    test('attempt numbers below 1 are treated as the first', () {
      expect(b.delayFor(0), const Duration(seconds: 30));
    });
  });
}
