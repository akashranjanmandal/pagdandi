import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_health/engine_health.dart';
import 'package:engine_navigation/engine_navigation.dart';
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

class _FlakyChannel implements CoreChannel {
  _FlakyChannel(this.inner);
  final CoreChannel inner;
  int failuresLeft = 0;
  @override
  Stream<String> get commands => inner.commands;
  @override
  Future<void> publish(String json) async {
    if (failuresLeft > 0) {
      failuresLeft--;
      throw StateError('relay down');
    }
    await inner.publish(json);
  }
}

class _Rig {
  _Rig() {
    gps.receive(clock.now());
    signal.set(SignalState.inService);
    final sos = SosKernel(
      sms: sms,
      signal: signal,
      store: outbox,
      clock: trusted,
      logger: log,
    );
    tracking = TrackingPipeline(
      location: location,
      sink: (b) async {},
      logger: log,
    );
    runtime = TrekRuntime(
      clock: trusted,
      snapshots: FakeSnapshotStore(),
      sos: sos,
      haptics: FakeHapticOutput(),
      beacon: FakeBeaconTransport(),
      alarms: FakeAlarmScheduler(clock),
      tracking: tracking,
      battery: battery,
      logger: log,
      memberName: 'Akash',
      contacts: () => liveContacts,
    );
    channel = _FlakyChannel(bridge.core);
    health = HealthMonitor(const HealthWatchdog());
    coreBridge = CoreBridge(
      runtime: runtime,
      channel: channel,
      tracking: tracking,
      health: health,
      battery: battery,
      clock: trusted,
      logger: log,
      beforeCommand: () async {
        hookCalls++;
        if (hookFails) throw StateError('settings unreadable');
        if (swapContacts) liveContacts = const ['+91NEW'];
      },
    );
  }

  final clock = FakeClock(DateTime.utc(2026, 10, 27, 14));
  late final gps = FakeGpsTimeSource(clock);
  late final trusted = TrustedClock(system: clock, gps: gps);
  List<String> liveContacts = const <String>['+91A', '+91B'];
  int hookCalls = 0;
  bool hookFails = false;
  bool swapContacts = false;
  final log = _Log();
  final bridge = FakeBridge();
  final sms = FakeSmsGateway();
  final signal = FakeSignalMonitor();
  final outbox = FakeSmsOutboxStore();
  final battery = FakeBatteryMonitor(level: 41);
  final location = FakeLocationSource();
  late final TrackingPipeline tracking;
  late final TrekRuntime runtime;
  late final _FlakyChannel channel;
  late final HealthMonitor health;
  late final CoreBridge coreBridge;

  List<CoreStateMessage> get published =>
      bridge.publishedStates.map((s) => CoreStateMessage.decode(s)!).toList();

  Future<void> settle() => pumpEventQueue();
}

