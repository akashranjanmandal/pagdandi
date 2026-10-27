import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/key_body.dart';
import 'package:pagdandi_app/widgets/key_style.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// The giant "I'm OK" key: the safe action must be the easiest, so a single
/// tap anywhere on it cancels.
class OkKey extends StatefulWidget {
  /// Creates the key.
  const OkKey({required this.onPressed, super.key});

  /// Cancels the countdown.
  final VoidCallback onPressed;

  @override
  State<OkKey> createState() => _OkKeyState();
}

class _OkKeyState extends State<OkKey> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    final style = KeyStyle.ok(p);
    return Semantics(
      button: true,
      label: "I'm OK. Cancel the SOS",
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onPressed,
        child: KeyBody(
          style: style,
          radius: 24,
          edge: 8,
          pressed: _down,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIconView(AppIcon.check, color: style.content, size: 56),
              const SizedBox(height: 6),
              Text(
                'I’m OK',
                style: TypeScale.display.copyWith(color: style.content),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
