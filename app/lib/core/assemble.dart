import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_db/core_db.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:drift/drift.dart';
import 'package:engine_health/engine_health.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:native_bridge/native_bridge.dart';
import 'package:pagdandi_app/routes/route_library.dart';
import 'package:trek_core/trek_core.dart';

/// The running core: the runtime plus what the app needs to reach it.
class TrekCore {
  TrekCore._({
    required this.runtime,
    required this.outbox,
    required this.snapshots,
    required this.settings,
    required this._db,
    required this._heartbeat,
    required this._loadSettings,
    required this._bridge,
    required this._channel,
    required this._poller,
    required this._readHealthNow,
    required this._replayAlarms,
    required this._navigation,
    required this._falls,
    required this._emergencyVoice,
    required this.pins,
  });

  /// The trek runtime: dispatch events, watch state.
  final TrekRuntime runtime;

  /// The SMS outbox (shared with the native guard).
  final SmsOutboxStore outbox;

  /// Pins dropped by the walker.
  final PinRepository pins;

  /// Persisted state snapshots.
  final SnapshotStore snapshots;

  /// Key-value settings.
  final SettingsRepository settings;

  final PagdandiDatabase _db;
  final HeartbeatLoop _heartbeat;
  final Future<void> Function() _loadSettings;
  final CoreBridge _bridge;
  final NativeCoreChannel _channel;
  final HealthPoller _poller;
  final Future<void> Function() _readHealthNow;
  final Future<void> Function() _replayAlarms;
  final NavigationController _navigation;
  final FallWatcher _falls;
  final EmergencyVoice _emergencyVoice;

  /// Restores state, starts the heartbeat and resumes whatever was running.
  Future<void> start() async {
    _heartbeat.start();
    await _loadSettings();
    await runtime.start();
    // The runtime now listens for the fall alarm: collect any that fired
    // while this process was not running.
    await _replayAlarms();
    await _bridge.start();
    // Register as the core only now that the bridge listens, so commands the
    // relay queued while we were starting are delivered, not lost.
    await _channel.register();
    _poller.start();
  }

  /// Reads the device health now (also done every 30 s).
  Future<void> refreshHealth() => _readHealthNow();

  /// Stops everything. Stored data is untouched.
  Future<void> dispose() async {
    _heartbeat.stop();
    _poller.stop();
    _navigation.dispose();
    _falls.stop();
    _emergencyVoice.dispose();
    _bridge.dispose();
    runtime.dispose();
    await _db.close();
  }
}

