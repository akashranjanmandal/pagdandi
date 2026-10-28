import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:engine_health/engine_health.dart';

/// Reads the phone's health inputs now and then (permissions, battery
/// exemption, storage, GPS age) and hands them to the watchdog.
class HealthPoller {
  /// Creates a poller.
  HealthPoller({
    required this.read,
    required this.onInputs,
    required Logger logger,
    this.period = const Duration(seconds: 30),
  }) : _log = logger;

  /// Reads the current inputs.
  final Future<HealthInputs> Function() read;

  /// Receives each reading.
  final void Function(HealthInputs inputs) onInputs;

  /// Time between readings.
  final Duration period;

  final Logger _log;
  Timer? _timer;

  /// Reads at once, then every [period] (idempotent).
  void start() {
    if (_timer != null) return;
    unawaited(_poll());
    _timer = Timer.periodic(period, (_) => unawaited(_poll()));
  }

  /// Stops polling.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    try {
      onInputs(await read());
    } on Object catch (e) {
      _log.warn('health', 'could not read device health', error: e);
    }
  }
}
