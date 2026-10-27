import 'package:flutter/painting.dart';

/// Colour tokens (docs/design/tokens.md). Dark only: true black saves OLED
/// battery. Sunlight mode is a second palette, not a different theme.
///
/// The `sos` and `tintSos` colours are reserved for SOS, Friend SOS, danger
/// pins and danger zone states. UI code must reach them only through
/// `sos_colour.dart`; a test enforces this.
class Palette {
  /// Creates a palette.
  const Palette({
    required this.bg,
    required this.surface,
    required this.raised,
    required this.hairline,
    required this.contour,
    required this.text,
    required this.text2,
    required this.text3,
    required this.signal,
    required this.nav,
    required this.ok,
    required this.warn,
    required this.sos,
    required this.tintNav,
    required this.tintWarn,
    required this.tintSignal,
    required this.tintSos,
    required this.lineScale,
  });

  /// Screen background.
  final Color bg;

  /// Glance zone and panels.
  final Color surface;

  /// Pressed or selected surfaces.
  final Color raised;

  /// Dividers.
  final Color hairline;

  /// Map contour lines.
  final Color contour;

  /// Primary text, and all instruction sub-lines (AAA).
  final Color text;

  /// Labels and metadata only (AA, not AAA).
  final Color text2;

  /// Non-essential, non-text-critical elements only.
  final Color text3;

  /// Rescue orange: primary action, you, PTT.
  final Color signal;

  /// Glacier cyan: route, directions, info.
  final Color nav;

  /// On route, in range, delivered.
  final Color ok;

  /// Off route, weak link, health warnings, blocking states.
  final Color warn;

  /// SOS and real danger only.
  final Color sos;

  /// HUD tint for navigation states.
  final Color tintNav;

  /// HUD tint for warnings.
  final Color tintWarn;

  /// HUD tint for regroup and lost states.
  final Color tintSignal;

  /// HUD tint for SOS states.
  final Color tintSos;

  /// Multiplier for line widths (2 in sunlight mode).
  final double lineScale;

  /// Normal dark palette.
  static const Palette normal = Palette(
    bg: Color(0xFF000000),
    surface: Color(0xFF0E1114),
    raised: Color(0xFF171B1F),
    hairline: Color(0xFF262C32),
    contour: Color(0xFF1A2026),
    text: Color(0xFFECEFF1),
    text2: Color(0xFF8A949E),
    text3: Color(0xFF6E7A85),
    signal: Color(0xFFFF6B1A),
    nav: Color(0xFF5CC8E0),
    ok: Color(0xFF4CD18A),
    warn: Color(0xFFFFB020),
    sos: Color(0xFFFF3B30),
    tintNav: Color(0xFF0B1A1F),
    tintWarn: Color(0xFF1F1608),
    tintSignal: Color(0xFF1F0F05),
    tintSos: Color(0xFF1F0706),
    lineScale: 1,
  );

  /// Sunlight palette: pure white text, no text-3, no tints, stronger lines.
  static const Palette sunlight = Palette(
    bg: Color(0xFF000000),
    surface: Color(0xFF0E1114),
    raised: Color(0xFF171B1F),
    hairline: Color(0xFF4A545D),
    contour: Color(0xFF3A444C),
    text: Color(0xFFFFFFFF),
    text2: Color(0xFFD0D6DB),
    text3: Color(0xFFD0D6DB),
    signal: Color(0xFFFF6B1A),
    nav: Color(0xFF5CC8E0),
    ok: Color(0xFF4CD18A),
    warn: Color(0xFFFFB020),
    sos: Color(0xFFFF3B30),
    tintNav: Color(0xFF000000),
    tintWarn: Color(0xFF000000),
    tintSignal: Color(0xFF000000),
    tintSos: Color(0xFF000000),
    lineScale: 2,
  );
}
