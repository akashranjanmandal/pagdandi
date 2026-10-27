import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/design/motion.dart';
import 'package:pagdandi_app/design/palette.dart';
import 'package:pagdandi_app/design/shape.dart';
import 'package:pagdandi_app/design/type_scale.dart';

void main() {
  test('normal palette matches docs/design/tokens.md', () {
    const p = Palette.normal;
    expect(p.bg, const Color(0xFF000000));
    expect(p.surface, const Color(0xFF0E1114));
    expect(p.raised, const Color(0xFF171B1F));
    expect(p.hairline, const Color(0xFF262C32));
    expect(p.contour, const Color(0xFF1A2026));
    expect(p.text, const Color(0xFFECEFF1));
    expect(p.text2, const Color(0xFF8A949E));
    expect(p.text3, const Color(0xFF6E7A85));
    expect(p.signal, const Color(0xFFFF6B1A));
    expect(p.nav, const Color(0xFF5CC8E0));
    expect(p.ok, const Color(0xFF4CD18A));
    expect(p.warn, const Color(0xFFFFB020));
    expect(p.sos, const Color(0xFFFF3B30));
    expect(p.tintNav, const Color(0xFF0B1A1F));
    expect(p.tintWarn, const Color(0xFF1F1608));
    expect(p.tintSignal, const Color(0xFF1F0F05));
    expect(p.tintSos, const Color(0xFF1F0706));
  });

  test('sunlight palette: white text, no text-3, no tints, thicker lines', () {
    const p = Palette.sunlight;
    expect(p.text, const Color(0xFFFFFFFF));
    expect(p.text2, const Color(0xFFD0D6DB));
    expect(p.text3, p.text2);
    for (final t in [p.tintNav, p.tintWarn, p.tintSignal, p.tintSos]) {
      expect(t, p.bg);
    }
    expect(p.lineScale, 2);
    expect(Palette.normal.lineScale, 1);
  });

  test('spacing is on the 4 pt grid', () {
    for (final s in Spacing.scale) {
      expect(s % 4, 0);
    }
    expect(Spacing.screenSide, 18);
  });

  test('touch targets meet the minimums and glove mode scales them', () {
    expect(Targets.min, 56);
    expect(Targets.primary, 72);
    expect(Targets.ptt, 104);
    expect(Targets.scaled(56, glove: true), 70);
    expect(Targets.scaled(104, glove: true), 130);
    expect(Targets.scaled(56, glove: false), 56);
    expect(Targets.spaced(20, glove: true), closeTo(23, 1e-9));
  });

  test('buttons are rounded squares, not circles', () {
    expect(Radii.ptt, 28);
    expect(Radii.hold, 20);
    expect(Radii.control, 16);
    expect(Radii.panel, 12);
    expect(Radii.chip, 8);
    // a radius of half the side would make a circle
    expect(Radii.ptt, lessThan(Targets.ptt / 2));
    expect(Radii.hold, lessThan(66 / 2));
  });

  test('motion durations', () {
    expect(Motion.fast, const Duration(milliseconds: 120));
    expect(Motion.base, const Duration(milliseconds: 220));
    expect(Motion.slow, const Duration(milliseconds: 320));
  });

  test('type scale sizes and families', () {
    expect(TypeScale.display.fontSize, 44);
    expect(TypeScale.hero.fontSize, 30);
    expect(TypeScale.title.fontSize, 20);
    expect(TypeScale.body.fontSize, 16);
    expect(TypeScale.label.fontSize, 13);
    expect(TypeScale.caption.fontSize, 12);
    expect(TypeScale.display.fontFamily, 'BarlowCondensed');
    expect(TypeScale.hero.fontFamily, 'BarlowCondensed');
    expect(TypeScale.body.fontFamily, 'Barlow');
  });

  test(
    'nothing is smaller than 12 and only two weights (600 for one number)',
    () {
      final styles = [
        TypeScale.display,
        TypeScale.hero,
        TypeScale.title,
        TypeScale.body,
        TypeScale.label,
        TypeScale.caption,
      ];
      for (final s in styles) {
        expect(s.fontSize, greaterThanOrEqualTo(12));
        expect(
          [FontWeight.w400, FontWeight.w500].contains(s.fontWeight),
          isTrue,
        );
      }
      expect(TypeScale.dominantNumber.fontWeight, FontWeight.w600);
    },
  );

  test('numbers use tabular figures', () {
    for (final s in [TypeScale.display, TypeScale.hero, TypeScale.body]) {
      expect(s.fontFeatures, contains(const FontFeature.tabularFigures()));
    }
  });

  test('declared font files exist and carry their licences', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(r'asset: (\S+\.ttf)').allMatches(pubspec);
    expect(assets, hasLength(5));
    for (final m in assets) {
      expect(File(m.group(1)!).existsSync(), isTrue, reason: m.group(1));
    }
    expect(File('assets/fonts/OFL-Barlow.txt').existsSync(), isTrue);
    expect(File('assets/fonts/OFL-BarlowCondensed.txt').existsSync(), isTrue);
  });
}