/// Builds the whole headless core from the native adapters and the shared
/// database. [contacts] and [memberName], when null, are read from settings
/// (set during Setup).
Future<TrekCore> assembleTrekCore({
  required PagdandiHostApi host,
  required NativeEvents events,
  required QueryExecutor Function(String path) openDatabase,
  required Logger logger,
  List<String>? contacts,
  String? memberName,
  RouteLibrary routes = const AssetRouteLibrary(),
}) async {
  final system = SystemClock();
  final gps = GpsTimeTracker(system);
  events.locations.listen(gps.observe);
  final trusted = TrustedClock(system: system, gps: gps);

  final db = PagdandiDatabase(openDatabase(await host.databasePath()));
  final outbox = DriftSmsOutboxStore(db);
  final snapshots = DriftSnapshotStore(db);
  final tracks = TrackRepository(db);
  final settings = SettingsRepository(db);

  var pinsThisTrek = 0;
  var contactList = contacts ?? const <String>[];
  var name = memberName ?? 'Unknown';
  NavigationController? navigation;
  String? loadedRoute;
  var loadedReversed = false;
  // Follows the route chosen at Basecamp. A route that cannot be read means a
  // free trek, never a stopped one.
  Future<void> syncRoute() async {
    final nav = navigation;
    if (nav == null) return;
    final id = await settings.get('active_route') ?? '';
    final reversed = await settings.get('route_reversed') == 'true';
    if (id == loadedRoute && reversed == loadedReversed) return;
    loadedRoute = id;
    loadedReversed = reversed;
    try {
      final route = id.isEmpty ? null : await routes.load(id);
      nav.setRoute(route, reversed: reversed);
    } on Object catch (e) {
      logger.warn('nav', 'route $id could not be loaded, free trek', error: e);
      nav.setRoute(null);
    }
  }

  Future<void> loadSettings() async {
    await syncRoute();
    if (contacts == null) {
      final raw = await settings.get('emergency_contacts');
      if (raw != null && raw.isNotEmpty) contactList = raw.split(',');
    }
    if (memberName == null) name = await settings.get('member_name') ?? name;
  }

  final signal = await NativeSignalMonitor.create(host, events);
  final battery = await NativeBatteryMonitor.create(host, events);
  final sos = SosKernel(
    sms: NativeSmsGateway(host, events),
    signal: signal,
    store: outbox,
    clock: trusted,
    logger: logger,
  );
  final tracking = TrackingPipeline(
    location: NativeLocationSource(host, events),
    logger: logger,
    sink: (batch) async {
      final trip = await tracks.openTrip();
      final id =
          trip?.id ??
          await tracks.startTrip(name: 'Trek', at: trusted.now().time);
      await tracks.addPoints(id, batch);
    },
  );
  final alarms = NativeAlarmScheduler(host, events, trusted, system);
  final runtime = TrekRuntime(
    clock: trusted,
    snapshots: snapshots,
    sos: sos,
    haptics: NativeHapticOutput(host),
    beacon: UnavailableBeaconTransport(),
    alarms: alarms,
    tracking: tracking,
    battery: battery,
    logger: logger,
    memberName: name,
    contacts: () => contactList,
  );

  final voice = NativeVoiceOutput(host);
  final emergencyVoice = EmergencyVoice(
    states: runtime.states,
    sos: runtime.sosSummary,
    voice: voice,
    logger: logger,
  );

  // Falls are watched only while a trek is on (battery).
  final falls = FallWatcher(
    accelerometer: NativeAccelerometer(host, events),
    onFall: () => runtime.dispatch(const FallSuspected()),
    logger: logger,
  );

  navigation = NavigationController(
    fixes: tracking.accepted,
    haptics: NativeHapticOutput(host),
    voice: voice,
    clock: () => trusted.now().time,
    logger: logger,
    emergencyActive: () => runtime.state.emergency is! NoEmergency,
  );

  final health = HealthMonitor(const HealthWatchdog());
  DateTime? trekStartedAt;
  runtime.states.listen((st) {
    if (st.activity.name != 'idle') {
      falls.start();
      trekStartedAt ??= trusted.now().time;
    } else {
      trekStartedAt = null;
      pinsThisTrek = 0;
      falls.stop();
      // The trek is over: guidance ends, and the next trek picks its route
      // afresh.
      navigation?.setRoute(null);
      loadedRoute = null;
    }
  });
  Future<HealthInputs> readHealth() async {
    // Setup may have changed contacts or the name since the last read.
    await loadSettings();
    await alarms.replayMissed();
    final h = await host.healthSnapshot();
    final crumb = tracking.breadcrumb;
    return HealthInputs(
      now: trusted.now().time,
      trekActive: runtime.state.activity.name != 'idle',
      trekStartedAt: trekStartedAt,
      lastFixAt: crumb.isEmpty ? null : crumb.last.gpsTime,
      locationPermission: h.locationPermission,
      backgroundLocationPermission: h.backgroundLocationPermission,
      smsPermission: h.smsPermission,
      batteryOptimizationExempt: h.batteryOptimizationExempt,
      storageFreeMb: h.storageFreeMb,
      batteryPercent: battery.level,
    );
  }

  final channel = NativeCoreChannel(host, events);
  final pinRepo = PinRepository(db);
  CoreBridge? bridgeRef;
  Future<void> dropPin() async {
    final crumb = tracking.breadcrumb;
    if (crumb.isEmpty) {
      await voice.speak('No position yet. Try again when GPS is back.');
      return;
    }
    final fix = crumb.last;
    final n = pinsThisTrek + 1;
    await pinRepo.add(
      at: trusted.now().time,
      lat: fix.latitude,
      lon: fix.longitude,
      accuracyM: fix.accuracyM,
      label: 'Pin $n',
    );
    pinsThisTrek = n;
    unawaited(NativeHapticOutput(host).play(HapticPattern.checkpoint));
    await voice.speak('Pin $n dropped.');
    bridgeRef?.refresh();
  }

  final bridge = CoreBridge(
    runtime: runtime,
    channel: channel,
    tracking: tracking,
    health: health,
    battery: battery,
    clock: trusted,
    logger: logger,
    beforeCommand: loadSettings,
    navigation: navigation,
    onDropPin: dropPin,
    pinCount: () => pinsThisTrek,
  );
  bridgeRef = bridge;
  final poller = HealthPoller(
    read: readHealth,
    onInputs: bridge.updateHealth,
    logger: logger,
  );

  return TrekCore._(
    runtime: runtime,
    outbox: outbox,
    snapshots: snapshots,
    settings: settings,
    db: db,
    heartbeat: HeartbeatLoop(
      sink: NativeHeartbeatSink(host),
      clock: system,
      logger: logger,
    ),
    loadSettings: loadSettings,
    bridge: bridge,
    channel: channel,
    poller: poller,
    readHealthNow: () async => bridge.updateHealth(await readHealth()),
    replayAlarms: alarms.replayMissed,
    navigation: navigation,
    falls: falls,
    emergencyVoice: emergencyVoice,
    pins: pinRepo,
  );
}
