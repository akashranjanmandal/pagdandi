import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/motion.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Circle with an arrow (or a glyph). Turns the shortest way with a stiff
/// 320 ms spring-like curve and no overshoot. 58 dp, or 112 dp when [big].
class DirectionDial extends StatefulWidget {
  /// Creates a dial pointing [angle] degrees from straight ahead.
  const DirectionDial({
    required this.angle,
    required this.color,
    required this.semanticsLabel,
    this.big = false,
    this.glyph,
    super.key,
  });

  /// Direction in degrees, 0 = ahead, positive clockwise.
  final double angle;

  /// State colour (ring and arrow).
  final Color color;

  /// Spoken description, e.g. "Fork in 80 metres, keep left".
  final String semanticsLabel;

  /// 112 dp with bearing ticks (emergency screens).
  final bool big;

  /// Shows this glyph instead of an arrow (U-turn, GPS lost).
  final AppIcon? glyph;

  @override
  State<DirectionDial> createState() => _DirectionDialState();
}

class _DirectionDialState extends State<DirectionDial> {
  late double _angle = widget.angle;

  @override
  void didUpdateWidget(DirectionDial old) {
    super.didUpdateWidget(old);
    if (old.angle != widget.angle) _angle = nextRotation(_angle, widget.angle);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = UiScope.of(context).reduceMotion;
    final size = widget.big ? 112.0 : 58.0;
    return Semantics(
      label: widget.semanticsLabel,
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color, width: 2),
              ),
              child: const SizedBox.expand(),
            ),
            if (widget.big)
              CustomPaint(
                size: Size(size, size),
                painter: _TickPainter(widget.color),
              ),
            if (widget.glyph != null)
              AppIconView(widget.glyph!, color: widget.color, size: size * 0.55)
            else
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: _angle),
                duration: reduce ? Duration.zero : Motion.slow,
                curve: Motion.enter,
                builder: (context, deg, child) => Transform(
                  key: const Key('dial-arrow'),
                  alignment: Alignment.center,
                  transform: Matrix4.rotationZ(deg * math.pi / 180),
                  child: child,
                ),
                child: AppIconView(
                  AppIcon.arrow,
                  color: widget.color,
                  size: size * (widget.big ? 0.5 : 0.56),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bearing scale: ticks every 30 degrees, longer at N, E, S, W.
class _TickPainter extends CustomPainter {
  _TickPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2 - 2;
    for (var i = 0; i < 360; i += 30) {
      final major = i % 90 == 0;
      final a = i * math.pi / 180;
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(
        c + dir * outer,
        c + dir * (outer - (major ? 9 : 5)),
        Paint()
          ..color = color.withValues(alpha: major ? 0.9 : 0.4)
          ..strokeWidth = major ? 2 : 1,
      );
    }
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.color != color;
}
