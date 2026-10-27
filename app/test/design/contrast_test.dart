import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/design/contrast.dart';
import 'package:pagdandi_app/design/palette.dart';

void main() {
  group('contrastRatio', () {
    test('black on white is 21:1', () {
      expect(
        contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01),
      );
    });

    test('is symmetric and 1:1 for equal colours', () {
      const a = Color(0xFF8A949E);
      const b = Color(0xFF000000);
      expect(contrastRatio(a, b), contrastRatio(b, a));
      expect(contrastRatio(a, a), closeTo(1, 1e-9));
    });
  });

  // The automated contrast test required by the design review: every
  // text/background pair, in the normal and the sunlight palette.
  for (final entry in {
    'normal': Palette.normal,
    'sunlight': Palette.sunlight,
  }.entries) {
    final p = entry.value;
    final surfaces = {
      'bg': p.bg,
      'surface': p.surface,
      'raised': p.raised,
      'tintNav': p.tintNav,
      'tintWarn': p.tintWarn,
      'tintSignal': p.tintSignal,
      'tintSos': p.tintSos,
    };

    group('${entry.key} palette', () {
      for (final s in surfaces.entries) {
        test('primary text is AAA (7:1) on ${s.key}', () {
          expect(contrastRatio(p.text, s.value), greaterThanOrEqualTo(7));
        });
        test('secondary text is AA (4.5:1) on ${s.key}', () {
          expect(contrastRatio(p.text2, s.value), greaterThanOrEqualTo(4.5));
        });
        for (final accent in {
          'signal': p.signal,
          'nav': p.nav,
          'ok': p.ok,
          'warn': p.warn,
          'sos': p.sos,
        }.entries) {
          test('${accent.key} is AA (4.5:1) on ${s.key}', () {
            expect(
              contrastRatio(accent.value, s.value),
              greaterThanOrEqualTo(4.5),
            );
          });
        }
      }

      test('black text on a signal-filled button is AAA', () {
        expect(
          contrastRatio(const Color(0xFF000000), p.signal),
          greaterThanOrEqualTo(7),
        );
      });

      test('text-3 is AA on the plain background (its only use)', () {
        expect(contrastRatio(p.text3, p.bg), greaterThanOrEqualTo(4.5));
      });
    });
  }

  test(
    'secondary text alone is not AAA: it is never used for instructions',
    () {
      expect(
        contrastRatio(Palette.normal.text2, Palette.normal.bg),
        lessThan(7),
      );
    },
  );
}
