import 'package:engine_health/engine_health.dart';
import 'package:test/test.dart';

final now = DateTime.utc(2026, 10, 27, 14);

HealthInputs inputs({
  bool trek = true,
  DateTime? started,
  DateTime? lastFix,
  bool fine = true,
  bool background = true,
  bool sms = true,
  bool exempt = true,
  int storageMb = 5000,
  int battery = 80,
}) => HealthInputs(
  now: now,
  trekActive: trek,
  trekStartedAt: started ?? now.subtract(const Duration(hours: 1)),
  lastFixAt: lastFix ?? now.subtract(const Duration(seconds: 10)),
  locationPermission: fine,
  backgroundLocationPermission: background,
  smsPermission: sms,
  batteryOptimizationExempt: exempt,
  storageFreeMb: storageMb,
  batteryPercent: battery,
);

Set<Type> kinds(List<HealthIssue> l) => l.map((i) => i.runtimeType).toSet();

void main() {
  const wd = HealthWatchdog();

  test('a healthy trek has no issues', () {
    expect(wd.evaluate(inputs()), isEmpty);
  });

  group('GPS', () {
    test('a fix older than two minutes during a trek is stale', () {
      final r = wd.evaluate(
        inputs(lastFix: now.subtract(const Duration(minutes: 3))),
      );
      expect(kinds(r), {GpsStale});
      expect((r.single as GpsStale).age, const Duration(minutes: 3));
      expect(r.single.severity, Severity.warn);
    });

    test('no fix at all two minutes after the trek began is stale too', () {
      final r = wd.evaluate(
        HealthInputs(
          now: now,
          trekActive: true,
          trekStartedAt: now.subtract(const Duration(minutes: 5)),
          lastFixAt: null,
          locationPermission: true,
          backgroundLocationPermission: true,
          smsPermission: true,
          batteryOptimizationExempt: true,
          storageFreeMb: 5000,
          batteryPercent: 80,
        ),
      );
      expect(kinds(r), {GpsStale});
      expect((r.single as GpsStale).age, isNull);
    });

    test('no fix yet but the trek only just began is fine', () {
      final r = wd.evaluate(
        HealthInputs(
          now: now,
          trekActive: true,
          trekStartedAt: now.subtract(const Duration(seconds: 30)),
          lastFixAt: null,
          locationPermission: true,
          backgroundLocationPermission: true,
          smsPermission: true,
          batteryOptimizationExempt: true,
          storageFreeMb: 5000,
          batteryPercent: 80,
        ),
      );
      expect(r, isEmpty);
    });

    test('staleness is ignored when no trek is running', () {
      expect(
        wd.evaluate(
          inputs(trek: false, lastFix: now.subtract(const Duration(hours: 2))),
        ),
        isEmpty,
      );
    });

    test('the threshold is configurable', () {
      const strict = HealthWatchdog(gpsStaleAfter: Duration(seconds: 20));
      expect(
        kinds(
          strict.evaluate(
            inputs(lastFix: now.subtract(const Duration(seconds: 30))),
          ),
        ),
        {GpsStale},
      );
    });
  });

  group('permissions', () {
    test('no location permission is critical', () {
      final r = wd.evaluate(inputs(fine: false));
      expect(kinds(r), {PermissionMissing});
      expect((r.single as PermissionMissing).permission, 'location');
      expect(r.single.severity, Severity.critical);
    });

    test('no SMS permission is critical: an SOS could not be sent', () {
      final r = wd.evaluate(inputs(sms: false));
      expect((r.single as PermissionMissing).permission, 'sms');
      expect(r.single.severity, Severity.critical);
    });

    test('no background location is a warning', () {
      final r = wd.evaluate(inputs(background: false));
      expect((r.single as PermissionMissing).permission, 'background location');
      expect(r.single.severity, Severity.warn);
    });

    test('not exempt from battery optimisation is a warning', () {
      final r = wd.evaluate(inputs(exempt: false));
      expect(kinds(r), {BatteryOptimised});
      expect(r.single.severity, Severity.warn);
    });
  });

  group('storage and battery', () {
    test('storage under 100 MB warns, under 20 MB is critical', () {
      expect(wd.evaluate(inputs(storageMb: 99)).single.severity, Severity.warn);
      expect(
        wd.evaluate(inputs(storageMb: 19)).single.severity,
        Severity.critical,
      );
      expect(wd.evaluate(inputs(storageMb: 100)), isEmpty);
      expect(
        (wd.evaluate(inputs(storageMb: 50)).single as StorageLow).freeMb,
        50,
      );
    });

    test('battery under 15 percent warns, under 5 percent is critical', () {
      expect(wd.evaluate(inputs(battery: 14)).single.severity, Severity.warn);
      expect(
        wd.evaluate(inputs(battery: 4)).single.severity,
        Severity.critical,
      );
      expect(wd.evaluate(inputs(battery: 15)), isEmpty);
      expect(
        (wd.evaluate(inputs(battery: 10)).single as BatteryLow).percent,
        10,
      );
    });
  });

  group('ordering and wording', () {
    test('most severe first', () {
      final r = wd.evaluate(inputs(background: false, sms: false, battery: 10));
      expect(r.map((i) => i.severity), [
        Severity.critical,
        Severity.warn,
        Severity.warn,
      ]);
    });

    test(
      'every issue says what is wrong and how to fix it, in plain words',
      () {
        final r = wd.evaluate(
          inputs(
            lastFix: now.subtract(const Duration(minutes: 3)),
            fine: false,
            sms: false,
            background: false,
            exempt: false,
            storageMb: 10,
            battery: 3,
          ),
        );
        expect(r.length, 7);
        for (final i in r) {
          expect(i.message, isNotEmpty);
          expect(i.fixHint, isNotEmpty);
          expect(i.message, isNot(contains('!')));
        }
      },
    );

    test('messages carry the facts', () {
      final r = wd.evaluate(
        inputs(lastFix: now.subtract(const Duration(minutes: 3))),
      );
      expect(r.single.message, contains('3 min'));
    });
  });

  group('HealthMonitor', () {
    test('publishes only when the set of issues changes', () {
      final m = HealthMonitor(wd);
      final seen = <List<HealthIssue>>[];
      m.changes.listen(seen.add);
      m.check(inputs());
      m.check(inputs());
      m.check(inputs(sms: false));
      m.check(inputs(sms: false));
      m.check(inputs());
      expect(seen.map((l) => l.length), [1, 0]);
      expect(m.current, isEmpty);
    });

    test('issues compare by kind and facts, not identity', () {
      expect(const StorageLow(50), const StorageLow(50));
      expect(const StorageLow(50).hashCode, const StorageLow(50).hashCode);
      expect(const StorageLow(50), isNot(const StorageLow(51)));
      expect(
        const PermissionMissing('sms', Severity.critical),
        const PermissionMissing('sms', Severity.critical),
      );
      expect(const BatteryOptimised(), const BatteryOptimised());
      expect(const BatteryLow(3), const BatteryLow(3));
      expect(
        const GpsStale(Duration(minutes: 3)),
        const GpsStale(Duration(minutes: 3)),
      );
    });
  });
}
