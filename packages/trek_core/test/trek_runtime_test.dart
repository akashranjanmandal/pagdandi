import 'dart:async';
import 'dart:typed_data';

import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
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
  }) => lines.add('${level.name}:$tag:$message');
}

/// Records the order in which the outside world is touched.
class _Calls {
  final order = <String>[];
}

class _Haptic extends FakeHapticOutput {
  _Haptic(this.calls);
  final _Calls calls;
  Error? error;
  @override
  Future<void> play(HapticPattern p) async {
    calls.order.add('haptic:${p.name}');
    if (error != null) throw error!;
    await super.play(p);
  }
}

class _Beacon extends FakeBeaconTransport {
  _Beacon(this.calls);
  final _Calls calls;
  @override
  Future<void> startBeacon(Uint8List payload) async {
    calls.order.add('beacon:on');
    await super.startBeacon(payload);
  }

  @override
  Future<void> stopBeacon() async {
    calls.order.add('beacon:off');
    await super.stopBeacon();
  }
}

class _Sms extends FakeSmsGateway {
  _Sms(this.calls);
  final _Calls calls;
  @override
  Future<void> send(SmsMessage m) async {
    calls.order.add('sms:${m.to}');
    await super.send(m);
  }
}

class _Alarms extends FakeAlarmScheduler {
  // The fake's parameter is private-named, so a super parameter can't be used.
  // ignore: use_super_parameters
  _Alarms(Clock clock, this.calls) : super(clock);
  final _Calls calls;
  @override
  Future<void> schedule(int id, DateTime at) async {
    calls.order.add('alarm:schedule');
    await super.schedule(id, at);
  }

  @override
  Future<void> cancel(int id) async {
    calls.order.add('alarm:cancel');
    await super.cancel(id);
  }
}

class _Rig {
  _Rig({
    FakeSnapshotStore? snapshots,
    FakeSmsOutboxStore? outbox,
    bool signal = true,
  }) : snapshots = snapshots ?? FakeSnapshotStore(),
       outbox = outbox ?? FakeSmsOutboxStore() {
    gps.receive(clock.now());
    this.signal.set(signal ? SignalState.inService : SignalState.noService);
    runtime = _build();
  }

  final clock = FakeClock(DateTime.utc(2026, 10, 27, 14));
  late final gps = FakeGpsTimeSource(clock);
  late final trusted = TrustedClock(system: clock, gps: gps);
  final calls = _Calls();
  final log = _Log();
  final FakeSnapshotStore snapshots;
  final FakeSmsOutboxStore outbox;
  final signal = FakeSignalMonitor();
  final battery = FakeBatteryMonitor(level: 41);
  final location = FakeLocationSource();
  late final haptic = _Haptic(calls);
  late final beacon = _Beacon(calls);
  late final sms = _Sms(calls);
  late final alarms = _Alarms(clock, calls);
  late TrekRuntime runtime;
  final writtenFixes = <LocationFix>[];

  TrekRuntime _build() {
    final sos = SosKernel(
      sms: sms,
      signal: signal,
      store: outbox,
      clock: trusted,
      logger: log,
    );
    final tracking = TrackingPipeline(
      location: location,
      sink: (b) async => writtenFixes.addAll(b),
      logger: log,
    );
    return TrekRuntime(
      clock: trusted,
      snapshots: snapshots,
      sos: sos,
      haptics: haptic,
      beacon: beacon,
      alarms: alarms,
      tracking: tracking,
      battery: battery,
      logger: log,
      memberName: 'Akash',
      contacts: () => const ['+91A', '+91B'],
    );
  }

  /// A new runtime over the same storage, as after a reboot.
  TrekRuntime reboot() {
    runtime.dispose();
    return runtime = _build();
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));
}

LocationFix fix() => LocationFix(
  latitude: 27.041,
  longitude: 88.2663,
  accuracyM: 8,
  gpsTime: DateTime.utc(2026, 10, 27, 14),
  altitudeM: 3102,
);

