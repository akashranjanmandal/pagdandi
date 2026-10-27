import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Phone-sized (360 x 780 dp) host for screen golden tests.
Future<void> pumpPhone(
  WidgetTester tester,
  Widget screen, {
  UiPrefs prefs = const UiPrefs(reduceMotion: true),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = const Size(720, 1560)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: const Size(360, 780),
        padding: const EdgeInsets.only(top: 24),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: UiScope(prefs: prefs, child: screen),
      ),
    ),
  );
  await tester.pump();
}
