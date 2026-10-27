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

  @override
  Stream<SmsReport> get reports => _c.stream;

  @override
  Future<void> send(SmsMessage message) async => sent.add(message);

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
