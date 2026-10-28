import 'package:core_geo/core_geo.dart';
import 'package:core_model/core_model.dart';

/// Why a fix was accepted or rejected.
enum FixVerdict {
  /// Good: record it.
  accepted,

  /// Accuracy worse than the limit.
  poorAccuracy,

  /// GPS time not after the last accepted fix.
  outOfOrder,

  /// Implies a speed no walker reaches: a GPS jump.
  impossibleSpeed,

  /// Moved less than the minimum: standing still or GPS jitter.
  tooClose,
}

/// Rejects poor-accuracy fixes, GPS jumps and jitter before they reach the
/// breadcrumb. Distances are measured from the last ACCEPTED fix so slow drift
/// is not lost. If the baseline itself was the outlier, [resyncAfter]
/// consecutive jumps re-sync to the new position.
class FixFilter {
  /// Creates a filter.
  FixFilter({
    this.maxAccuracyM = 40,
    this.maxSpeedMps = 15,
    this.minMoveM = 8,
    this.resyncAfter = 3,
  });

  /// Worst accuracy radius accepted.
  final double maxAccuracyM;

  /// Fastest plausible speed in metres per second.
  final double maxSpeedMps;

  /// Smallest move worth recording.
  final double minMoveM;

  /// Consecutive impossible-speed fixes after which the baseline is replaced.
  final int resyncAfter;

  LocationFix? _last;
  int _jumps = 0;

  GeoPoint _p(LocationFix f) => GeoPoint(f.latitude, f.longitude);

  /// Judges [f] and, if accepted, makes it the new baseline.
  FixVerdict check(LocationFix f) {
    if (f.accuracyM > maxAccuracyM) return FixVerdict.poorAccuracy;
    final last = _last;
    if (last == null) return _accept(f);
    final dt = f.gpsTime.difference(last.gpsTime).inMicroseconds / 1e6;
    if (dt <= 0) return FixVerdict.outOfOrder;
    final dist = distanceM(_p(last), _p(f));
    if (dist / dt > maxSpeedMps) {
      _jumps++;
      return _jumps >= resyncAfter ? _accept(f) : FixVerdict.impossibleSpeed;
    }
    if (dist < minMoveM) return FixVerdict.tooClose;
    return _accept(f);
  }

  FixVerdict _accept(LocationFix f) {
    _last = f;
    _jumps = 0;
    return FixVerdict.accepted;
  }

  /// Sets the baseline without judging (restoring after a restart).
  void seed(LocationFix f) => _accept(f);

  /// Forgets the baseline.
  void reset() {
    _last = null;
    _jumps = 0;
  }
}
