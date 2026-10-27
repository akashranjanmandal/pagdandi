import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';
import 'package:pagdandi_app/design/palette.dart';

/// Colours of a physical key: raised face, light top rim, dark lower edge.
/// No shadows or glow: the edge is a flat band.
@immutable
class KeyStyle {
  /// Creates a style.
  const KeyStyle({
    required this.face,
    required this.rim,
    required this.edge,
    required this.content,
  });

  /// Neutral key (secondary actions).
  factory KeyStyle.neutral(Palette p) {
    final sun = p.lineScale > 1;
    return KeyStyle(
      face: sun ? p.surface : p.raised,
      rim: sun ? const Color(0xFFA9B2BA) : const Color(0xFF2E363E),
      edge: sun ? p.bg : const Color(0xFF07090A),
      content: p.text,
    );
  }

  /// Primary key: rescue orange, one per screen.
  factory KeyStyle.signal(Palette p) => KeyStyle(
    face: p.signal,
    rim: const Color(0xFFFF9A66),
    edge: const Color(0xFFA3400A),
    content: p.bg,
  );

  /// The big safe "I'm OK" key.
  factory KeyStyle.ok(Palette p) => KeyStyle(
    face: p.ok,
    rim: const Color(0xFF8BE8B8),
    edge: const Color(0xFF2A8A59),
    content: p.bg,
  );

  /// Key face.
  final Color face;

  /// Top rim.
  final Color rim;

  /// Lower edge.
  final Color edge;

  /// Text and icon colour on the face.
  final Color content;
}
