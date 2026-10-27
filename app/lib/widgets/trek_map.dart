import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/motion.dart';
import 'package:pagdandi_app/design/palette.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/models/map_scene.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';
import 'package:path_drawing/path_drawing.dart';

/// Offline trek map: contours, planned route, breadcrumb, friends, you.
/// One-finger pan; recenters on you after [recenterAfter] of no touch.
/// Draws sample geometry for now; real tiles replace the painter later.
class TrekMap extends StatefulWidget {
  /// Creates the map for [nav].
  const TrekMap({
    required this.nav,
    required this.altitude,
    this.uncertaintyRadius = 14,
    this.recenterAfter = const Duration(seconds: 8),
    super.key,
  });

  /// State to draw.
  final NavState nav;

  /// Altitude caption, e.g. "3,214 m".
  final String altitude;

  /// Radius of the uncertainty circle while GPS is lost.
  final double uncertaintyRadius;

  /// Idle time before the map recenters.
  final Duration recenterAfter;

  @override
  State<TrekMap> createState() => _TrekMapState();
}

class _TrekMapState extends State<TrekMap> with SingleTickerProviderStateMixin {
  Offset _pan = Offset.zero;
  Timer? _timer;
  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );
  Offset _from = Offset.zero;

  @override
  void initState() {
    super.initState();
    _back.addListener(() {
      setState(() {
        _pan = Offset.lerp(
          _from,
          Offset.zero,
          Motion.enter.transform(_back.value),
        )!;
      });
    });
  }

  void _scheduleRecenter() {
    _timer?.cancel();
    _timer = Timer(widget.recenterAfter, () {
      _from = _pan;
      if (UiScope.of(context).reduceMotion) {
        setState(() => _pan = Offset.zero);
      } else {
        _back.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    final scene = MapScene.of(widget.nav);
    return Semantics(
      label: 'Offline map. Drag to pan; it recenters after 8 seconds.',
      container: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          _timer?.cancel();
          _back.stop();
        },
        onPanUpdate: (d) => setState(() => _pan += d.delta),
        onPanEnd: (_) => _scheduleRecenter(),
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _MapPainter(scene, p, _pan, widget.uncertaintyRadius),
              ),
              if (scene.pulse) _Pulse(color: p.signal, offset: _pan),
              Positioned(
                right: 18,
                bottom: 8,
                child: Text(
                  widget.altitude,
                  style: TypeScale.caption.copyWith(color: p.text2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Beacon pulse around your marker: live, so it animates.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.color, required this.offset});

  final Color color;
  final Offset offset;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (UiScope.of(context).reduceMotion) {
      _c.value = 0.35;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => CustomPaint(
      painter: _PulsePainter(widget.color, _c.value, widget.offset),
    ),
  );
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.color, this.t, this.offset);

  final Color color;
  final double t;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero) + offset,
      9 + 20 * t,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.9 * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t || old.offset != offset;
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.scene, this.p, this.pan, this.uncertainty);

  final MapScene scene;
  final Palette p;
  final Offset pan;
  final double uncertainty;

  static Path _ring(double cx, double cy, double r, double k, double ax) {
    final path = Path();
    for (var t = 0; t <= 360; t += 10) {
      final a = t * math.pi / 180;
      final n = 1 + .07 * math.sin(3 * a + k) + .04 * math.sin(5 * a + 2 * k);
      final x = math.cos(a) * r * ax * n;
      final y = math.sin(a) * r * n;
      const rot = -.35;
      final px = cx + x * math.cos(rot) - y * math.sin(rot);
      final py = cy + x * math.sin(rot) + y * math.cos(rot);
      if (t == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..clipRect(Offset.zero & size)
      ..translate(
        size.width / 2 - scene.you.dx + pan.dx,
        size.height / 2 - scene.you.dy + pan.dy,
      );
    final w = p.lineScale;

    // contours: rings around two peaks
    for (var i = 1; i <= 13; i++) {
      canvas.drawPath(
        _ring(430, 140, i * 26.0, i.toDouble(), 1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (i % 5 == 0 ? 2.4 : 1.4) * (w > 1 ? 1.5 : 1)
          ..color = p.contour,
      );
    }
    for (var i = 1; i <= 9; i++) {
      canvas.drawPath(
        _ring(110, 330, i * 24.0, i + 3.0, 1.3),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (i % 5 == 0 ? 2.4 : 1.4) * (w > 1 ? 1.5 : 1)
          ..color = p.contour,
      );
    }

    // the branch: grey, or dotted warn when you took it
    if (scene.takenBranch) {
      _dots(canvas, scene.branch, 0, double.infinity, 8, p.warn, 3);
    } else {
      canvas.drawPath(
        scene.branch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..color = p.text3,
      );
    }
    // planned route
    canvas.drawPath(
      scene.route,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = p.nav,
    );
    // breadcrumb
    final dot = Paint()..color = p.text2.withValues(alpha: .6);
    for (var i = 0; i < scene.breadcrumb.length; i++) {
      canvas.drawCircle(scene.breadcrumb[i], 1.5, dot);
    }
    // junction node
    final j = scene.junction;
    if (scene.showJunctionHighlight) {
      canvas
        ..drawCircle(
          j,
          16,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = p.nav,
        )
        ..drawCircle(j, 8, Paint()..color = p.bg)
        ..drawCircle(
          j,
          8,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = p.nav,
        );
    } else {
      canvas
        ..drawCircle(j, 6, Paint()..color = p.bg)
        ..drawCircle(
          j,
          6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = p.text2,
        );
    }
    // friends
    for (final f in scene.friends) {
      canvas.drawCircle(f.pos, 13, Paint()..color = p.bg);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = f.outOfRange ? p.text3 : p.ok;
      if (f.outOfRange) {
        _dashedCircle(canvas, f.pos, 13, ring);
      } else {
        canvas.drawCircle(f.pos, 13, ring);
      }
      final tp = TextPainter(
        text: TextSpan(
          text: f.initials,
          style: TypeScale.label.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: f.outOfRange ? p.text2 : p.text,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, f.pos - Offset(tp.width / 2, tp.height / 2));
    }
    // you
    final you = scene.you;
    if (scene.hollowYou) {
      _dashedCircle(
        canvas,
        you,
        uncertainty,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = p.signal,
      );
      canvas.drawCircle(
        you,
        8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = p.signal,
      );
    } else {
      canvas.save();
      canvas.translate(you.dx, you.dy);
      canvas.rotate(scene.headingDeg * math.pi / 180);
      canvas.drawPath(
        parseSvgPathData('M0 0 L-16 -34 A38 38 0 0 1 16 -34 Z'),
        Paint()..color = p.signal.withValues(alpha: .28),
      );
      canvas.restore();
      canvas
        ..drawCircle(you, 9, Paint()..color = p.signal)
        ..drawCircle(
          you,
          9,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = p.bg,
        );
    }
  }

  void _dashedCircle(Canvas canvas, Offset c, double r, Paint paint) {
    const dash = 3.0;
    const gap = 4.0;
    final circ = 2 * math.pi * r;
    final n = (circ / (dash + gap)).floor();
    for (var i = 0; i < n; i++) {
      final a0 = i * (dash + gap) / r;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a0,
        dash / r,
        false,
        paint,
      );
    }
  }

  void _dots(
    Canvas canvas,
    Path path,
    double from,
    double to,
    double step,
    Color c,
    double r,
  ) {
    final m = path.computeMetrics().first;
    final paint = Paint()..color = c;
    for (var l = from; l <= math.min(to, m.length); l += step) {
      canvas.drawCircle(m.getTangentForOffset(l)!.position, r / 2 + .5, paint);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.scene != scene ||
      old.p != p ||
      old.pan != pan ||
      old.uncertainty != uncertainty;
}
