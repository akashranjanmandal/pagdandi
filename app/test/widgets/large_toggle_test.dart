import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/widgets/large_toggle.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

Widget host(Widget child, {UiPrefs prefs = const UiPrefs()}) => Directionality(
  textDirection: TextDirection.ltr,
  child: UiScope(
    prefs: prefs,
    child: Center(child: SizedBox(width: 156, child: child)),
  ),
);

void main() {
  testWidgets('tapping asks for the opposite value', (tester) async {
    bool? asked;
    await tester.pumpWidget(
      host(
        LargeToggle(
          icon: AppIcon.siren,
          label: 'Siren',
          value: false,
          onChanged: (v) => asked = v,
        ),
      ),
    );
    await tester.tap(find.byType(LargeToggle));
    expect(asked, isTrue);
  });

  testWidgets('shows the state in words, not colour alone', (tester) async {
    await tester.pumpWidget(
      host(
        LargeToggle(
          icon: AppIcon.siren,
          label: 'Siren',
          value: false,
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Off'), findsOneWidget);
    await tester.pumpWidget(
      host(
        LargeToggle(
          icon: AppIcon.siren,
          label: 'Siren',
          value: true,
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('On'), findsOneWidget);
  });

  testWidgets('is at least 72 dp tall and exposes toggled semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        LargeToggle(
          icon: AppIcon.torch,
          label: 'Torch strobe',
          value: true,
          onChanged: (_) {},
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(LargeToggle)).height,
      greaterThanOrEqualTo(72),
    );
    final node = tester.getSemantics(find.byType(LargeToggle));
    expect(node.label, 'Torch strobe');
    expect(
      node.getSemanticsData().flagsCollection.isToggled.toBoolOrNull(),
      isTrue,
    );
    handle.dispose();
  });
}
