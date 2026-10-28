import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_bridge/native_bridge.dart';
import 'package:testing/testing.dart';

class _Host extends PagdandiHostApi {
  int battery = 77;
  DeviceCapabilities caps = DeviceCapabilities(
    sdkInt: 34,
    leCodedPhySupported: true,
    leExtendedAdvertisingSupported: false,
    hasBarometer: true,
    hasSignificantMotion: false,
  );
  SignalStateDto signal = SignalStateDto.inService;
  final sentSms = <(String, String, String)>[];
  final locationRequests = <LocationRequestDto>[];
  final beats = <int>[];
  final roles = <String>[];
  final commandsSent = <String>[];
  final statesPublished = <String>[];
  int serviceStarts = 0;
  int serviceStops = 0;
  int locationStops = 0;
  final haptics = <HapticRequest>[];
  int cancels = 0;

  @override
  Future<int> batteryLevel() async => battery;

  @override
  Future<DeviceCapabilities> deviceCapabilities() async => caps;

  @override
  Future<void> playHaptic(HapticRequest request) async => haptics.add(request);

  @override
  Future<void> cancelHaptic() async => cancels++;

  @override
  Future<void> sendSms(String id, String to, String body) async =>
      sentSms.add((id, to, body));

  @override
  Future<SignalStateDto> signalState() async => signal;

  @override
  Future<void> startLocation(LocationRequestDto request) async =>
      locationRequests.add(request);

  @override
  Future<void> stopLocation() async => locationStops++;

  @override
  Future<String> databasePath() async => '/data/pagdandi.sqlite';

  @override
  Future<void> heartbeat(int atMs) async => beats.add(atMs);

  @override
  Future<void> startTrekService() async => serviceStarts++;

  @override
  Future<void> setRole(String role) async => roles.add(role);

  @override
  Future<void> sendCommand(String json) async => commandsSent.add(json);

  @override
  Future<void> publishState(String json) async => statesPublished.add(json);

  @override
  Future<void> stopTrekService() async => serviceStops++;

  final spoken = <(String, bool)>[];
  int speechStops = 0;
  final accelStarts = <int>[];
  int accelStops = 0;
  bool hasAccel = true;
  final torch = <(bool, bool)>[];
  final siren = <bool>[];
  final dialed = <String>[];
  final scheduled = <(int, int)>[];
  final cancelledAlarms = <int>[];
  List<int> fired = [];

  @override
  Future<void> speak(String text, bool urgent) async =>
      spoken.add((text, urgent));

  @override
  Future<void> stopSpeaking() async => speechStops++;

  @override
  Future<bool> startAccelerometer(int periodMs) async {
    accelStarts.add(periodMs);
    return hasAccel;
  }

  @override
  Future<void> stopAccelerometer() async => accelStops++;

  @override
  Future<void> setTorch(bool on, bool strobe) async => torch.add((on, strobe));

  @override
  Future<void> setSiren(bool on) async => siren.add(on);

  @override
  Future<void> openDialer(String number) async => dialed.add(number);

  @override
  Future<void> scheduleAlarm(int id, int atMs) async =>
      scheduled.add((id, atMs));

  @override
  Future<void> cancelAlarm(int id) async => cancelledAlarms.add(id);

