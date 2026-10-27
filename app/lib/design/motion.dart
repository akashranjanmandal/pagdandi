import 'package:flutter/animation.dart';

/// Motion tokens. Springs are stiff with no overshoot.
abstract final class Motion {
  /// Press feedback.
  static const Duration fast = Duration(milliseconds: 120);

  /// State change.
  static const Duration base = Duration(milliseconds: 220);

  /// Screen transition.
  static const Duration slow = Duration(milliseconds: 320);

  /// Entering: ease-out, no overshoot.
  static const Curve enter = Cubic(0.2, 0.9, 0.25, 1);

  /// Leaving: ease-in.
  static const Curve leave = Cubic(0.5, 0, 0.8, 0.4);
}
