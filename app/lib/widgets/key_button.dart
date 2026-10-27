import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/shape.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/key_body.dart';
import 'package:pagdandi_app/widgets/key_style.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Which key look to use.
enum KeyVariant {
  /// Secondary action: neutral key.
  neutral,

  /// Primary action: orange key, one per screen.
  primary,
}

/// A full-width key with an optional icon and sub-line. At least 72 dp tall
/// (56 compact),
/// scaled 1.25x in glove mode.
class KeyButton extends StatefulWidget {
  /// Creates a key button.
  const KeyButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.sub,
    this.variant = KeyVariant.neutral,
    this.enabled = true,
    this.compact = false,
    this.iconColor,
    super.key,
  });

  /// Main text.
  final String label;

  /// Optional second line (e.g. why a key is disabled).
  final String? sub;

  /// Leading icon.
  final AppIcon? icon;

  /// Tap callback.
  final VoidCallback onPressed;

  /// Look.
  final KeyVariant variant;

  /// Disabled keys are dashed, flat and explain themselves via [sub].
  final bool enabled;

  /// 56 dp instead of 72 dp.
  final bool compact;

  /// Overrides the icon colour (colour lives on the icon, not on outlines).
  final Color? iconColor;

  @override
  State<KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<KeyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    final style = !widget.enabled
        ? KeyStyle(face: p.bg, rim: p.text3, edge: p.bg, content: p.text2)
        : widget.variant == KeyVariant.primary
        ? KeyStyle.signal(p)
        : KeyStyle.neutral(p);
    final height = prefs.target(widget.compact ? Targets.min : Targets.primary);
    final iconColor = widget.iconColor ?? style.content;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      hint: widget.enabled ? null : widget.sub,
      onTap: widget.enabled ? widget.onPressed : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _down = false)
            : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: KeyBody(
          minHeight: height,
          style: style,
          radius: Radii.control,
          pressed: _down,
          dashed: !widget.enabled,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  AppIconView(widget.icon!, color: iconColor),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: widget.icon == null
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TypeScale.body.copyWith(
                          color: style.content,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.sub != null)
                        Text(
                          widget.sub!,
                          style: TypeScale.label.copyWith(color: p.text2),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
