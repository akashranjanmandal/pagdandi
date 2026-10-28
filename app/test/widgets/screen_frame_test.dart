import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/widgets/screen_parts.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

Widget host({required double keyboard}) => MediaQuery(
  data: MediaQueryData(
    size: const Size(360, 780),
    viewInsets: EdgeInsets.only(bottom: keyboard),
  ),
  child: const Directionality(
    textDirection: TextDirection.ltr,
    child: UiScope(
      prefs: UiPrefs(),
      child: ScreenFrame(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(key: Key('bottom'), height: 50, width: 50),
        ),
      ),
    ),
  ),
);

Future<void> phone(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(360, 780)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('content ends above the keyboard so bottom keys stay visible', (
    tester,
  ) async {
    await phone(tester);
    await tester.pumpWidget(host(keyboard: 300));
    final bottom = tester.getBottomLeft(find.byKey(const Key('bottom'))).dy;
    expect(bottom, lessThanOrEqualTo(780 - 300));
  });

  testWidgets('without a keyboard the content reaches the bottom', (
    tester,
  ) async {
    await phone(tester);
    await tester.pumpWidget(host(keyboard: 0));
    final bottom = tester.getBottomLeft(find.byKey(const Key('bottom'))).dy;
    expect(bottom, 780);
  });
}
