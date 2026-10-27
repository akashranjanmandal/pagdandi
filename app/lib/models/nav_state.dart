import 'package:pagdandi_app/design/icons.dart';

/// Navigation region of the trek state, as the UI shows it.
enum NavState {
  /// On the planned route.
  onRoute('On route', AppIcon.ok),

  /// A fork is coming up.
  junction('Junction ahead', AppIcon.fork),

  /// Left the trail.
  offRoute('Off route', AppIcon.warn),

  /// Walking back toward the start.
  wrongWay('Wrong way', AppIcon.uturn),

  /// No usable GPS.
  gpsLost('GPS lost', AppIcon.gps),

  /// Regrouping with a friend who fell behind.
  regroup('Regrouping', AppIcon.radar);

  const NavState(this.tagLabel, this.icon);

  /// Word shown in the status tag.
  final String tagLabel;

  /// Distinct shape shown in the status tag (never colour alone).
  final AppIcon icon;
}

/// The angle to rotate a dial to, turning the shortest way from [current]
/// (which may already be accumulated past 360) toward [target] degrees.
double nextRotation(double current, double target) =>
    current + (((target - current) % 360 + 540) % 360 - 180);
