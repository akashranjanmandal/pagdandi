import 'dart:async';

import 'package:engine_health/src/issues.dart';
import 'package:engine_health/src/watchdog.dart';

/// Runs the watchdog and announces only changes, so the UI banner and the
/// notification do not flicker.
class HealthMonitor {
  /// Creates a monitor around a watchdog.
  HealthMonitor(this._watchdog);

  final HealthWatchdog _watchdog;
  final _changes = StreamController<List<HealthIssue>>.broadcast(sync: true);
  List<HealthIssue> _current = const [];

  /// The issues as of the last check.
  List<HealthIssue> get current => _current;

  /// Emits when the set of issues changes.
  Stream<List<HealthIssue>> get changes => _changes.stream;

  /// Evaluates [inputs]; emits if the issues differ from last time.
  void check(HealthInputs inputs) {
    final next = _watchdog.evaluate(inputs);
    final same =
        next.length == _current.length &&
        [for (var i = 0; i < next.length; i++) next[i] == _current[i]]
            .every((e) => e);
    if (same) return;
    _current = next;
    _changes.add(next);
  }
}
