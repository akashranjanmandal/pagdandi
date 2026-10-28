import 'dart:async';
import 'dart:typed_data';

import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';

StreamController<T> _sync<T>() => StreamController<T>.broadcast(sync: true);

/// Fake vibration motor that logs what was played.
class FakeHapticOutput implements HapticOutput {
  /// Every pattern played, oldest first.
  final played = <HapticPattern>[];

  /// The repeating pattern currently running, if any.
  HapticPattern? repeating;

  @override
  Future<void> play(HapticPattern pattern) async {
    played.add(pattern);
    repeating = pattern.repeats ? pattern : null;
  }

  @override
  Future<void> cancel() async => repeating = null;
}

/// Fake torch.
class FakeTorchOutput implements TorchOutput {
  /// Steady light state.
  bool isOn = false;

  /// Strobe state.
  bool strobing = false;

  @override
  Future<void> setOn({required bool on}) async => isOn = on;

  @override
  Future<void> setStrobe({required bool on}) async => strobing = on;
}

/// Fake siren.
class FakeSirenOutput implements SirenOutput {
  /// Whether the siren is sounding.
  bool isOn = false;

  @override
  Future<void> setOn({required bool on}) async => isOn = on;
}

/// Fake voice: records what was said.
class FakeVoiceOutput implements VoiceOutput {
  /// Everything said, oldest first.
  final said = <String>[];

  /// Which lines were urgent.
  final urgent = <String>[];

  /// Number of times it was stopped.
  int stops = 0;

  @override
  Future<void> speak(String text, {bool urgent = false}) async {
    said.add(text);
    if (urgent) this.urgent.add(text);
  }

  @override
  Future<void> stop() async => stops++;
}

/// Fake dialer: records the numbers it was asked to open.
class FakeDialer implements Dialer {
  /// Numbers opened, in order.
  final opened = <String>[];

  @override
  Future<void> open(String number) async => opened.add(number);
}

/// Fake battery.
class FakeBatteryMonitor implements BatteryMonitor {
  /// Creates a battery at [_level] percent.
  FakeBatteryMonitor({this._level = 100});

  final StreamController<int> _c = _sync<int>();
  int _level;

  @override
  int get level => _level;

  @override
  Stream<int> get changes => _c.stream;

  /// Sets the level and notifies listeners.
  void set(int level) {
    _level = level;
    _c.add(level);
  }
}

/// Fake exact alarms; call `fireDue` to fire what is due on the clock.
class FakeAlarmScheduler implements AlarmScheduler {
  /// Creates a scheduler reading time from `clock`.
  FakeAlarmScheduler(this._clock);

  final Clock _clock;
  final StreamController<int> _c = _sync<int>();
  final _alarms = <int, DateTime>{};

  @override
  Stream<int> get fired => _c.stream;

  @override
  Future<void> schedule(int id, DateTime at) async => _alarms[id] = at;

  @override
  Future<void> cancel(int id) async => _alarms.remove(id);

  /// Ids currently scheduled.
  Iterable<int> get pending => _alarms.keys;

  /// Fires, once, every alarm whose time has come.
  void fireDue() {
    final now = _clock.now();
    final due = [
      for (final e in _alarms.entries)
        if (!e.value.isAfter(now)) e.key,
    ]..sort();
    due.forEach(_alarms.remove);
    due.forEach(_c.add);
  }
}

/// Fake voice and cue output.
class FakeAudioOutput implements AudioOutput {
  final StreamController<bool> _c = _sync<bool>();

  /// Texts spoken, oldest first.
  final spoken = <String>[];

  /// Cues played, oldest first.
  final cues = <AudioCue>[];

  @override
  Stream<bool> get headphones => _c.stream;

  @override
  Future<void> speak(String text) async {
    cues.add(AudioCue.chime);
    spoken.add(text);
  }

  @override
  Future<void> cue(AudioCue cue) async => cues.add(cue);

  @override
  Future<void> stop() async {}

  /// Signals headphones connected or removed.
  void setHeadphones({required bool connected}) => _c.add(connected);
}

/// Fake push-to-talk audio.
class FakePttAudio implements PttAudio {
  final StreamController<({String peerId, bool speaking})> _c =
      _sync<({String peerId, bool speaking})>();

  /// True while this phone is talking.
  bool talking = false;

  @override
  Stream<({String peerId, bool speaking})> get incoming => _c.stream;

  @override
  Future<void> startTalking() async => talking = true;

  @override
  Future<void> stopTalking() async => talking = false;

  /// Signals that [peerId] started or stopped talking to us.
  void peer(String peerId, {required bool speaking}) =>
      _c.add((peerId: peerId, speaking: speaking));
}

/// Fake SMS radio: records what was sent; call [report] to emit a status.
class FakeSmsGateway implements SmsGateway {
  final StreamController<SmsReport> _c = _sync<SmsReport>();

  /// Messages handed to [send], oldest first.
  final sent = <SmsMessage>[];

  /// When set, [send] throws it (radio off, permission revoked...).
  Object? sendError;

  @override
  Stream<SmsReport> get reports => _c.stream;

  @override
  Future<void> send(SmsMessage message) async {
    // Tests may inject any error object to simulate radio failures.
    // ignore: only_throw_errors
    if (sendError != null) throw sendError!;
    sent.add(message);
  }

