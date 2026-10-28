import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:engine_navigation/engine_navigation.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_bridge/native_bridge.dart';
import 'package:pagdandi_app/core/assemble.dart';
import 'package:pagdandi_app/routes/route_library.dart';
import 'package:trek_core/trek_core.dart';

/// A fake of the Kotlin side: records what the core asks of Android.
class _Host extends PagdandiHostApi {
  final sms = <(String, String, String)>[];
  final haptics = <HapticRequest>[];
  final beats = <int>[];
  final locationRequests = <LocationRequestDto>[];
  SignalStateDto signal = SignalStateDto.inService;
  final roles = <String>[];
  final published = <String>[];
  bool smsGranted = true;

  @override
  Future<int> batteryLevel() async => 41;
  @override
  Future<DeviceCapabilities> deviceCapabilities() async => DeviceCapabilities(
    sdkInt: 34,
    leCodedPhySupported: false,
    leExtendedAdvertisingSupported: false,
    hasBarometer: false,
    hasSignificantMotion: false,
  );
  @override
  Future<void> playHaptic(HapticRequest r) async => haptics.add(r);
  @override
  Future<void> cancelHaptic() async {}
  @override
  Future<void> sendSms(String id, String to, String body) async =>
      sms.add((id, to, body));
  @override
  Future<SignalStateDto> signalState() async => signal;
  @override
  Future<void> startLocation(LocationRequestDto r) async =>
      locationRequests.add(r);
  @override
  Future<void> stopLocation() async {}
  @override
  Future<String> databasePath() async => ':memory:';
  @override
  Future<void> heartbeat(int atMs) async => beats.add(atMs);
  @override
  Future<void> startTrekService() async {}
  @override
  Future<void> stopTrekService() async {}
  @override
  Future<HealthSnapshotDto> healthSnapshot() async => HealthSnapshotDto(
    locationPermission: true,
    backgroundLocationPermission: true,
    smsPermission: smsGranted,
    notificationPermission: true,
    batteryOptimizationExempt: true,
    storageFreeMb: 5000,
  );
  @override
  Future<void> setRole(String role) async => roles.add(role);
  @override
  Future<void> sendCommand(String json) async {}
  @override
  Future<void> publishState(String json) async => published.add(json);
  final spoken = <String>[];
  @override
  Future<void> speak(String text, bool urgent) async => spoken.add(text);
  @override
  Future<void> stopSpeaking() async {}
  final accelStarts = <int>[];
  int accelStops = 0;
  @override
  Future<bool> startAccelerometer(int periodMs) async {
    accelStarts.add(periodMs);
    return true;
  }

  @override
  Future<void> stopAccelerometer() async => accelStops++;
  final scheduled = <(int, int)>[];
  final cancelledAlarms = <int>[];
  List<int> fired = [];
  @override
  Future<void> setTorch(bool on, bool strobe) async {}
  @override
  Future<void> setSiren(bool on) async {}
  @override
  Future<void> openDialer(String number) async {}
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

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late _Host host;
  late NativeEvents events;
  late TrekCore core;

  setUp(() async {
    host = _Host();
    events = NativeEvents();
    core = await assembleTrekCore(
      host: host,
      events: events,
      openDatabase: (path) => NativeDatabase.memory(),
      logger: _Log(),
      contacts: const ['+91A', '+91B'],
      memberName: 'Akash',
    );
    await core.start();
  });
  tearDown(() => core.dispose());

  CoreStateMessage lastPublished() =>
      CoreStateMessage.decode(host.published.last)!;

  test('the core registers as the core only after its bridge listens', () {
    expect(host.roles, ['core']);
    expect(
      host.published,
      isNotEmpty,
      reason: 'state published before registering',
    );
  });

  test(
    'a command from the UI, through the native channel, changes the state',
    () async {
      events.onCommand(encodeCommand(const StartTrek()));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(core.runtime.state.activity, Activity.stationary);
      expect(lastPublished().state.activity, Activity.stationary);
    },
  );

  test(
    'an SOS pressed in the UI is sent and its progress comes back',
    () async {
      events.onCommand(encodeCommand(const SosPressed()));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(host.sms, hasLength(2));
      expect(lastPublished().sos.active, isTrue);
      expect(lastPublished().sos.total, 2);
    },
  );

  test(
    'a missing SMS permission shows up as a critical issue for the UI',
    () async {
      host.smsGranted = false;
      await core.refreshHealth();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final issues = lastPublished().issues;
      expect(issues.first.severity, 'critical');
      expect(issues.first.message, contains('sms'));
    },
  );

  test('starting the core beats the heart straight away', () {
    expect(host.beats, isNotEmpty);
  });

