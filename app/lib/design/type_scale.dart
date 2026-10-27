import 'package:flutter/painting.dart';

/// Type tokens. Barlow for text, Barlow Condensed for large numbers; both are
/// bundled (no runtime font fetching). Sentence case everywhere.
abstract final class TypeScale {
  static const String _text = 'Barlow';
  static const String _condensed = 'BarlowCondensed';
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// 44, condensed: one per screen at most (emergencies).
  static const TextStyle display = TextStyle(
    fontFamily: _condensed,
    fontSize: 44,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  /// 30, condensed: the main HUD number or instruction.
  static const TextStyle hero = TextStyle(
    fontFamily: _condensed,
    fontSize: 30,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  /// 20.
  static const TextStyle title = TextStyle(
    fontFamily: _text,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  /// 16.
  static const TextStyle body = TextStyle(
    fontFamily: _text,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );

  /// 13.
  static const TextStyle label = TextStyle(
    fontFamily: _text,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );

  /// 12: the minimum size on device.
  static const TextStyle caption = TextStyle(
    fontFamily: _text,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );

  /// The single dominant number on a screen (weight 600 is allowed only here).
  static const TextStyle dominantNumber = TextStyle(
    fontFamily: _condensed,
    fontSize: 44,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );
}
