import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/widgets/direction_dial.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

Widget host(double angle, {UiPrefs prefs = const UiPrefs()}) => Directionality(
  textDirection: TextDirection.ltr,
  child: UiScope(
    prefs: prefs,
    child: Center(
      child: DirectionDial(
        angle: angle,
        color: const Color(0xFF5CC8E0),
        semanticsLabel: 'Fork 20 degrees right',
      ),
    ),
  ),
);

double turns(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(const Key('dial-arrow')))
    .transform
    .getRotation()
    .storage[1];

void main() {
  testWidgets('is 58 dp, or 112 dp when big', (tester) async {
    await tester.pumpWidget(host(0));
    expect(tester.getSize(find.byType(DirectionDial)), const Size(58, 58));
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: DirectionDial(
            angle: 0,
            color: Color(0xFF5CC8E0),
            semanticsLabel: 'x',
            big: true,
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(DirectionDial)), const Size(112, 112));
  });

  testWidgets('turns the short way: 350 to 10 passes through 0, not 180', (
    tester,
  ) async {
    await tester.pumpWidget(host(350));
    await tester.pump();
    await tester.pumpWidget(host(10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    final mid = tester
        .widget<Transform>(find.byKey(const Key('dial-arrow')))
        .transform;
    // the short way stays near 0 degrees (cos near +1); the long way would
    // swing through 180 degrees (cos near -1)
    expect(mid.getRotation().storage[0], greaterThan(0.9));
    await tester.pump(const Duration(milliseconds: 400));
    expect(turns(tester).abs(), greaterThan(0.1)); // settled at 10 degrees
  });

  testWidgets('with reduce motion it jumps instead of animating', (
    tester,
  ) async {
    await tester.pumpWidget(host(0, prefs: const UiPrefs(reduceMotion: true)));
    await tester.pumpWidget(host(90, prefs: const UiPrefs(reduceMotion: true)));
    await tester.pump();
    expect(turns(tester).abs(), closeTo(1, 0.01));
  });

  testWidgets('has a spoken label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(20));
    expect(
      tester.getSemantics(find.byType(DirectionDial)).label,
      'Fork 20 degrees right',
    );
    handle.dispose();
  });
}
