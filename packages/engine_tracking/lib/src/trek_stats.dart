import 'package:core_geo/core_geo.dart';
import 'package:core_model/core_model.dart';
import 'package:meta/meta.dart';

/// Numbers for the trek so far, computed from the breadcrumb.
@immutable
class TrekStats {
  /// Creates stats.
  const TrekStats({
    required this.distanceM,
    required this.climbM,
    required this.elapsed,
    required this.altitudeM,
  });

  /// Distance walked in metres.
  final double distanceM;

  /// Total ascent in metres (noise filtered).
  final double climbM;

  /// First fix to last fix.
  final Duration elapsed;

  /// Latest known altitude, or null.
  final double? altitudeM;
}

/// Ascent counted only in steps of at least this many metres, so GPS altitude
/// jitter does not add up to a fake climb.
const double _climbStepM = 3;

/// Computes [TrekStats] from [fixes] (oldest first).
TrekStats computeStats(List<LocationFix> fixes) {
  if (fixes.isEmpty) {
    return const TrekStats(
      distanceM: 0,
      climbM: 0,
      elapsed: Duration.zero,
      altitudeM: null,
    );
  }
  var distance = 0.0;
  for (var i = 1; i < fixes.length; i++) {
    distance += distanceM(
      GeoPoint(fixes[i - 1].latitude, fixes[i - 1].longitude),
      GeoPoint(fixes[i].latitude, fixes[i].longitude),
    );
  }
  // Hysteresis: only move the reference altitude by real steps.
  var climb = 0.0;
  double? ref;
  double? last;
  for (final f in fixes) {
    final a = f.altitudeM;
    if (a == null) continue;
    last = a;
    final r = ref;
    if (r == null) {
      ref = a;
    } else if (a - r >= _climbStepM) {
      climb += a - r;
      ref = a;
    } else if (r - a >= _climbStepM) {
      ref = a;
    }
  }
  return TrekStats(
    distanceM: distance,
    climbM: climb,
    elapsed: fixes.last.gpsTime.difference(fixes.first.gpsTime),
    altitudeM: last,
  );
}
