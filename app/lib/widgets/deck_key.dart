import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/shape.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/key_body.dart';
import 'package:pagdandi_app/widgets/key_style.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Square 80 dp neutral key with an icon over a label (the Pin key).
class DeckKey extends StatefulWidget {
  /// Creates the key.
  const DeckKey({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// Icon.
  final AppIcon icon;

  /// Label.
  final String label;

  /// Tap.
  final VoidCallback onPressed;

  @override
  State<DeckKey> createState() => _DeckKeyState();
}

class _DeckKeyState extends State<DeckKey> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final style = KeyStyle.neutral(prefs.palette);
    final size = prefs.target(80);
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: KeyBody(
            style: style,
            radius: Radii.hold,
            pressed: _down,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIconView(widget.icon, color: style.content, size: 26),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: TypeScale.body.copyWith(
                    color: style.content,
                    fontWeight: FontWeight.w500,
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
