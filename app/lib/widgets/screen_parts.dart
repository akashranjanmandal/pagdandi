import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Black full-screen frame with the status-bar inset.
class ScreenFrame extends StatelessWidget {
  /// Creates a frame.
  const ScreenFrame({required this.child, super.key});

  /// Content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    return ColoredBox(
      color: p.bg,
      child: SafeArea(child: child),
    );
  }
}

/// Top strip: GPS accuracy, status tag, battery. Display only.
class GlanceStrip extends StatelessWidget {
  /// Creates a strip.
  const GlanceStrip({
    required this.accuracy,
    required this.tag,
    required this.battery,
    required this.tint,
    this.child,
    super.key,
  });

  /// e.g. "GPS ±6 m".
  final String accuracy;

  /// The status tag.
  final Widget tag;

  /// Battery percent.
  final int battery;

  /// Background tint for the state.
  final Color tint;

  /// Extra content under the row (dial, hero, numbers).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    // The glance zone is display-only and truncates before controls give way.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: BoxDecoration(
          color: tint,
          border: Border(
            bottom: BorderSide(color: p.hairline, width: p.lineScale),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  accuracy,
                  style: TypeScale.caption.copyWith(color: p.text2),
                ),
                tag,
                Row(
                  children: [
                    AppIconView(AppIcon.battery, color: p.text2, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$battery%',
                      style: TypeScale.caption.copyWith(color: p.text2),
                    ),
                  ],
                ),
              ],
            ),
            if (child != null) ...[const SizedBox(height: 12), child!],
          ],
        ),
      ),
    );
  }
}

/// Emergency headline in display size with a primary-text sub-line (AAA).
class BigInstruction extends StatelessWidget {
  /// Creates the instruction.
  const BigInstruction({
    required this.title,
    required this.sub,
    this.hero = false,
    super.key,
  });

  /// Headline.
  final String title;

  /// Line under it.
  final String sub;

  /// Hero size instead of display (SOS screen, where coordinates take the
  /// display slot).
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title. $sub',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: (hero ? TypeScale.hero : TypeScale.display).copyWith(
                color: p.text,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(sub, style: TypeScale.body.copyWith(color: p.text)),
          ],
        ),
      ),
    );
  }
}

/// The thumb zone: a surface panel the keys sit on.
class ThumbPanel extends StatelessWidget {
  /// Creates a panel.
  const ThumbPanel({required this.children, super.key});

  /// Controls, top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(
          top: BorderSide(color: p.hairline, width: p.lineScale),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: prefs.space(12)),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Dims the screen behind a bottom sheet.
class Scrim extends StatelessWidget {
  /// Creates a scrim.
  const Scrim({super.key});

  @override
  Widget build(BuildContext context) =>
      const Positioned.fill(child: ColoredBox(color: Color(0xB3000000)));
}

/// Bottom sheet container.
class SheetPanel extends StatelessWidget {
  /// Creates a sheet.
  const SheetPanel({required this.title, required this.children, super.key});

  /// Title.
  final String title;

  /// Content.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: p.hairline, width: 2)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: TypeScale.title.copyWith(color: p.text)),
              SizedBox(height: prefs.space(12)),
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: prefs.space(12)),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