  test(
    'an SOS goes out through the native SMS adapter to every contact',
    () async {
      await core.runtime.dispatch(const SosPressed());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(host.sms.map((m) => m.$2), ['+91A', '+91B']);
      expect(host.sms.first.$3, contains('SOS Akash'));
      expect(host.sms.first.$3, contains('battery 41%'));
    },
  );

  test('the SOS is written to the shared database before it is sent', () async {
    await core.runtime.dispatch(const SosPressed());
    final rows = await core.outbox.all();
    expect(rows, hasLength(2));
    expect(rows.every((r) => r.attempts == 1), isTrue);
  });

  test('delivery reports from Android update the outbox', () async {
    await core.runtime.dispatch(const SosPressed());
    final id = host.sms.first.$1;
    events.onSmsReport(id, SmsStatusDto.delivered);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final row = (await core.outbox.all()).firstWhere((r) => r.id == id);
    expect(row.status, SmsStatus.delivered);
  });

  test(
    'starting a trek asks Android for location with the tracking request',
    () async {
      await core.runtime.dispatch(const StartTrek());
      expect(host.locationRequests.single.intervalMs, 5000);
    },
  );

  test(
    'GPS time from native fixes becomes the trusted time of the SOS',
    () async {
      await core.runtime.dispatch(const StartTrek());
      events.onLocations([
        LocationFixDto(
          latitude: 27.041,
          longitude: 88.2663,
          accuracyM: 6,
          timeMs: DateTime.utc(2026, 10, 27, 14, 32).millisecondsSinceEpoch,
        ),
      ]);
      await core.runtime.dispatch(const SosPressed());
      expect(host.sms.first.$3, contains('2026-10-27 14:32 UTC'));
      expect(host.sms.first.$3, contains('27.0410, 88.2663'));
    },
  );

  test(
    'a failing beacon (not built yet) is a warning, never a stopped SOS',
    () async {
      final warnings = <String>[];
      core.runtime.warnings.listen((w) => warnings.add(w.source));
      await core.runtime.dispatch(const SosPressed());
      expect(warnings, contains('BeaconOn'));
      expect(host.sms, isNotEmpty);
      expect(host.haptics, isNotEmpty);
    },
  );

  test(
    'the state survives: a snapshot is stored in the shared database',
    () async {
      await core.runtime.dispatch(const StartTrek());
      expect(await core.snapshots.latest(), isNotNull);
      expect(
        decodeSnapshot((await core.snapshots.latest())!)!.activity,
        Activity.stationary,
      );
    },
  );

  group('pins', () {
    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 60));

    test('a pin saves where you are and says so', () async {
      events.onCommand(encodeCommand(const StartTrek()));
      await settle();
      events.onLocations([
        LocationFixDto(
          latitude: 30.15,
          longitude: 79.58,
          accuracyM: 6,
          timeMs: DateTime.utc(2026, 12, 14, 9).millisecondsSinceEpoch,
        ),
      ]);
      await settle();
      events.onCommand(encodeDropPin());
      await settle();
      final p = (await core.pins.all()).single;
      expect([p.lat, p.lon, p.label], [30.15, 79.58, 'Pin 1']);
      expect(host.spoken, contains('Pin 1 dropped.'));
      expect(lastPublished().pinCount, 1);
    });

    test('with no position yet nothing is saved and it says so', () async {
      events.onCommand(encodeCommand(const StartTrek()));
      await settle();
      events.onCommand(encodeDropPin());
      await settle();
      expect(await core.pins.all(), isEmpty);
      expect(
        host.spoken,
        contains('No position yet. Try again when GPS is back.'),
      );
      expect(lastPublished().pinCount, 0);
    });

