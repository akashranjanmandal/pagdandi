import 'package:core_geo/core_geo.dart';
import 'package:meta/meta.dart';

/// Where to head to retrace your breadcrumb back to the start.
@immutable
class BackGuidance {
  /// Creates guidance.
  const BackGuidance({
    required this.bearingDeg,
    required this.distanceToNextM,
    required this.remainingM,
    required this.next,
    required this.arrived,
  });

  /// Direction to walk, degrees from north.
  final double bearingDeg;

  /// Distance to the next aim point.
  final double distanceToNextM;

  /// Distance left back to the start, along the trail.
  final double remainingM;

  /// The point to aim at.
  final GeoPoint next;

  /// Close enough to the start.
  final bool arrived;
}

/// Guides back along [breadcrumb] (oldest first) from [current]: aim at the
/// trail point [lookaheadM] back from the nearest point, or the start. Null
/// when there is no breadcrumb.
BackGuidance? takeMeBack(
  List<GeoPoint> breadcrumb,
  GeoPoint current, {
  double lookaheadM = 30,
  double arriveM = 15,
}) {
  if (breadcrumb.isEmpty) return null;
  final near = nearestOnPath(breadcrumb, current);
  var target = near.index;
  var along = 0.0;
  // Half a metre of tolerance so 30 m of trail counts as 30 m.
  while (target > 0 && along < lookaheadM - 0.5) {
    along += distanceM(breadcrumb[target], breadcrumb[target - 1]);
    target--;
  }
  final next = breadcrumb[target];
  final remaining =
      near.distanceM + pathLengthM(breadcrumb.sublist(0, near.index + 1));
  return BackGuidance(
    bearingDeg: bearingDeg(current, next),
    distanceToNextM: distanceM(current, next),
    remainingM: remaining,
    next: next,
    arrived: remaining <= arriveM,
  );
}
