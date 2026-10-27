/// 4 pt spacing grid.
abstract final class Spacing {
  /// Allowed spacing values.
  static const List<double> scale = [4, 8, 12, 16, 20, 24, 32];

  /// Horizontal screen padding.
  static const double screenSide = 18;
}

/// Corner radii. Buttons are rounded squares, never circles.
abstract final class Radii {
  /// The PTT button.
  static const double ptt = 28;

  /// Hold buttons and quick-message targets.
  static const double hold = 20;

  /// Other large controls: toggles, snooze, back, wide buttons.
  static const double control = 16;

  /// Panels.
  static const double panel = 12;

  /// Small chips.
  static const double chip = 8;
}

/// Touch target sizes in dp, with glove-mode scaling.
abstract final class Targets {
  /// Minimum size of any control.
  static const double min = 56;

  /// Primary actions.
  static const double primary = 72;

  /// Push-to-talk.
  static const double ptt = 104;

  /// Glove mode scale for targets.
  static const double gloveTarget = 1.25;

  /// Glove mode scale for spacing.
  static const double gloveSpacing = 1.15;

  /// [size] scaled for glove mode when [glove] is true.
  static double scaled(double size, {required bool glove}) =>
      glove ? size * gloveTarget : size;

  /// [gap] scaled for glove mode when [glove] is true.
  static double spaced(double gap, {required bool glove}) =>
      glove ? gap * gloveSpacing : gap;
}