    test('pins are numbered one after another', () async {
      events.onCommand(encodeCommand(const StartTrek()));
      await settle();
      for (var i = 0; i < 2; i++) {
        events.onLocations([
          LocationFixDto(
            latitude: 30.15 + i * 0.001,
            longitude: 79.58,
            accuracyM: 6,
            timeMs: DateTime.utc(2026, 12, 14, 9, i).millisecondsSinceEpoch,
          ),
        ]);
        await settle();
        events.onCommand(encodeDropPin());
        await settle();
      }
      expect((await core.pins.all()).map((p) => p.label), ['Pin 2', 'Pin 1']);
      expect(lastPublished().pinCount, 2);
    });
  });

  group('voice in the assembled core', () {
    test('an SOS says it is active, and delivery only when true', () async {
      events.onCommand(encodeCommand(const SosPressed()));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(
        host.spoken,
        contains('S.O.S. active. Your position will be sent at first signal.'),
      );
      expect(host.spoken.where((t) => t.contains('delivered')), isEmpty);
      final id = host.sms.first.$1;
      events.onSmsReport(id, SmsStatusDto.delivered);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(host.spoken.where((t) => t.contains('delivered')), hasLength(1));
    });

    test('a fall countdown asks if you fell', () async {
      await core.runtime.dispatch(const FallSuspected());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(
        host.spoken,
        contains(
          'Did you fall? Sending S.O.S. in 60 seconds. Tap I’m OK to cancel.',
        ),
      );
    });
  });

  group('fall detection in the assembled core', () {
    /// Flat [x, y, z, timeMs]: weightlessness, an impact, then stillness.
    List<double> fallBatch() {
      final out = <double>[];
      var t = 1000.0;
      void add(double z) {
        out.addAll([0, 0, z, t]);
        t += 40;
      }

      for (var i = 0; i < 5; i++) {
        add(1);
      }
      add(40);
      for (var i = 0; i < 25 * 33; i++) {
        add(9.8);
      }
      return out;
    }

    test('the sensor runs only while a trek is on', () async {
      expect(host.accelStarts, isEmpty);
      events.onCommand(encodeCommand(const StartTrek()));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(host.accelStarts, [40]);
      events.onCommand(encodeCommand(const EndTrek()));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(host.accelStops, greaterThanOrEqualTo(1));
    });

    test('a fall and stillness from the sensor start the countdown', () async {
      events.onCommand(encodeCommand(const StartTrek()));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      events.onAccelerometer(fallBatch());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(core.runtime.state.emergency, isA<FallCountdown>());
      expect(host.scheduled.map((a) => a.$1), contains(AlarmIds.fall));
    });

    test('walking-like data does not', () async {
      events.onCommand(encodeCommand(const StartTrek()));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final out = <double>[];
      for (var i = 0; i < 25 * 60; i++) {
        out.addAll([0, 0, 9.8 + (i.isEven ? 6 : -6), 1000.0 + i * 40]);
      }
      events.onAccelerometer(out);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(core.runtime.state.emergency, isA<NoEmergency>());
    });

    test('with no trek running, sensor data is ignored', () async {
      events.onAccelerometer(fallBatch());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(core.runtime.state.emergency, isA<NoEmergency>());
    });
  });

  group('route guidance in the assembled core', () {
    Route northRoute() => Route(
      id: 'north',
      name: 'North trail',
      points: [for (var i = 0; i <= 100; i++) RoutePoint(30 + i * 0.00009, 79)],
      waypoints: const [Waypoint('Lake', 30.0045, 79)],
      attribution: 'test',
    );

    Future<(_Host, NativeEvents, TrekCore)> boot(RouteLibrary lib) async {
      final h = _Host();
      final e = NativeEvents();
      final c = await assembleTrekCore(
        host: h,
        events: e,
        openDatabase: (path) => NativeDatabase.memory(),
        logger: _Log(),
        contacts: const ['+91A'],
        memberName: 'A',
        routes: lib,
      );
      await c.start();
      return (h, e, c);
    }

    void fixAt(NativeEvents e, double lat, double lon, int sec) =>
        e.onLocations([
          LocationFixDto(
            latitude: lat,
            longitude: lon,
            accuracyM: 6,
            timeMs: DateTime.utc(
              2026,
              12,
              14,
              6,
            ).add(Duration(seconds: sec)).millisecondsSinceEpoch,
          ),
        ]);

    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 40));

    test('a chosen route is followed and published', () async {
      final (h, e, c) = await boot(_OneRoute(northRoute()));
      await c.settings.set('active_route', 'north');
      e.onCommand(encodeCommand(const StartTrek()));
      await settle();
      fixAt(e, 30.002, 79, 0);
      await settle();
      final nav = CoreStateMessage.decode(h.published.last)!.nav!;
      expect(nav.routeId, 'north');
      expect(nav.status, NavStatus.onRoute);
      expect(nav.progressM, closeTo(222, 8));
      expect(nav.nextName, 'Lake');
      await c.dispose();
    });

    test('no chosen route is a free trek with no guidance', () async {
      final (h, e, c) = await boot(_OneRoute(northRoute()));
      e.onCommand(encodeCommand(const StartTrek()));
      await settle();
      fixAt(e, 30.002, 79, 0);
      await settle();
      expect(CoreStateMessage.decode(h.published.last)!.nav, isNull);
      await c.dispose();
    });

    test('a route that cannot be loaded falls back to a free trek', () async {
      final (h, e, c) = await boot(_BrokenLibrary());
      await c.settings.set('active_route', 'north');
      e.onCommand(encodeCommand(const StartTrek()));
      await settle();
      fixAt(e, 30.002, 79, 0);
      await settle();
      final m = CoreStateMessage.decode(h.published.last)!;
      expect(m.nav, isNull);
      expect(m.state.activity, isNot(Activity.idle), reason: 'trek still runs');
      await c.dispose();
    });

    test('walking away from the trail buzzes the off-route pattern', () async {
      final (h, e, c) = await boot(_OneRoute(northRoute()));
      await c.settings.set('active_route', 'north');
      e.onCommand(encodeCommand(const StartTrek()));
      await settle();
      for (var i = 0; i < 4; i++) {
        fixAt(e, 30.002 + i * 0.0002, 79.001, i * 20);
        await settle();
      }
      final nav = CoreStateMessage.decode(h.published.last)!.nav!;
      expect(nav.status, NavStatus.offRoute);
      expect(h.haptics.any((r) => r.repeat), isTrue);
      expect(h.spoken.any((t) => t.startsWith('Warning. You are')), isTrue);
      await c.dispose();
    });

    test('ending the trek ends the guidance', () async {
      final (h, e, c) = await boot(_OneRoute(northRoute()));
      await c.settings.set('active_route', 'north');
      e.onCommand(encodeCommand(const StartTrek()));
      await settle();
      fixAt(e, 30.002, 79, 0);
      await settle();
      e.onCommand(encodeCommand(const EndTrek()));
      await settle();
      expect(CoreStateMessage.decode(h.published.last)!.nav, isNull);
      await c.dispose();
    });
  });

  group('the fall countdown uses native exact alarms', () {
    test(
      'a suspected fall schedules an alarm with the phone, not a timer',
      () async {
        await core.runtime.dispatch(const FallSuspected());
        expect(host.scheduled.map((a) => a.$1), [AlarmIds.fall]);
        final inMs =
            host.scheduled.single.$2 - DateTime.now().millisecondsSinceEpoch;
        expect(inMs, inInclusiveRange(55000, 65000));
      },
    );

    test('cancelling the fall cancels the native alarm', () async {
      await core.runtime.dispatch(const FallSuspected());
      await core.runtime.dispatch(const FallCancelled());
      expect(host.cancelledAlarms, contains(AlarmIds.fall));
    });

    test('the alarm firing in the phone starts the SOS', () async {
      await core.runtime.dispatch(const FallSuspected());
      events.onAlarm(AlarmIds.fall);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(core.runtime.state.emergency, isA<SosActive>());
      expect(host.sms, isNotEmpty);
    });

    test('an alarm that fired while the core was down is not lost', () async {
      await core.runtime.dispatch(const FallSuspected());
      host.fired = [AlarmIds.fall];
      await core.refreshHealth();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(core.runtime.state.emergency, isA<SosActive>());
    });

    test(
      'alarms missed before the core started are collected at start',
      () async {
        final h = _Host()..fired = [AlarmIds.fall];
        final e = NativeEvents();
        final c = await assembleTrekCore(
          host: h,
          events: e,
          openDatabase: (path) => NativeDatabase.memory(),
          logger: _Log(),
          contacts: const ['+91A'],
          memberName: 'A',
        );
        await c.start();
        expect(h.fired, isEmpty, reason: 'taken at start');
        await c.dispose();
      },
    );
  });

  group('settings saved by Setup reach the running core', () {
    late _Host h2;
    late NativeEvents e2;
    late TrekCore c2;

    setUp(() async {
      h2 = _Host();
      e2 = NativeEvents();
      c2 = await assembleTrekCore(
        host: h2,
        events: e2,
        openDatabase: (path) => NativeDatabase.memory(),
        logger: _Log(),
      );
      await c2.start();
    });
    tearDown(() => c2.dispose());

    test('contacts added after start are used by the next SOS', () async {
      await c2.settings.set('emergency_contacts', '+91X,+91Y,+91Z');
      await c2.refreshHealth();
      e2.onCommand(encodeCommand(const SosPressed()));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(h2.sms.map((m) => m.$2).toSet(), {'+91X', '+91Y', '+91Z'});
    });

    test(
      'a contact saved just before the SOS is used, no health read needed',
      () async {
        await c2.settings.set('emergency_contacts', '+91Q');
        e2.onCommand(encodeCommand(const SosPressed()));
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(h2.sms.map((m) => m.$2).toSet(), {'+91Q'});
      },
    );

    test(
      'with no contacts at all the SOS still runs, with nobody to tell',
      () async {
        e2.onCommand(encodeCommand(const SosPressed()));
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(c2.runtime.state.emergency, isA<SosActive>());
        expect(h2.sms, isEmpty);
      },
    );
  });
}

class _OneRoute implements RouteLibrary {
  _OneRoute(this.route);
  final Route route;
  @override
  List<RouteInfo> get available => [RouteInfo(route.id, route.name, 'x')];
  @override
  Future<Route?> load(String id) async => id == route.id ? route : null;
}

class _BrokenLibrary implements RouteLibrary {
  @override
  List<RouteInfo> get available => const [];
  @override
  Future<Route?> load(String id) async => throw const FormatException('bad');
}
