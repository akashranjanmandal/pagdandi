import 'dart:typed_data';

import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';
import 'package:trek_core/trek_core.dart';

LocationFix fix(DateTime t) => LocationFix(
  latitude: 27,
  longitude: 88,
  accuracyM: 5,
  gpsTime: t,
);

void main() {
  group('GpsTimeTracker', () {
    test('has no reading until a fix arrives', () {
      expect(GpsTimeTracker(FakeClock(DateTime.utc(2026))).latest, isNull);
    });

    test('a fix gives a reading stamped with the monotonic clock', () {
      final clock = FakeClock(DateTime.utc(2026))
        ..advance(const Duration(minutes: 3));
      final t = GpsTimeTracker(clock)
        ..observe(fix(DateTime.utc(2026, 1, 1, 0, 3)));
      expect(t.latest!.gpsTime, DateTime.utc(2026, 1, 1, 0, 3));
      expect(t.latest!.monotonicAtReading, const Duration(minutes: 3));
    });

    test('feeds TrustedClock: GPS time wins over a wrong phone clock', () {
      final clock = FakeClock(DateTime.utc(2020));
      final t = GpsTimeTracker(clock)
        ..observe(fix(DateTime.utc(2026, 10, 27, 14)));
      final trusted = TrustedClock(system: clock, gps: t);
      clock.advance(const Duration(seconds: 30));
      expect(trusted.now().time, DateTime.utc(2026, 10, 27, 14, 0, 30));
      expect(trusted.now().gpsTrusted, isTrue);
    });

    test('the newest fix replaces the old reading', () {
      final clock = FakeClock(DateTime.utc(2026));
      final t = GpsTimeTracker(clock)
        ..observe(fix(DateTime.utc(2026)))
        ..observe(fix(DateTime.utc(2026, 1, 1, 0, 0, 5)));
      expect(t.latest!.gpsTime, DateTime.utc(2026, 1, 1, 0, 0, 5));
    });
  });

  group('UnavailableBeaconTransport', () {
    test('says clearly that it is not available instead of pretending', () {
      final b = UnavailableBeaconTransport();
      expect(b.capabilities.codedPhy, isFalse);
      expect(() => b.startBeacon(Uint8List(0)), throwsStateError);
      expect(b.stopBeacon(), completes);
      expect(b.startScan, throwsStateError);
      expect(b.stopScan(), completes);
      expect(b.sightings, isNotNull);
    });
  });
}