  /// Emits a status update for message [id].
  void report(String id, SmsStatus status) =>
      _c.add(SmsReport(id: id, status: status));
}

/// Fake BLE beacon.
class FakeBeaconTransport implements BeaconTransport {
  /// Creates a beacon with the given [capabilities].
  FakeBeaconTransport({
    this.capabilities = const BeaconCapabilities(
      codedPhy: true,
      extendedAdvertising: true,
    ),
  });

  final StreamController<BeaconSighting> _c = _sync<BeaconSighting>();

  @override
  final BeaconCapabilities capabilities;

  /// Payload being broadcast, or null when not broadcasting.
  Uint8List? broadcasting;

  /// True while scanning.
  bool scanning = false;

  @override
  Stream<BeaconSighting> get sightings => _c.stream;

  @override
  Future<void> startBeacon(Uint8List payload) async => broadcasting = payload;

  @override
  Future<void> stopBeacon() async => broadcasting = null;

  @override
  Future<void> startScan() async => scanning = true;

  @override
  Future<void> stopScan() async => scanning = false;

  /// Signals a beacon heard nearby.
  void hear(Uint8List payload, {int rssi = -70}) =>
      _c.add(BeaconSighting(payload: payload, rssi: rssi));
}

/// In-memory outbox store with a switch to simulate a full disk.
class FakeSmsOutboxStore implements SmsOutboxStore {
  /// Creates an empty store.
  FakeSmsOutboxStore();

  /// Creates a store holding a copy of [other]'s data (a process restart).
  FakeSmsOutboxStore.restoreFrom(FakeSmsOutboxStore other) {
    _rows.addAll(other._rows);
  }

  final _rows = <String, OutboxEntry>{};

  /// When true, [put] throws, as if storage were full.
  bool failWrites = false;

  @override
  Future<void> put(OutboxEntry entry) async {
    if (failWrites) throw StateError('storage full');
    _rows[entry.id] = entry;
  }

  @override
  Future<List<OutboxEntry>> all() async =>
      _rows.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

/// In-memory snapshot store with a switch to simulate a failing disk.
class FakeSnapshotStore implements SnapshotStore {
  /// Creates an empty store.
  FakeSnapshotStore();

  /// Creates a store holding a copy of [other]'s data (a process restart).
  FakeSnapshotStore.restoreFrom(FakeSnapshotStore other) {
    saved.addAll(other.saved);
  }

  /// Every saved snapshot, oldest first.
  final saved = <String>[];

  /// When true, [save] throws, as if storage were full.
  bool failWrites = false;

  @override
  Future<void> save(String json, {required DateTime at}) async {
    if (failWrites) throw StateError('storage full');
    saved.add(json);
  }

  @override
  Future<String?> latest() async => saved.isEmpty ? null : saved.last;
}

/// Fake heartbeat sink that records every beat.
class FakeHeartbeatSink implements HeartbeatSink {
  /// Beats received, oldest first.
  final beats = <DateTime>[];

  /// When set, [beat] throws it.
  Error? error;

  @override
  Future<void> beat(DateTime at) async {
    if (error != null) throw error!;
    beats.add(at);
  }
}

/// Fake trek service control.
class FakeTrekService implements TrekService {
  /// Whether the service is running.
  bool running = false;

  @override
  Future<void> start() async => running = true;

  @override
  Future<void> stop() async => running = false;
}

/// A linked pair of fake channels: what the UI sends reaches the core, what
/// the core publishes reaches the UI. Commands sent before the core listens
/// are queued, like the native relay does.
class FakeBridge {
  final _commands = StreamController<String>.broadcast(sync: true);
  final _states = StreamController<String>.broadcast(sync: true);
  final _queued = <String>[];
  String? _latestState;
  bool _coreListening = false;

  /// The core's end.
  late final CoreChannel core = _FakeCore(this);

  /// The UI's end.
  late final UiChannel ui = _FakeUi(this);

  /// Every command the UI ever sent, oldest first.
  final sentCommands = <String>[];

  /// Every state the core ever published, oldest first.
  final publishedStates = <String>[];
}

class _FakeCore implements CoreChannel {
  _FakeCore(this._b);
  final FakeBridge _b;

  @override
  Stream<String> get commands {
    _b._coreListening = true;
    final queued = List<String>.of(_b._queued);
    _b._queued.clear();
    return Stream<String>.multi((c) {
      queued.forEach(c.add);
      final sub = _b._commands.stream.listen(c.add);
      c.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> publish(String json) async {
    _b
      ..publishedStates.add(json)
      .._latestState = json
      .._states.add(json);
  }
}

class _FakeUi implements UiChannel {
  _FakeUi(this._b);
  final FakeBridge _b;

  @override
  Stream<String> get states => Stream<String>.multi((c) {
    final latest = _b._latestState;
    if (latest != null) c.add(latest);
    final sub = _b._states.stream.listen(c.add);
    c.onCancel = sub.cancel;
  });

  @override
  Future<void> send(String json) async {
    _b.sentCommands.add(json);
    if (_b._coreListening) {
      _b._commands.add(json);
    } else {
      _b._queued.add(json);
    }
  }
}
