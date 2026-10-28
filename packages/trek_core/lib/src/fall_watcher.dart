import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_safety/engine_safety.dart';

/// Runs the fall detector on live accelerometer data, only while a trek is on
/// (an idle phone should not spend battery on it). A detector that cannot run
/// never affects the rest of the core.
class FallWatcher {
  /// Creates the watcher. [_onFall] is called when a fall is suspected.
  FallWatcher({
    required this._accelerometer,
    required this._onFall,
    required Logger logger,
  }) : _log = logger;

  final Accelerometer _accelerometer;
  final Future<void> Function() _onFall;
  final Logger _log;
  StreamSubscription<AccelSample>? _sub;
  static const _tag = 'fall';

  /// Whether samples are being watched.
  bool get running => _sub != null;

  /// Starts watching (25 samples a second). Starting twice does nothing.
  void start() {
    if (_sub != null) return;
    final detector = FallDetector();
    _sub = _accelerometer
        .samples(const Duration(milliseconds: 40))
        .listen(
          (s) {
            if (detector.onSample(s)) unawaited(_report());
          },
          onError: (Object e) {
            _log.warn(
              _tag,
              'the accelerometer failed; no fall detection',
              error: e,
            );
            _sub = null;
          },
          onDone: () {
            _log.warn(
              _tag,
              'no accelerometer on this phone; no fall detection',
            );
            _sub = null;
          },
        );
  }

  Future<void> _report() async {
    try {
      await _onFall();
    } on Object catch (e) {
      _log.error(_tag, 'could not start the fall countdown', error: e);
    }
  }

  /// Stops watching and forgets any half-seen fall.
  void stop() {
    unawaited(_sub?.cancel());
    _sub = null;
  }
}
