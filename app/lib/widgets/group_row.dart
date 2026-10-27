import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// How the group bar is coloured.
enum GroupTone {
  /// Everyone fine.
  ok,

  /// Something to watch (weak link, paused distances).
  warn,

  /// Regrouping: signal colour.
  regroup,
}

/// "Is my group OK?": count plus the single most important fact. A tappable
/// row that opens the radar.
class GroupRow extends StatelessWidget {
  /// Creates the row.
  const GroupRow({
    required this.main,
    required this.fact,
    required this.tone,
    required this.onTap,
    this.icon = AppIcon.people,
    super.key,
  });

  /// Count text, e.g. "4 of 4 in range".
  final String main;

  /// Most important group fact, e.g. "Rahul 60 m behind".
  final String fact;

  /// Colouring.
  final GroupTone tone;

  /// Opens the radar.
  final VoidCallback onTap;

  /// Leading icon.
  final AppIcon icon;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    final (Color fg, Color factColor, Color bg) = switch (tone) {
      GroupTone.ok => (p.text, p.text2, p.surface),
      GroupTone.warn => (p.warn, p.warn, p.surface),
      GroupTone.regroup => (p.signal, p.signal, p.tintSignal),
    };
    final iconColor = tone == GroupTone.ok ? p.ok : fg;
    return Semantics(
      button: true,
      label: '$main, $fact. Opens radar',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: prefs.target(56),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              top: BorderSide(color: p.hairline, width: p.lineScale),
            ),
          ),
          child: Row(
            children: [
              AppIconView(icon, color: iconColor),
              const SizedBox(width: 12),
              Text(
                main,
                style: TypeScale.body.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fact,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TypeScale.label.copyWith(color: factColor),
                ),
              ),
              const SizedBox(width: 8),
              AppIconView(
                AppIcon.chevron,
                color: tone == GroupTone.ok ? p.text2 : fg,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
