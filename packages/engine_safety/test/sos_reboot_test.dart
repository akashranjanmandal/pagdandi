import 'dart:io';

import 'package:core_common/core_common.dart';
import 'package:core_db/core_db.dart';
import 'package:core_model/core_model.dart';
import 'package:drift/native.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

/// Fault injection: reboot with a pending SOS, using a real SQLite file.
void main() {
  late Directory dir;
  late File file;
  late FakeClock clock;
  late FakeGpsTimeSource gps;
  late TrustedClock trusted;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pagdandi_reboot');
    file = File('${dir.path}/trek.sqlite');
    clock = FakeClock(DateTime.utc(2026, 10, 27, 14));
    gps = FakeGpsTimeSource(clock)..receive(clock.now());
    trusted = TrustedClock(system: clock, gps: gps);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  SosReport report() => SosReport(
    name: 'Akash',
    fix: LocationFix(
      latitude: 27.041,
      longitude: 88.2663,
      accuracyM: 8,
      gpsTime: clock.now(),
    ),
    time: trusted.now(),
    batteryPercent: 41,
  );

  test('an SOS raised with no signal is sent after a full reboot', () async {
    // First boot: no signal, the SOS is raised and waits in the outbox.
    final db1 = PagdandiDatabase(NativeDatabase(file));
    final signal1 = FakeSignalMonitor();
    final sms1 = FakeSmsGateway();
    final k1 = SosKernel(
      sms: sms1,
      signal: signal1,
      store: DriftSmsOutboxStore(db1),
      clock: trusted,
      logger: const NoopLogger(),
    );
    await k1.start();
    await k1.raise(report: report(), contacts: const ['+91A', '+91B']);
    expect(sms1.sent, isEmpty);
    // Power loss: everything in memory is gone.
    k1.dispose();
    await db1.close();

    // Second boot: a brand-new kernel, database connection and radio.
    clock.advance(const Duration(minutes: 7));
    gps.receive(clock.now());
    final db2 = PagdandiDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final signal2 = FakeSignalMonitor();
    final sms2 = FakeSmsGateway();
    final k2 = SosKernel(
      sms: sms2,
      signal: signal2,
      store: DriftSmsOutboxStore(db2),
      clock: trusted,
      logger: const NoopLogger(),
    );
    await k2.start();
    expect(k2.current.active, isTrue);
    expect(k2.current.queued, 2);
    expect(sms2.sent, isEmpty, reason: 'still no signal');

    // First signal after the reboot.
    signal2.set(SignalState.inService);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(sms2.sent.map((m) => m.to), ['+91A', '+91B']);
    expect(sms2.sent.first.body, contains('SOS Akash'));
    k2.dispose();
  });

  test('delivered messages are not sent again after a reboot', () async {
    final db1 = PagdandiDatabase(NativeDatabase(file));
    final signal = FakeSignalMonitor()..set(SignalState.inService);
    final sms1 = FakeSmsGateway();
    final k1 = SosKernel(
      sms: sms1,
      signal: signal,
      store: DriftSmsOutboxStore(db1),
      clock: trusted,
      logger: const NoopLogger(),
    );
    await k1.start();
    await k1.raise(report: report(), contacts: const ['+91A']);
    sms1.report(
      (await DriftSmsOutboxStore(db1).all()).single.id,
      SmsStatus.delivered,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    k1.dispose();
    await db1.close();

    final db2 = PagdandiDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final sms2 = FakeSmsGateway();
    final k2 = SosKernel(
      sms: sms2,
      signal: signal,
      store: DriftSmsOutboxStore(db2),
      clock: trusted,
      logger: const NoopLogger(),
    );
    await k2.start();
    expect(sms2.sent, isEmpty);
    expect(k2.current.delivered, 1);
    expect(k2.current.active, isTrue);
    k2.dispose();
  });
}