void main() {
  late _Rig r;
  setUp(() => r = _Rig());

  group('state and snapshots', () {
    test('dispatch applies the reducer and publishes the new state', () async {
      await r.runtime.start();
      final seen = <TrekState>[];
      r.runtime.states.listen(seen.add);
      await r.runtime.dispatch(const StartTrek());
      expect(r.runtime.state.activity, Activity.stationary);
      expect(seen.last.activity, Activity.stationary);
    });

    test('a snapshot is saved on every transition', () async {
      await r.runtime.start();
      await r.runtime.dispatch(const StartTrek());
      await r.runtime.dispatch(const MotionDetected());
      expect(r.snapshots.saved, hasLength(2));
      expect(decodeSnapshot(r.snapshots.saved.last)!.activity, Activity.moving);
    });

    test('an ignored event changes nothing and saves nothing', () async {
      await r.runtime.start();
      await r.runtime.dispatch(const MotionDetected());
      expect(r.snapshots.saved, isEmpty);
    });

    test(
      'a failing snapshot store never stops the transition or its effects',
      () async {
        await r.runtime.start();
        r.snapshots.failWrites = true;
        await r.runtime.dispatch(const SosPressed());
        expect(r.runtime.state.emergency, const SosActive());
        expect(r.sms.sent, hasLength(2));
        expect(r.log.lines.any((l) => l.startsWith('error:')), isTrue);
      },
    );

    test('events are processed one at a time, in order', () async {
      await r.runtime.start();
      final futures = [
        r.runtime.dispatch(const StartTrek()),
        r.runtime.dispatch(const MotionDetected()),
        r.runtime.dispatch(const StillnessDetected()),
        r.runtime.dispatch(const MotionDetected()),
      ];
      await Future.wait(futures);
      expect(r.runtime.state.activity, Activity.moving);
      expect(r.snapshots.saved, hasLength(4));
    });
  });

  group('SOS', () {
    test('holding SOS raises it, lights the beacon and buzzes', () async {
      await r.runtime.start();
      r.location.emit(fix());
      await r.runtime.dispatch(const StartTrek());
      r.location.emit(fix());
      await r.runtime.dispatch(const SosPressed());
      await r.settle();
      expect(r.sms.sent.map((m) => m.to), ['+91A', '+91B']);
      expect(r.sms.sent.first.body, contains('Akash'));
      expect(r.sms.sent.first.body, contains('battery 41%'));
      expect(r.beacon.broadcasting, isNotNull);
      expect(r.haptic.played, [HapticPattern.sos]);
    });

    test('the SOS goes out even with no trek running and no GPS fix', () async {
      await r.runtime.start();
      await r.runtime.dispatch(const SosPressed());
      expect(r.sms.sent.first.body, contains('Position unknown'));
    });

    test('cancelling stops the beacon and buzz and tells contacts', () async {
      await r.runtime.start();
      await r.runtime.dispatch(const SosPressed());
      await r.runtime.dispatch(const SosCancelled());
      await r.settle();
      expect(r.beacon.broadcasting, isNull);
      expect(r.haptic.repeating, isNull);
      expect(
        r.sms.sent.where((m) => m.body.contains('cancelled')),
        hasLength(2),
      );
      expect(r.runtime.state.emergency, const NoEmergency());
    });

    test('safety effects run before housekeeping, whatever order the reducer '
        'listed them in', () async {
      await r.runtime.start();
      await r.runtime.dispatch(const FallSuspected());
      r.calls.order.clear();
      // The reducer lists CancelFallDeadline first; the SOS must still go out
      // before the alarm is cancelled.
      await r.runtime.dispatch(const SosPressed());
      final order = r.calls.order;
      expect(order.indexOf('sms:+91A'), isNonNegative);
      expect(
        order.indexOf('sms:+91A'),
        lessThan(order.indexOf('alarm:cancel')),
      );
      expect(
        order.indexOf('beacon:on'),
        lessThan(order.indexOf('alarm:cancel')),
      );
    });
  });

  group('fault isolation', () {
    test('a failing haptic never stops the SOS', () async {
      await r.runtime.start();
      r.haptic.error = StateError('vibrator gone');
      final warnings = <HealthWarning>[];
      r.runtime.warnings.listen(warnings.add);
      await r.runtime.dispatch(const SosPressed());
      expect(r.sms.sent, hasLength(2));
      expect(r.beacon.broadcasting, isNotNull);
      expect(warnings.single.source, 'Haptic');
    });

    test('a failing beacon never stops the SOS or the haptic', () async {
      await r.runtime.start();
      final failing = _FailingBeacon();
      final rig = _Rig();
      // use a runtime whose beacon throws
      final rt = rig._buildWith(beacon: failing);
      await rt.start();
      await rt.dispatch(const SosPressed());
      expect(rig.sms.sent, hasLength(2));
      expect(rig.haptic.played, [HapticPattern.sos]);
      rt.dispose();
    });
  });

  group('fall', () {
    test(
      'a suspected fall schedules the alarm and shows the fall screen',
      () async {
        await r.runtime.start();
        final ui = <Effect>[];
        r.runtime.uiCommands.listen(ui.add);
        await r.runtime.dispatch(const FallSuspected());
        expect(r.alarms.pending, [AlarmIds.fall]);
        expect(ui, [const ShowFallScreen()]);
      },
    );

    test('the alarm firing sends the SOS', () async {
      await r.runtime.start();
      await r.runtime.dispatch(const FallSuspected());
      r.clock.advance(const Duration(seconds: 61));
      r.alarms.fireDue();
      await r.settle();
      expect(r.runtime.state.emergency, const SosActive());
      expect(r.sms.sent, hasLength(2));
    });

    test('I am OK cancels the alarm: no SOS later', () async {
      await r.runtime.start();
      await r.runtime.dispatch(const FallSuspected());
      await r.runtime.dispatch(const FallCancelled());
      expect(r.alarms.pending, isEmpty);
      r.clock.advance(const Duration(seconds: 61));
      r.alarms.fireDue();
      await r.settle();
      expect(r.sms.sent, isEmpty);
    });
  });

  group('tracking and friend alerts', () {
    test('starting a trek starts tracking; ending stops it', () async {
      await r.runtime.start();
      await r.runtime.dispatch(const StartTrek());
      expect(r.location.isRunning, isTrue);
      await r.runtime.dispatch(const EndTrek());
      expect(r.location.isRunning, isFalse);
    });

    test(
      'a friend SOS buzzes and shows the alert; acknowledging stops it',
      () async {
        await r.runtime.start();
        final ui = <Effect>[];
        r.runtime.uiCommands.listen(ui.add);
        await r.runtime.dispatch(const FriendSosReceived('rahul'));
        expect(r.haptic.repeating, HapticPattern.sos);
        expect(ui, [const ShowFriendScreen('rahul')]);
        await r.runtime.dispatch(const FriendSosAcknowledged());
        expect(r.haptic.repeating, isNull);
      },
    );

    test('lost mode lights the beacon and arms the SOS', () async {
      await r.runtime.start();
      await r.runtime.dispatch(const LostModeEntered());
      expect(r.beacon.broadcasting, isNotNull);
      expect(r.sms.sent, hasLength(2));
      await r.runtime.dispatch(const FoundByGroup());
      expect(r.beacon.broadcasting, isNull);
    });
  });

  group('recovery after a restart or reboot', () {
    test('a running trek resumes tracking', () async {
      await r.runtime.start();
      await r.runtime.dispatch(const StartTrek());
      await r.runtime.dispatch(const MotionDetected());
      final rt = r.reboot();
      await r.location.stop();
      await rt.start();
      expect(rt.state.activity, Activity.moving);
      expect(r.location.isRunning, isTrue);
    });

    test(
      'an active SOS survives a reboot: beacon back on, outbox flushed',
      () async {
        final noSignal = _Rig(signal: false);
        await noSignal.runtime.start();
        await noSignal.runtime.dispatch(const SosPressed());
        expect(noSignal.sms.sent, isEmpty);
        final rt = noSignal.reboot();
        await noSignal.beacon.stopBeacon();
        noSignal.signal.set(SignalState.inService);
        await rt.start();
        await noSignal.settle();
        expect(rt.state.emergency, const SosActive());
        expect(noSignal.beacon.broadcasting, isNotNull);
        expect(noSignal.sms.sent, hasLength(2));
      },
    );

    test(
      'a fall countdown still running is re-armed for the same deadline',
      () async {
        await r.runtime.start();
        await r.runtime.dispatch(const FallSuspected());
        r.clock.advance(const Duration(seconds: 20));
        final rt = r.reboot();
        await rt.start();
        expect(r.alarms.pending, [AlarmIds.fall]);
        r.clock.advance(const Duration(seconds: 41));
        r.alarms.fireDue();
        await r.settle();
        expect(rt.state.emergency, const SosActive());
      },
    );

    test(
      'a fall deadline that passed while the phone was off sends the SOS',
      () async {
        await r.runtime.start();
        await r.runtime.dispatch(const FallSuspected());
        r.clock.advance(const Duration(minutes: 5));
        r.gps.receive(r.clock.now());
        final rt = r.reboot();
        await rt.start();
        await r.settle();
        expect(rt.state.emergency, const SosActive());
        expect(r.sms.sent, hasLength(2));
      },
    );

    test(
      'a corrupt snapshot is ignored but an SOS in the outbox is not lost',
      () async {
        await r.runtime.start();
        await r.runtime.dispatch(const SosPressed());
        r.snapshots.saved
          ..clear()
          ..add('{corrupt');
        final rt = r.reboot();
        await rt.start();
        expect(rt.state.emergency, const SosActive());
      },
    );

    test('a corrupt snapshot with nothing active starts idle', () async {
      r.snapshots.saved.add('{corrupt');
      await r.runtime.start();
      expect(r.runtime.state, TrekState.idle);
    });

    test('with no snapshot the runtime starts idle', () async {
      await r.runtime.start();
      expect(r.runtime.state, TrekState.idle);
    });
  });

  group('SOS progress', () {
    test('is exposed for the UI, live', () async {
      await r.runtime.start();
      final seen = <int>[];
      r.runtime.sosSummary.listen((s) => seen.add(s.delivered));
      expect(r.runtime.sosCurrent.active, isFalse);
      await r.runtime.dispatch(const SosPressed());
      expect(r.runtime.sosCurrent.active, isTrue);
      expect(r.runtime.sosCurrent.total, 2);
      final id = (await r.outbox.all()).first.id;
      r.sms.report(id, SmsStatus.delivered);
      await r.settle();
      expect(r.runtime.sosCurrent.delivered, 1);
      expect(seen.last, 1);
    });
  });

  group('lifecycle', () {
    test('after dispose the alarm no longer drives the state', () async {
      await r.runtime.start();
      await r.runtime.dispatch(const FallSuspected());
      r.runtime.dispose();
      r.clock.advance(const Duration(seconds: 61));
      r.alarms.fireDue();
      await r.settle();
      expect(r.sms.sent, isEmpty);
    });
  });
}

class _FailingBeacon extends FakeBeaconTransport {
  @override
  Future<void> startBeacon(Uint8List payload) async =>
      throw StateError('bluetooth off');
}

extension on _Rig {
  TrekRuntime _buildWith({required BeaconTransport beacon}) {
    final sos = SosKernel(
      sms: sms,
      signal: signal,
      store: outbox,
      clock: trusted,
      logger: log,
    );
    final tracking = TrackingPipeline(
      location: location,
      sink: (b) async {},
      logger: log,
    );
    return TrekRuntime(
      clock: trusted,
      snapshots: snapshots,
      sos: sos,
      haptics: haptic,
      beacon: beacon,
      alarms: alarms,
      tracking: tracking,
      battery: battery,
      logger: log,
      memberName: 'Akash',
      contacts: () => const ['+91A', '+91B'],
    );
  }
}
