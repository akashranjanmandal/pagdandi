import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/palette.dart';
import 'package:pagdandi_app/widgets/key_button.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

Widget host(Widget child, {UiPrefs prefs = const UiPrefs()}) => Directionality(
  textDirection: TextDirection.ltr,
  child: UiScope(
    prefs: prefs,
    child: Center(child: child),
  ),
);

void main() {
  testWidgets('tapping a key calls onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(KeyButton(label: 'Back to trek', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Back to trek'));
    expect(taps, 1);
  });

  testWidgets('a key is at least 72 dp tall (56 for compact)', (tester) async {
    await tester.pumpWidget(host(KeyButton(label: 'A', onPressed: () {})));
    expect(
      tester.getSize(find.byType(KeyButton)).height,
      greaterThanOrEqualTo(72),
    );
    await tester.pumpWidget(
      host(KeyButton(label: 'A', compact: true, onPressed: () {})),
    );
    expect(
      tester.getSize(find.byType(KeyButton)).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('glove mode makes keys 1.25x taller', (tester) async {
    await tester.pumpWidget(host(KeyButton(label: 'A', onPressed: () {})));
    final normal = tester.getSize(find.byType(KeyButton)).height;
    await tester.pumpWidget(
      host(
        KeyButton(label: 'A', onPressed: () {}),
        prefs: const UiPrefs(glove: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.getSize(find.byType(KeyButton)).height,
      closeTo(normal * 1.25, 0.01),
    );
  });

  testWidgets('a disabled key does not call onPressed and says so', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        KeyButton(
          label: 'Call 112',
          sub: 'No signal yet',
          enabled: false,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Call 112'));
    expect(taps, 0);
    expect(find.text('No signal yet'), findsOneWidget);
  });

  testWidgets('keys expose a button semantics node with their label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        KeyButton(
          label: 'Guide me there',
          icon: AppIcon.arrow,
          onPressed: () {},
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(KeyButton)),
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        label: 'Guide me there',
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('pressing drops the key face and releasing lifts it back', (
    tester,
  ) async {
    await tester.pumpWidget(host(KeyButton(label: 'A', onPressed: () {})));
    final rest = tester.getTopLeft(find.byKey(const Key('key-face'))).dy;
    final g = await tester.startGesture(
      tester.getCenter(find.byType(KeyButton)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.getTopLeft(find.byKey(const Key('key-face'))).dy,
      greaterThan(rest + 2),
    );
    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getTopLeft(find.byKey(const Key('key-face'))).dy, rest);
  });

  testWidgets('UiScope defaults to the normal palette and right hand', (
    tester,
  ) async {
    late UiPrefs seen;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: UiScope(
          prefs: const UiPrefs(),
          child: Builder(
            builder: (c) {
              seen = UiScope.of(c);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(seen.palette, Palette.normal);
    expect(seen.leftHanded, isFalse);
    expect(seen.glove, isFalse);
  });

  test('UiPrefs picks the sunlight palette when sunlight is on', () {
    expect(const UiPrefs(sunlight: true).palette, Palette.sunlight);
  });
}
