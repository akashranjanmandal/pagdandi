import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

void main() {
  test('FakeLocationSource streams fixes and records requests', () async {
    final loc = FakeLocationSource();
    final got = <LocationFix>[];
    loc.fixes.listen(got.add);
    await loc.request(const LocationRequest(interval: Duration(seconds: 5)));
    final fix = LocationFix(
      latitude: 27,
      longitude: 88,
      accuracyM: 5,
      gpsTime: DateTime.utc(2026),
    );
    loc.emit(fix);
    expect(got, [fix]);
    expect(loc.requests.single.interval, const Duration(seconds: 5));
    await loc.stop();
    expect(loc.isRunning, isFalse);
  });

  test('FakeHapticOutput logs patterns and tracks a repeating one', () async {
    final h = FakeHapticOutput();
    await h.play(HapticPattern.junction);
    await h.play(HapticPattern.offRoute);
    expect(h.played, [HapticPattern.junction, HapticPattern.offRoute]);
    expect(h.repeating, HapticPattern.offRoute);
    await h.cancel();
    expect(h.repeating, isNull);
  });

  test('FakeSignalMonitor emits changes and exposes the current state', () {
    final s = FakeSignalMonitor();
    final got = <SignalState>[];
    s.changes.listen(got.add);
    expect(s.current, SignalState.noService);
    s.set(SignalState.inService);
    expect(s.current, SignalState.inService);
    expect(got, [SignalState.inService]);
  });

  test('FakeSmsGateway records sends and relays reports', () async {
    final g = FakeSmsGateway();
    final reports = <SmsReport>[];
    g.reports.listen(reports.add);
    await g.send(const SmsMessage(id: '1', to: '+91', body: 'sos'));
    g.report('1', SmsStatus.delivered);
    expect(g.sent.single.id, '1');
    expect(reports.single.status, SmsStatus.delivered);
  });

  test('FakeAlarmScheduler fires only alarms that are due', () async {
    final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
    final a = FakeAlarmScheduler(clock);
    final fired = <int>[];
    a.fired.listen(fired.add);
    await a.schedule(1, DateTime.utc(2026, 1, 1, 10));
    await a.schedule(2, DateTime.utc(2026, 1, 1, 11));
    await a.cancel(2);
    clock.advance(const Duration(hours: 2));
    a.fireDue();
    expect(fired, [1]);
    a.fireDue();
    expect(fired, [1]);
  });

  test(
    'FakeTorchOutput, FakeSirenOutput and FakeBatteryMonitor hold state',
    () async {
      final t = FakeTorchOutput();
      await t.setStrobe(on: true);
      expect(t.strobing, isTrue);
      final s = FakeSirenOutput();
      await s.setOn(on: true);
      expect(s.isOn, isTrue);
      final b = FakeBatteryMonitor(level: 80);
      final got = <int>[];
      b.changes.listen(got.add);
      b.set(41);
      expect(b.level, 41);
      expect(got, [41]);
    },
  );

  test('FakeGpsTimeSource feeds TrustedClock', () {
    final clock = FakeClock(DateTime.utc(2026, 1, 1, 9));
    final gps = FakeGpsTimeSource(clock)
      ..receive(DateTime.utc(2026, 1, 1, 9, 0, 5));
    final trusted = TrustedClock(system: clock, gps: gps);
    expect(trusted.now().gpsTrusted, isTrue);
    expect(trusted.now().time, DateTime.utc(2026, 1, 1, 9, 0, 5));
  });
}
