import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/widgets/hold_button.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

Widget host(
  Widget child, {
  UiPrefs prefs = const UiPrefs(),
  bool wideHost = true,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: UiScope(
    prefs: prefs,
    child: Center(
      child: wideHost ? SizedBox(width: 324, child: child) : child,
    ),
  ),
);

HoldButton wide({
  int secs = 3,
  VoidCallback? onComplete,
  void Function(int)? onTick,
}) => HoldButton.wide(
  label: 'Cancel SOS · hold 5 s',
  semanticsLabel: 'Cancel SOS, hold $secs seconds',
  icon: AppIcon.x,
  seconds: secs,
  color: const Color(0xFFFF3B30),
  onComplete: onComplete ?? () {},
  onTick: onTick,
);

void main() {
  testWidgets('completes only after the full hold time', (tester) async {
    var done = 0;
    await tester.pumpWidget(host(wide(onComplete: () => done++)));
    final g = await tester.startGesture(
      tester.getCenter(find.byType(HoldButton)),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2900));
    expect(done, 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(done, 1);
    await g.up();
  });

  testWidgets('releasing early does not complete and the fill springs back', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(host(wide(onComplete: () => done++)));
    final g = await tester.startGesture(
      tester.getCenter(find.byType(HoldButton)),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    final mid = tester
        .widget<FractionallySizedBox>(find.byKey(const Key('hold-fill')))
        .widthFactor!;
    expect(mid, closeTo(0.5, 0.05));
    await g.up();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(done, 0);
    expect(
      tester
          .widget<FractionallySizedBox>(find.byKey(const Key('hold-fill')))
          .widthFactor,
      0,
    );
  });

  testWidgets('a single tap never completes', (tester) async {
    var done = 0;
    await tester.pumpWidget(host(wide(onComplete: () => done++)));
    await tester.tap(find.byType(HoldButton));
    await tester.pump(const Duration(seconds: 6));
    expect(done, 0);
  });

  testWidgets('ticks once per second while holding, not at completion', (
    tester,
  ) async {
    final ticks = <int>[];
    await tester.pumpWidget(host(wide(onTick: ticks.add)));
    final g = await tester.startGesture(
      tester.getCenter(find.byType(HoldButton)),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(ticks, [1, 2]);
    await g.up();
  });

  testWidgets('completes once even if held longer', (tester) async {
    var done = 0;
    await tester.pumpWidget(host(wide(onComplete: () => done++)));
    final g = await tester.startGesture(
      tester.getCenter(find.byType(HoldButton)),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 4));
    expect(done, 1);
    await g.up();
  });

  testWidgets('can be held again after an early release', (tester) async {
    var done = 0;
    await tester.pumpWidget(host(wide(onComplete: () => done++)));
    var g = await tester.startGesture(
      tester.getCenter(find.byType(HoldButton)),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await g.up();
    await tester.pump(const Duration(seconds: 1));
    g = await tester.startGesture(tester.getCenter(find.byType(HoldButton)));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3100));
    expect(done, 1);
    await g.up();
  });

  testWidgets(
    'square variant completes the same way and keeps its square size',
    (tester) async {
      var done = 0;
      await tester.pumpWidget(
        host(
          HoldButton.square(
            label: 'SOS',
            sub: 'hold 3 s',
            semanticsLabel: 'SOS, hold 3 seconds',
            seconds: 3,
            color: const Color(0xFFFF3B30),
            onComplete: () => done++,
          ),
          wideHost: false,
        ),
      );
      expect(tester.getSize(find.byType(HoldButton)), const Size(80, 80));
      final g = await tester.startGesture(
        tester.getCenter(find.byType(HoldButton)),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3100));
      expect(done, 1);
      await g.up();
    },
  );

  testWidgets('glove mode scales the square variant 1.25x', (tester) async {
    await tester.pumpWidget(
      host(
        HoldButton.square(
          label: 'SOS',
          semanticsLabel: 'SOS',
          seconds: 3,
          color: const Color(0xFFFF3B30),
          onComplete: () {},
        ),
        prefs: const UiPrefs(glove: true),
        wideHost: false,
      ),
    );
    expect(tester.getSize(find.byType(HoldButton)), const Size(100, 100));
  });

  testWidgets('exposes button semantics with the spoken label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(wide()));
    expect(
      tester.getSemantics(find.byType(HoldButton)).label,
      'Cancel SOS, hold 3 seconds',
    );
    handle.dispose();
  });
}