void main() {
  late _Rig r;
  setUp(() async {
    r = _Rig();
    await r.runtime.start();
    await r.coreBridge.start();
    await r.settle();
  });
  tearDown(() => r.coreBridge.dispose());

  test('publishes the current state as soon as it starts', () {
    final m = r.published.first;
    expect(m.state, TrekState.idle);
    expect(m.battery, 41);
    expect(m.sos.active, isFalse);
  });

  test(
    'a command from the UI is applied and the new state published',
    () async {
      await r.bridge.ui.send(encodeCommand(const StartTrek()));
      await r.settle();
      expect(r.runtime.state.activity, Activity.stationary);
      expect(r.published.last.state.activity, Activity.stationary);
    },
  );

  test('an SOS from the UI goes out and its progress reaches the UI', () async {
    await r.bridge.ui.send(encodeCommand(const SosPressed()));
    await r.settle();
    expect(r.sms.sent, hasLength(2));
    var m = r.published.last;
    expect(m.state.emergency, const SosActive());
    expect(m.sos.active, isTrue);
    expect(m.sos.total, 2);
    expect(m.sos.delivered, 0);
    r.sms.report((await r.outbox.all()).first.id, SmsStatus.delivered);
    await r.settle();
    m = r.published.last;
    expect(m.sos.delivered, 1);
  });

  test('the latest settings are read before an SOS goes out', () async {
    r.swapContacts = true;
    await r.bridge.ui.send(encodeCommand(const SosPressed()));
    await r.settle();
    expect(r.hookCalls, 1);
    expect(r.sms.sent.map((m) => m.to).toSet(), {'+91NEW'});
  });

  test('settings are also read before a trek starts', () async {
    await r.bridge.ui.send(encodeCommand(const StartTrek()));
    await r.settle();
    expect(r.hookCalls, 1);
  });

  test('other commands do not touch settings', () async {
    await r.bridge.ui.send(encodeCommand(const MapOpened()));
    await r.settle();
    expect(r.hookCalls, 0);
  });

  test('if settings cannot be read the SOS still goes out', () async {
    r.hookFails = true;
    await r.bridge.ui.send(encodeCommand(const SosPressed()));
    await r.settle();
    expect(r.sms.sent.map((m) => m.to).toSet(), {'+91A', '+91B'});
  });

  test('route guidance is published with the state', () async {
    final src = StreamController<LocationFix>.broadcast(sync: true);
    final nav = NavigationController(
      fixes: src.stream,
      haptics: FakeHapticOutput(),
      clock: r.clock.now,
      logger: r.log,
      emergencyActive: () => false,
    );
    final pts = <RoutePoint>[];
    for (var i = 0; i <= 50; i++) {
      pts.add(RoutePoint(30 + i * 0.0001, 79));
    }
    nav.setRoute(
      Route(id: 'r', name: 'R', points: pts, attribution: 'a'),
    );
    final bridge = CoreBridge(
      runtime: r.runtime,
      channel: r.channel,
      tracking: r.tracking,
      health: r.health,
      battery: r.battery,
      clock: r.trusted,
      logger: r.log,
      navigation: nav,
    );
    await bridge.start();
    src.add(
      LocationFix(
        latitude: 30.002,
        longitude: 79,
        accuracyM: 5,
        gpsTime: r.clock.now(),
      ),
    );
    await r.settle();
    expect(r.published.last.nav?.routeId, 'r');
    expect(r.published.last.nav?.status, NavStatus.onRoute);
    bridge.dispose();
    nav.dispose();
  });

  test('the reverse-route command turns the guidance around', () async {
    final src = StreamController<LocationFix>.broadcast(sync: true);
    final nav = NavigationController(
      fixes: src.stream,
      haptics: FakeHapticOutput(),
      clock: r.clock.now,
      logger: r.log,
      emergencyActive: () => false,
    );
    final pts = [for (var i = 0; i <= 50; i++) RoutePoint(30 + i * 0.0001, 79)];
    nav.setRoute(Route(id: 'r', name: 'R', points: pts, attribution: 'a'));
    final bridge = CoreBridge(
      runtime: r.runtime,
      channel: r.channel,
      tracking: r.tracking,
      health: r.health,
      battery: r.battery,
      clock: r.trusted,
      logger: r.log,
      navigation: nav,
    );
    await bridge.start();
    await r.bridge.ui.send(encodeReverseRoute());
    await r.settle();
    src.add(
      LocationFix(
        latitude: 30.004,
        longitude: 79,
        accuracyM: 5,
        gpsTime: r.clock.now(),
      ),
    );
    await r.settle();
    expect(r.published.last.nav?.reversed, isTrue);
    bridge.dispose();
    nav.dispose();
  });

  test(
    'a pin command calls the pin handler and the count is published',
    () async {
      var drops = 0;
      final bridge = CoreBridge(
        runtime: r.runtime,
        channel: r.channel,
        tracking: r.tracking,
        health: r.health,
        battery: r.battery,
        clock: r.trusted,
        logger: r.log,
        onDropPin: () async => drops++,
        pinCount: () => drops,
      );
      await bridge.start();
      await r.bridge.ui.send(encodeDropPin());
      await r.settle();
      expect(drops, 1);
      bridge.refresh();
      await r.settle();
      expect(r.published.last.pinCount, 1);
      bridge.dispose();
    },
  );

  test('a failing pin handler is logged and changes nothing else', () async {
    final bridge = CoreBridge(
      runtime: r.runtime,
      channel: r.channel,
      tracking: r.tracking,
      health: r.health,
      battery: r.battery,
      clock: r.trusted,
      logger: r.log,
      onDropPin: () async => throw StateError('disk full'),
    );
    await bridge.start();
    await r.bridge.ui.send(encodeDropPin());
    await r.settle();
    bridge.dispose();
  });

  test('forged or garbage commands change nothing and are logged', () async {
    await r.bridge.ui.send('{"c":"fallSuspected"}');
    await r.bridge.ui.send('not json');
    await r.settle();
    expect(r.runtime.state, TrekState.idle);
    expect(r.log.lines.where((l) => l.startsWith('warn')), hasLength(2));
  });

  test('accepted fixes update the stats and position for the UI', () async {
    await r.bridge.ui.send(encodeCommand(const StartTrek()));
    await r.settle();
    r.location
      ..emit(
        LocationFix(
          latitude: 27,
          longitude: 88,
          accuracyM: 5,
          gpsTime: DateTime.utc(2026, 10, 27, 14),
          altitudeM: 3000,
        ),
      )
      ..emit(
        LocationFix(
          latitude: 27.001,
          longitude: 88,
          accuracyM: 5,
          gpsTime: DateTime.utc(2026, 10, 27, 14, 1),
          altitudeM: 3020,
        ),
      );
    await r.settle();
    final m = r.published.last;
    expect(m.fix!.latitude, 27.001);
    expect(m.stats.distanceM, closeTo(111, 2));
    expect(m.stats.climbM, 20);
    expect(m.stats.elapsed, const Duration(minutes: 1));
  });

  test('battery changes are published', () async {
    r.battery.set(12);
    await r.settle();
    expect(r.published.last.battery, 12);
  });

  test('health issues are published when they change', () async {
    r.coreBridge.updateHealth(
      HealthInputs(
        now: r.clock.now(),
        trekActive: false,
        trekStartedAt: null,
        lastFixAt: null,
        locationPermission: true,
        backgroundLocationPermission: true,
        smsPermission: false,
        batteryOptimizationExempt: true,
        storageFreeMb: 5000,
        batteryPercent: 80,
      ),
    );
    await r.settle();
    expect(r.published.last.issues.single.severity, 'critical');
    expect(r.published.last.issues.single.message, contains('sms'));
  });

  test('a burst of changes in one tick is published once', () async {
    final before = r.bridge.publishedStates.length;
    r.battery
      ..set(40)
      ..set(39)
      ..set(38);
    await r.settle();
    expect(r.bridge.publishedStates.length, before + 1);
    expect(r.published.last.battery, 38);
  });

  test(
    'a failing channel is logged and the next change still gets through',
    () async {
      r.channel.failuresLeft = 1;
      r.battery.set(30);
      await r.settle();
      expect(
        r.log.lines.any((l) => l.startsWith('warn') && l.contains('publish')),
        isTrue,
      );
      r.battery.set(29);
      await r.settle();
      expect(r.published.last.battery, 29);
    },
  );

  test('a UI that connects late gets the latest state at once', () async {
    r.battery.set(77);
    await r.settle();
    final got = <String>[];
    r.bridge.ui.states.listen(got.add);
    await r.settle();
    expect(CoreStateMessage.decode(got.single)!.battery, 77);
  });

  test('after dispose nothing more is published', () async {
    r.coreBridge.dispose();
    final n = r.bridge.publishedStates.length;
    r.battery.set(10);
    await r.settle();
    expect(r.bridge.publishedStates.length, n);
  });
}
