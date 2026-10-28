import 'dart:math' as math;

import 'package:core_geo/core_geo.dart';
import 'package:engine_navigation/src/route.dart';
import 'package:meta/meta.dart';

/// Where the walker is on the trail, in words.
enum NavStatus {
  /// On the route.
  onRoute,

  /// Away from the route for several fixes in a row.
  offRoute,

  /// Steadily walking back toward the start.
  wrongWay,

  /// No position for a while; nothing is claimed.
  gpsLost,
}

/// One accepted position fix.
@immutable
class NavFix {
  /// Creates a fix.
  const NavFix({
    required this.position,
    required this.accuracyM,
    required this.time,
  });

  /// Where.
  final GeoPoint position;

  /// Accuracy radius in metres.
  final double accuracyM;

  /// GPS time.
  final DateTime time;
}

/// What the tracker knows after a fix or a tick.
@immutable
class NavSnapshot {
  /// Creates a snapshot.
  const NavSnapshot({
    required this.status,
    required this.progressM,
    required this.remainingM,
    required this.totalM,
    required this.crossTrackM,
    required this.bearingToGoDeg,
    required this.arrived,
    this.nextCheckpoint,
    this.distanceToCheckpointM,
    this.reachedCheckpoint,
  });

  /// Where the walker stands.
  final NavStatus status;

  /// Metres done.
  final double progressM;

  /// Metres left.
  final double remainingM;

  /// Route length.
  final double totalM;

  /// Metres from the trail.
  final double crossTrackM;

  /// The direction to walk, degrees from north (back to the trail when off
  /// route, along the trail otherwise).
  final double bearingToGoDeg;

  /// Within 30 m of the end.
  final bool arrived;

  /// The next named place ahead, if any.
  final Checkpoint? nextCheckpoint;

  /// Metres to it.
  final double? distanceToCheckpointM;

  /// A checkpoint crossed with this fix (announced once).
  final Checkpoint? reachedCheckpoint;
}

/// Follows a [Route]: progress, off-route (beyond max(25 m, 2 x accuracy) for
/// three fixes in a row, cleared inside 15 m), wrong way (steadily losing
/// progress), GPS lost (silence), checkpoints.
class NavigationTracker {
  /// Creates a tracker for [route].
  NavigationTracker(
    Route route, {
    this.gpsLostAfter = const Duration(seconds: 60),
  }) : _route = route;

  /// Silence longer than this is GPS lost.
  final Duration gpsLostAfter;

  Route _route;
  var _reversed = false;
  NavSnapshot? _current;
  DateTime? _lastFixAt;
  double? _lastProgress;
  var _offCount = 0;
  var _offRoute = false;
  var _wrongWay = false;
  var _gpsLost = false;
  double _minSinceWrong = 0;
  final _history = <double>[];
  final _reached = <String>{};

  static const double _offFloorM = 25;
  static const double _clearM = 15;
  static const int _offFixes = 3;
  static const double _wrongDropM = 40;
  static const double _wrongNoiseM = 3;
  static const int _wrongWindow = 5;
  static const double _wrongClearM = 20;
  static const double _arrivedM = 30;
  static const double _checkpointReachM = 25;

  /// The route being followed (reversed after [reverse]).
  Route get route => _route;

  /// Whether the route is being walked backwards.
  bool get isReversed => _reversed;

  /// The latest snapshot, or null before the first fix.
  NavSnapshot? get current => _current;

  /// Walk the same trail the other way (the way home).
  void reverse() {
    _route = _route.reversed();
    _reversed = !_reversed;
    _reset();
  }

  void _reset() {
    _current = null;
    _lastProgress = null;
    _offCount = 0;
    _offRoute = false;
    _wrongWay = false;
    _gpsLost = false;
    _history.clear();
    _reached.clear();
  }

  /// A new accepted fix.
  NavSnapshot? onFix(NavFix fix) {
    final m = _route.project(fix.position, nearProgressM: _lastProgress);
    final resumed = _gpsLost;
    if (resumed) {
      // Silence says nothing about being off the trail.
      _gpsLost = false;
      _offCount = 0;
      _history.clear();
    }
    _lastFixAt = fix.time;

    final limit = math.max(_offFloorM, 2 * fix.accuracyM);
    if (_offRoute) {
      if (m.crossTrackM < _clearM) {
        _offRoute = false;
        _offCount = 0;
      }
    } else if (m.crossTrackM > limit) {
      _offCount++;
      if (_offCount >= _offFixes) _offRoute = true;
    } else {
      _offCount = 0;
    }

    if (!_offRoute) {
      _history.add(m.progressM);
      if (_history.length > _wrongWindow) _history.removeAt(0);
      if (_wrongWay) {
        _minSinceWrong = math.min(_minSinceWrong, m.progressM);
        if (m.progressM >= _minSinceWrong + _wrongClearM) {
          _wrongWay = false;
          _history
            ..clear()
            ..add(m.progressM);
        }
      } else if (_history.length >= _wrongWindow && _isLosing()) {
        _wrongWay = true;
        _minSinceWrong = m.progressM;
      }
    }

    final prev = _lastProgress;
    _lastProgress = m.progressM;
    final status = _offRoute
        ? NavStatus.offRoute
        : _wrongWay
        ? NavStatus.wrongWay
        : NavStatus.onRoute;

    Checkpoint? reachedNow;
    Checkpoint? next;
    for (final c in _route.checkpoints) {
      final key = '${c.name}@${c.distanceAlongM.round()}';
      if (_reached.contains(key)) continue;
      if (m.progressM >= c.distanceAlongM - _checkpointReachM) {
        _reached.add(key);
        final crossed =
            prev != null && prev < c.distanceAlongM - _checkpointReachM;
        if (crossed && !_offRoute) reachedNow ??= c;
      } else {
        next ??= c;
      }
    }

    final bearing = _offRoute
        ? bearingDeg(fix.position, m.snapped)
        : bearingDeg(
            _route.positionAt(m.progressM),
            _route.positionAt(m.progressM + 30),
          );
    final remaining = math.max(0, _route.totalM - m.progressM).toDouble();
    return _current = NavSnapshot(
      status: status,
      progressM: m.progressM,
      remainingM: remaining,
      totalM: _route.totalM,
      crossTrackM: m.crossTrackM,
      bearingToGoDeg: bearing,
      arrived: remaining <= _arrivedM,
      nextCheckpoint: next,
      distanceToCheckpointM: next == null
          ? null
          : math.max(0, next.distanceAlongM - m.progressM).toDouble(),
      reachedCheckpoint: reachedNow,
    );
  }

  bool _isLosing() {
    final drop = _history.first - _history.last;
    if (drop < _wrongDropM) return false;
    for (var i = 1; i < _history.length; i++) {
      if (_history[i] - _history[i - 1] > _wrongNoiseM) return false;
    }
    return true;
  }

  /// Time passing. Returns a snapshot only when GPS has just been lost.
  NavSnapshot? onTick(DateTime now) {
    final last = _lastFixAt;
    final cur = _current;
    if (last == null || cur == null || _gpsLost) return null;
    if (now.difference(last) < gpsLostAfter) return null;
    _gpsLost = true;
    return _current = NavSnapshot(
      status: NavStatus.gpsLost,
      progressM: cur.progressM,
      remainingM: cur.remainingM,
      totalM: cur.totalM,
      crossTrackM: cur.crossTrackM,
      bearingToGoDeg: cur.bearingToGoDeg,
      arrived: cur.arrived,
      nextCheckpoint: cur.nextCheckpoint,
      distanceToCheckpointM: cur.distanceToCheckpointM,
    );
  }
}
