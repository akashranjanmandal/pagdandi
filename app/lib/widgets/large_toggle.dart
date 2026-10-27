import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/shape.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/key_body.dart';
import 'package:pagdandi_app/widgets/key_style.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Torch and Siren: a key with a status lamp. On = orange fill + the word
/// "On" + icon (never colour alone). 88 dp tall, scaled in glove mode.
class LargeToggle extends StatefulWidget {
  /// Creates a toggle.
  const LargeToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Icon.
  final AppIcon icon;

  /// Name, e.g. "Siren".
  final String label;

  /// Whether it is on.
  final bool value;

  /// Asks for a new value.
  final ValueChanged<bool> onChanged;

  @override
  State<LargeToggle> createState() => _LargeToggleState();
}

class _LargeToggleState extends State<LargeToggle> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    final on = widget.value;
    final style = on ? KeyStyle.signal(p) : KeyStyle.neutral(p);
    return Semantics(
      button: true,
      toggled: on,
      label: widget.label,
      excludeSemantics: true,
      onTap: () => widget.onChanged(!on),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: () => widget.onChanged(!on),
        child: KeyBody(
          minHeight: prefs.target(88),
          style: style,
          radius: Radii.control,
          pressed: _down,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppIconView(widget.icon, color: style.content, size: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: TypeScale.body.copyWith(
                            color: style.content,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          on ? 'On' : 'Off',
                          style: TypeScale.label.copyWith(
                            color: on ? p.bg : p.text2,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? p.bg : null,
                    border: Border.all(color: on ? p.bg : p.text3, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
