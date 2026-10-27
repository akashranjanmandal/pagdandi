import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:path_drawing/path_drawing.dart';

/// Draws an [AppIcon] at [size] in [color] (2 px stroke on the 24 grid).
class AppIconView extends StatelessWidget {
  /// Creates an icon.
  const AppIconView(
    this.icon, {
    required this.color,
    this.size = 22,
    super.key,
  });

  /// Which icon.
  final AppIcon icon;

  /// Stroke or fill colour.
  final Color color;

  /// Edge length in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _IconPainter(icon, color)),
    ),
  );
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.icon, this.color);

  final AppIcon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..style = icon.filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final d in icon.paths) {
      canvas.drawPath(parseSvgPathData(d), paint);
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.icon != icon || old.color != color;
}
