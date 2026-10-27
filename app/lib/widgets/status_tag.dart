import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/shape.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Icon + word + colour: the state is never colour alone.
class StatusTag extends StatelessWidget {
  /// Creates a tag.
  const StatusTag({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });

  /// Distinct shape.
  final AppIcon icon;

  /// Word.
  final String label;

  /// Colour of border, icon and text.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = UiScope.of(context).palette.lineScale;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        height: 28,
        padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.chip),
          border: Border.all(color: color, width: width),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconView(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TypeScale.label.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