  @override
  Future<List<int>> takeFiredAlarms() async {
    final out = fired;
    fired = [];
    return out;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeBatteryMonitor', () {
    test('reads the initial level from the host', () async {
      final m = await NativeBatteryMonitor.create(_Host(), NativeEvents());
      expect(m.level, 77);
    });

    test('updates level and emits changes when the hub reports one', () async {
      final hub = NativeEvents();
      final m = await NativeBatteryMonitor.create(_Host(), hub);
      final seen = <int>[];
      m.changes.listen(seen.add);
      hub.onBatteryLevel(41);
      expect(m.level, 41);
      expect(seen, [41]);
    });

    test('clamps nonsense values into 0..100', () async {
      final hub = NativeEvents();
      final m = await NativeBatteryMonitor.create(_Host(), hub);
      hub.onBatteryLevel(140);
      expect(m.level, 100);
      hub.onBatteryLevel(-3);
      expect(m.level, 0);
    });
  });

  group('NativeEvents', () {
    test('maps native SMS reports to core statuses', () {
      final hub = NativeEvents();
      final got = <SmsReport>[];
      hub.smsReports.listen(got.add);
      hub
        ..onSmsReport('a', SmsStatusDto.sending)
        ..onSmsReport('a', SmsStatusDto.sent)
        ..onSmsReport('a', SmsStatusDto.delivered)
        ..onSmsReport('a', SmsStatusDto.failed);
      expect(got.map((r) => r.status), [
        SmsStatus.sending,
        SmsStatus.sent,
        SmsStatus.delivered,
        SmsStatus.failed,
      ]);
      expect(got.every((r) => r.id == 'a'), isTrue);
    });

    test('maps native signal states to core states', () {
      final hub = NativeEvents();
      final got = <SignalState>[];
      hub.signal.listen(got.add);
      hub
        ..onSignalState(SignalStateDto.noService)
        ..onSignalState(SignalStateDto.emergencyOnly)
        ..onSignalState(SignalStateDto.inService);
      expect(got, [
        SignalState.noService,
        SignalState.emergencyOnly,
        SignalState.inService,
      ]);
    });
  });

  group('NativeSmsGateway', () {
    test('hands the message to the host', () async {
      final host = _Host();
      await NativeSmsGateway(
        host,
        NativeEvents(),
      ).send(const SmsMessage(id: 'sos-1|+91A', to: '+91A', body: 'help'));
      expect(host.sentSms.single, ('sos-1|+91A', '+91A', 'help'));
    });

    test('relays delivery reports from the hub', () async {
      final hub = NativeEvents();
      final g = NativeSmsGateway(_Host(), hub);
      final got = <SmsReport>[];
      g.reports.listen(got.add);
      hub.onSmsReport('x', SmsStatusDto.delivered);
      expect(got.single, const SmsReport(id: 'x', status: SmsStatus.delivered));
    });
  });

  group('NativeSignalMonitor', () {
    test('starts with the host state and follows the hub', () async {
      final host = _Host()..signal = SignalStateDto.noService;
      final hub = NativeEvents();
      final m = await NativeSignalMonitor.create(host, hub);
      expect(m.current, SignalState.noService);
      final got = <SignalState>[];
      m.changes.listen(got.add);
      hub.onSignalState(SignalStateDto.inService);
      expect(m.current, SignalState.inService);
      expect(got, [SignalState.inService]);
    });
  });

  group('NativeLocationSource', () {
    LocationFixDto dto({
      double lat = 27.04,
      double lon = 88.26,
      int ms = 1761573600000,
    }) => LocationFixDto(
      latitude: lat,
      longitude: lon,
      accuracyM: 6,
      timeMs: ms,
      altitudeM: 3100,
      speedMps: 1.2,
      bearingDeg: 90,
    );

    test('hub maps native fixes to core fixes in order, GPS time in UTC', () {
      final hub = NativeEvents();
      final got = <LocationFix>[];
      hub.locations.listen(got.add);
      hub.onLocations([
        dto(),
        dto(lat: 27.05, ms: 1761573605000),
      ]);
      expect(got, hasLength(2));
      expect(got.first.latitude, 27.04);
      expect(got.first.accuracyM, 6);
      expect(got.first.altitudeM, 3100);
      expect(got.first.speedMps, 1.2);
      expect(got.first.bearingDeg, 90);
      expect(
        got.first.gpsTime,
        DateTime.fromMillisecondsSinceEpoch(1761573600000, isUtc: true),
      );
      expect(got.last.latitude, 27.05);
    });

    test('optional fields stay null when the phone has none', () {
      final hub = NativeEvents();
      final got = <LocationFix>[];
      hub.locations.listen(got.add);
      hub.onLocations([
        LocationFixDto(latitude: 1, longitude: 2, accuracyM: 3, timeMs: 0),
      ]);
      expect(got.single.altitudeM, isNull);
      expect(got.single.speedMps, isNull);
      expect(got.single.bearingDeg, isNull);
    });

    test('an impossible fix is dropped, the rest of the batch is kept', () {
      final hub = NativeEvents();
      final got = <LocationFix>[];
      hub.locations.listen(got.add);
      hub.onLocations([
        dto(lat: 123),
        dto(lat: 27.1),
        LocationFixDto(latitude: 1, longitude: 2, accuracyM: -5, timeMs: 0),
      ]);
      expect(got.map((f) => f.latitude), [27.1]);
      expect(hub.droppedFixes, 2);
    });

    test(
      'request sends interval, batching delay and distance to the host',
      () async {
        final host = _Host();
        final src = NativeLocationSource(host, NativeEvents());
        await src.request(
          const LocationRequest(
            interval: Duration(seconds: 5),
            maxBatchDelay: Duration(minutes: 2),
            minDistanceM: 10,
          ),
        );
        final r = host.locationRequests.single;
        expect(r.intervalMs, 5000);
        expect(r.maxBatchDelayMs, 120000);
        expect(r.minDistanceM, 10);
      },
    );

    test('fixes come from the hub and stop is forwarded', () async {
      final host = _Host();
      final hub = NativeEvents();
      final src = NativeLocationSource(host, hub);
      final got = <LocationFix>[];
      src.fixes.listen(got.add);
      hub.onLocations([dto()]);
      expect(got, hasLength(1));
      await src.stop();
      expect(host.locationStops, 1);
    });
  });

  group('UI/core channel', () {
    test(
      'commands that arrive before anyone listens are buffered, in order',
      () async {
        final hub = NativeEvents()
          ..onCommand('a')
          ..onCommand('b');
        final got = <String>[];
        NativeCoreChannel(_Host(), hub).commands.listen(got.add);
        await Future<void>.delayed(Duration.zero);
        expect(got, ['a', 'b']);
      },
    );

    test('the core publishes states through the host', () async {
      final host = _Host();
      await NativeCoreChannel(host, NativeEvents()).publish('{"s":1}');
      expect(host.statesPublished, ['{"s":1}']);
    });

    test(
      'the core registers its role only when asked, after it listens',
      () async {
        final host = _Host();
        final c = NativeCoreChannel(host, NativeEvents());
        expect(host.roles, isEmpty);
        await c.register();
        expect(host.roles, ['core']);
      },
    );

    test(
      'the UI sends commands through the host and receives states',
      () async {
        final host = _Host();
        final hub = NativeEvents();
        final ui = NativeUiChannel(host, hub);
        await ui.send('{"c":"startTrek"}');
        expect(host.commandsSent, ['{"c":"startTrek"}']);
        final got = <String>[];
        ui.states.listen(got.add);
        hub.onState('s1');
        expect(got, ['s1']);
      },
    );

    test('the UI registers its role only when asked', () async {
      final host = _Host();
      await NativeUiChannel(host, NativeEvents()).register();
      expect(host.roles, ['ui']);
    });
  });

  group('service ports', () {
    test('the heartbeat sink sends epoch milliseconds to the host', () async {
      final host = _Host();
      await NativeHeartbeatSink(host).beat(DateTime.utc(2026, 10, 27, 14));
      expect(host.beats, [
        DateTime.utc(2026, 10, 27, 14).millisecondsSinceEpoch,
      ]);
    });

    test('the trek service forwards start and stop', () async {
      final host = _Host();
      final s = NativeTrekService(host);
      await s.start();
      await s.stop();
      expect(host.serviceStarts, 1);
      expect(host.serviceStops, 1);
    });
  });

  group('NativeHapticOutput', () {
    test('sends the waveform of the pattern to the host', () async {
      final host = _Host();
      await NativeHapticOutput(host).play(HapticPattern.junction);
      final r = host.haptics.single;
      expect(r.timings, HapticPattern.junction.waveform);
      expect(r.repeat, isFalse);
      expect(r.strong, isFalse);
    });

    test('passes repeat and strong flags', () async {
      final host = _Host();
      final out = NativeHapticOutput(host);
      await out.play(HapticPattern.sos);
      await out.play(HapticPattern.holdComplete);
      expect(host.haptics[0].repeat, isTrue);
      expect(host.haptics[1].strong, isTrue);
    });

    test('cancel is forwarded', () async {
      final host = _Host();
      await NativeHapticOutput(host).cancel();
      expect(host.cancels, 1);
    });
  });

  group('NativeTorchOutput and NativeSirenOutput', () {
    test('torch steady and strobe are forwarded', () async {
      final host = _Host();
      final t = NativeTorchOutput(host);
      await t.setOn(on: true);
      await t.setStrobe(on: true);
      await t.setStrobe(on: false);
      expect(host.torch, [(true, false), (true, true), (false, true)]);
    });

    test('siren on and off are forwarded', () async {
      final host = _Host();
      final s = NativeSirenOutput(host);
      await s.setOn(on: true);
      await s.setOn(on: false);
      expect(host.siren, [true, false]);
    });

    test('a failing host never throws into the caller', () async {
      final t = NativeTorchOutput(_ThrowingHost());
      await t.setOn(on: true);
      await NativeSirenOutput(_ThrowingHost()).setOn(on: true);
    });
  });

  group('NativeVoiceOutput', () {
    test('speaks, with urgency, through the host', () async {
      final host = _Host();
      final v = NativeVoiceOutput(host);
      await v.speak('Back on the trail.');
      await v.speak('Did you fall?', urgent: true);
      expect(host.spoken, [
        ('Back on the trail.', false),
        ('Did you fall?', true),
      ]);
    });

    test('stop is forwarded', () async {
      final host = _Host();
      await NativeVoiceOutput(host).stop();
      expect(host.speechStops, 1);
    });

    test('a failing host never throws into the caller', () async {
      final v = NativeVoiceOutput(_ThrowingHost());
      await v.speak('x');
      await v.stop();
    });
  });

  group('NativeAccelerometer', () {
    test(
      'starts the sensor on listen with the period, stops on cancel',
      () async {
        final host = _Host();
        final hub = NativeEvents();
        final a = NativeAccelerometer(host, hub);
        final sub = a.samples(const Duration(milliseconds: 40)).listen((_) {});
        await pumpEventQueue();
        expect(host.accelStarts, [40]);
        await sub.cancel();
        await pumpEventQueue();
        expect(host.accelStops, 1);
      },
    );

    test('batches become samples with their monotonic times', () async {
      final hub = NativeEvents();
      final a = NativeAccelerometer(_Host(), hub);
      final got = <AccelSample>[];
      final sub = a.samples(const Duration(milliseconds: 40)).listen(got.add);
      await pumpEventQueue();
      hub.onAccelerometer([0, 0, 9.8, 1000, 1, 2, 3, 1040]);
      expect(got, hasLength(2));
      expect(got[0].z, 9.8);
      expect(got[0].at, const Duration(milliseconds: 1000));
      expect([got[1].x, got[1].y, got[1].z], [1, 2, 3]);
      expect(got[1].at, const Duration(milliseconds: 1040));
      await sub.cancel();
    });

    test('a damaged batch is dropped whole, never half-read', () async {
      final hub = NativeEvents();
      final a = NativeAccelerometer(_Host(), hub);
      final got = <AccelSample>[];
      final sub = a.samples(const Duration(milliseconds: 40)).listen(got.add);
      await pumpEventQueue();
      hub.onAccelerometer([1, 2, 3]);
      hub.onAccelerometer([0, 0, double.nan, 1000]);
      hub.onAccelerometer([0, 0, double.infinity, 1000]);
      expect(got, isEmpty);
      await sub.cancel();
    });

    test('a phone without an accelerometer ends the stream, quietly', () async {
      final host = _Host()..hasAccel = false;
      final a = NativeAccelerometer(host, NativeEvents());
      expect(
        await a.samples(const Duration(milliseconds: 40)).toList(),
        isEmpty,
      );
    });

    test('a failing host ends the stream, quietly', () async {
      final a = NativeAccelerometer(_ThrowingHost(), NativeEvents());
      expect(
        await a.samples(const Duration(milliseconds: 40)).toList(),
        isEmpty,
      );
    });
  });

  group('NativeDialer', () {
    test('opens the dialer with the number', () async {
      final host = _Host();
      await NativeDialer(host).open('112');
      expect(host.dialed, ['112']);
    });

    test('a failing host never throws', () async {
      await NativeDialer(_ThrowingHost()).open('112');
    });
  });

  group('NativeAlarmScheduler', () {
    final system = FakeClock(DateTime.utc(2026, 10, 28, 9));
    final trusted = TrustedClock(
      system: system,
      gps: FakeGpsTimeSource(system),
    );

    test(
      'schedules by the phone clock, converting from trusted time',
      () async {
        final host = _Host();
        final a = NativeAlarmScheduler(host, NativeEvents(), trusted, system);
        final at = trusted.now().time.add(const Duration(seconds: 60));
        await a.schedule(2, at);
        expect(host.scheduled.single.$1, 2);
        expect(
          host.scheduled.single.$2,
          system.now().add(const Duration(seconds: 60)).millisecondsSinceEpoch,
        );
      },
    );

    test('cancel is forwarded', () async {
      final host = _Host();
      await NativeAlarmScheduler(
        host,
        NativeEvents(),
        trusted,
        system,
      ).cancel(2);
      expect(host.cancelledAlarms, [2]);
    });

    test('fired alarms from the hub come out of the stream', () async {
      final hub = NativeEvents();
      final a = NativeAlarmScheduler(_Host(), hub, trusted, system);
      final got = <int>[];
      a.fired.listen(got.add);
      hub.onAlarm(5);
      expect(got, [5]);
    });

    test(
      'alarms that fired while the core was down are replayed once',
      () async {
        final host = _Host()..fired = [3, 8];
        final a = NativeAlarmScheduler(host, NativeEvents(), trusted, system);
        final got = <int>[];
        a.fired.listen(got.add);
        await a.replayMissed();
        expect(got, [3, 8]);
        await a.replayMissed();
        expect(got, [3, 8], reason: 'taken once');
      },
    );

    test('a failing host is survived when replaying', () async {
      final a = NativeAlarmScheduler(
        _ThrowingHost(),
        NativeEvents(),
        trusted,
        system,
      );
      await a.replayMissed();
    });
  });

  group('beaconCapabilitiesFrom', () {
    test('maps coded PHY and extended advertising support', () async {
      final caps = await _Host().deviceCapabilities();
      final b = beaconCapabilitiesFrom(caps);
      expect(b.codedPhy, isTrue);
      expect(b.extendedAdvertising, isFalse);
    });
  });
}

class _ThrowingHost extends _Host {
  @override
  Future<void> setTorch(bool on, bool strobe) async => throw StateError('x');
  @override
  Future<void> setSiren(bool on) async => throw StateError('x');
  @override
  Future<void> openDialer(String number) async => throw StateError('x');
  @override
  Future<List<int>> takeFiredAlarms() async => throw StateError('x');
  @override
  Future<bool> startAccelerometer(int periodMs) async => throw StateError('x');
  @override
  Future<void> speak(String text, bool urgent) async => throw StateError('x');
  @override
  Future<void> stopSpeaking() async => throw StateError('x');
}
