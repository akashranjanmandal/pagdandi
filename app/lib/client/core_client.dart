import 'dart:async';

import 'package:clock/clock.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:trek_core/trek_core.dart';

/// The UI's thin client of the trek core: it shows the newest state the core
/// published and sends commands. It never decides anything itself.
class CoreClient {
  /// Creates a client. The register callback tells the relay this engine is
  /// the UI; it runs only after the client listens, so the latest state is
  /// not lost.
  CoreClient({
    required this._channel,
    required this._register,
  });

  final UiChannel _channel;
  final Future<void> Function() _register;
  final _out = StreamController<CoreStateMessage>.broadcast(sync: true);
  StreamSubscription<String>? _sub;
  // Monotonic, and driven by fake time in tests.
  final Stopwatch _age = clock.stopwatch();
  CoreStateMessage? _latest;

  /// Newest state, or null until the core has sent one.
  CoreStateMessage? get latest => _latest;

  /// How long ago the newest state arrived (monotonic, not the wall clock).
  Duration get sinceReceived => _age.elapsed;

  /// Whether the core has been heard from.
  bool get connected => _latest != null;

  /// Every new state.
  Stream<CoreStateMessage> get states => _out.stream;

  /// Starts listening, then registers with the relay.
  Future<void> connect() async {
    _sub ??= _channel.states.listen((json) {
      final m = CoreStateMessage.decode(json);
      if (m == null) return;
      _latest = m;
      _age
        ..reset()
        ..start();
      _out.add(m);
    });
    await _register();
  }

  /// Sends [event] to the core. A failing relay never reaches the screen.
  Future<void> send(TrekEvent event) async {
    try {
      await _channel.send(encodeCommand(event));
    } on Object {
      // The relay keeps trying; the UI must not crash on a dead core.
    }
  }

  /// Tells the core to follow the route the other way (walking home).
  Future<void> reverseRoute() async {
    try {
      await _channel.send(encodeReverseRoute());
    } on Object {
      // The relay keeps trying; the UI must not crash on a dead core.
    }
  }

  /// Drops a pin at the current position.
  Future<void> dropPin() => _sendRaw(encodeDropPin());

  /// Silences off-route alerts for 10 minutes ("I know, exploring").
  Future<void> snoozeAlerts() => _sendRaw(encodeSnoozeAlerts());

  /// Brings the alerts back.
  Future<void> resumeAlerts() => _sendRaw(encodeResumeAlerts());

  Future<void> _sendRaw(String json) async {
    try {
      await _channel.send(json);
    } on Object {
      // The relay keeps trying; the UI must not crash on a dead core.
    }
  }

  /// Stops listening.
  Future<void> dispose() async {
    await _sub?.cancel();
    await _out.close();
  }
}
