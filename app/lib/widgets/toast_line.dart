import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// A received quick message: one line, sender in cyan. Not tappable.
class ToastLine extends StatelessWidget {
  /// Creates a toast.
  const ToastLine({required this.sender, required this.message, super.key});

  /// Who sent it.
  final String sender;

  /// The message.
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    return Semantics(
      liveRegion: true,
      label: '$sender says: $message',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: p.raised,
          border: Border(
            top: BorderSide(color: p.hairline, width: p.lineScale),
          ),
        ),
        child: Row(
          children: [
            AppIconView(AppIcon.send, color: p.text, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: sender,
                      style: TypeScale.body.copyWith(
                        color: p.nav,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: ' $message',
                      style: TypeScale.body.copyWith(
                        color: p.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
