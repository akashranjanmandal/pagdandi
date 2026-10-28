import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_ports/core_ports.dart';

/// Tells the native safety guard "the core is alive" every [period]. It beats
/// once immediately so the guard never sees a gap, and a failing sink is
/// logged without ever stopping the loop.
class HeartbeatLoop {
  /// Creates the loop. The default period (10 s) is well inside the guard's
  /// 30 s timeout.
  HeartbeatLoop({
    required this._sink,
    required this._clock,
    required Logger logger,
    this.period = const Duration(seconds: 10),
  }) : _log = logger;

  final HeartbeatSink _sink;
  final Clock _clock;
  final Logger _log;

  /// Time between beats.
  final Duration period;

  Timer? _timer;

  /// Starts beating (idempotent).
  void start() {
    if (_timer != null) return;
    unawaited(_beat());
    _timer = Timer.periodic(period, (_) => unawaited(_beat()));
  }

  /// Stops beating.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _beat() async {
    try {
      await _sink.beat(_clock.now());
    } on Object catch (e) {
      _log.warn('heartbeat', 'beat failed, will try again', error: e);
    }
  }
}
