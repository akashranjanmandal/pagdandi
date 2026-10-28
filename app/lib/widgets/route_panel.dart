import 'package:core_geo/core_geo.dart';
import 'package:engine_navigation/engine_navigation.dart';
import 'package:flutter/widgets.dart' hide Route;
import 'package:pagdandi_app/design/palette.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:pagdandi_app/models/route_scene.dart';
import 'package:pagdandi_app/widgets/nav_style.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// The real route on screen: the trail (done part bright), named places, the
/// walker and an elevation profile. North is up. Replaced by offline map
/// tiles later; until then this is drawn from the route file alone.
class RoutePanel extends StatelessWidget {
  /// Creates the panel.
  const RoutePanel({
    required this.route,
    required this.state,
    required this.progressM,
    this.me,
    super.key,
  });

  /// The trail.
  final Route route;

  /// Drives the colour of the walked part.
  final NavState state;

  /// Metres walked along the route.
  final double progressM;

  /// Where the walker is, if known.
  final GeoPoint? me;

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    final km = (progressM / 1000).toStringAsFixed(1);
    final total = (route.totalM / 1000).toStringAsFixed(1);
    return Semantics(
      container: true,
      label:
          'Route map, north is up. $km of $total kilometres walked. '
          '${route.checkpoints.length} named places.',
      excludeSemantics: true,
      child: ColoredBox(
        color: p.bg,
        child: LayoutBuilder(
          builder: (context, c) {
            final profileH = route.hasElevation ? c.maxHeight * 0.26 : 0.0;
            final mapH = c.maxHeight - profileH;
            final scene = RouteScene.of(
              route,
              aspect: c.maxWidth / (mapH <= 0 ? 1 : mapH),
              progressM: progressM,
              me: me,
            );
            return Column(
              children: [
                SizedBox(
                  height: mapH,
                  width: c.maxWidth,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MapPainter(scene, p, state.color(p)),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 4,
                        child: Text(
                          '© OpenStreetMap contributors',
                          style: TypeScale.caption.copyWith(
                            color: p.text3,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (route.hasElevation)
                  SizedBox(
                    height: profileH,
                    width: c.maxWidth,
                    child: CustomPaint(
                      painter: _ProfilePainter(scene, p, state.color(p)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

TextPainter _label(String text, Color color, {double size = 11}) => TextPainter(
  text: TextSpan(
    text: text,
    style: TypeScale.caption.copyWith(color: color, fontSize: size),
  ),
  textDirection: TextDirection.ltr,
  maxLines: 1,
)..layout();

class _MapPainter extends CustomPainter {
  _MapPainter(this.scene, this.p, this.done);

  final RouteScene scene;
  final Palette p;
  final Color done;

  @override
  void paint(Canvas canvas, Size size) {
    Offset px(Offset o) => Offset(o.dx * size.height, o.dy * size.height);
    final ahead = Paint()
      ..color = p.text3
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final walked = Paint()
      ..color = done
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Path path(int from, int to) {
      final pa = Path()
        ..moveTo(px(scene.line[from]).dx, px(scene.line[from]).dy);
      for (var i = from + 1; i <= to; i++) {
        pa.lineTo(px(scene.line[i]).dx, px(scene.line[i]).dy);
      }
      return pa;
    }

    canvas.drawPath(path(0, scene.line.length - 1), ahead);
    if (scene.doneUntil > 0) canvas.drawPath(path(0, scene.doneUntil), walked);

    // Named places: a ring, passed ones filled; the name beside it.
    for (final c in scene.checkpoints) {
      final o = px(c.at);
      canvas
        ..drawCircle(o, 6, Paint()..color = p.bg)
        ..drawCircle(
          o,
          6,
          Paint()
            ..color = c.passed ? done : p.text2
            ..style = c.passed ? PaintingStyle.fill : PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      final short = c.name.replaceAll(RegExp(r'\s*\(.*\)\s*$'), '');
      final tp = _label(short, p.text);
      final onRight = o.dx < size.width / 2;
      tp.paint(
        canvas,
        Offset(
          onRight ? o.dx + 10 : o.dx - 10 - tp.width,
          o.dy - tp.height / 2,
        ),
      );
    }

    final me = scene.me;
    if (me != null) {
      final o = px(me);
      canvas
        ..drawCircle(o, 11, Paint()..color = p.signal.withValues(alpha: 0.25))
        ..drawCircle(o, 6, Paint()..color = p.signal)
        ..drawCircle(
          o,
          6,
          Paint()
            ..color = p.bg
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.scene != scene || old.p != p || old.done != done;
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter(this.scene, this.p, this.done);

  final RouteScene scene;
  final Palette p;
  final Color done;

  @override
  void paint(Canvas canvas, Size size) {
    if (!scene.hasProfile) return;
    const padX = 12.0;
    const padTop = 16.0;
    const padBottom = 6.0;
    final w = size.width - 2 * padX;
    final h = size.height - padTop - padBottom;
    Offset at(Offset o) => Offset(padX + o.dx * w, padTop + o.dy * h);

    canvas.drawLine(
      Offset.zero,
      Offset(size.width, 0),
      Paint()
        ..color = p.hairline
        ..strokeWidth = p.lineScale,
    );

    final area = Path()..moveTo(at(scene.profile.first).dx, padTop + h);
    for (final o in scene.profile) {
      area.lineTo(at(o).dx, at(o).dy);
    }
    area
      ..lineTo(at(scene.profile.last).dx, padTop + h)
      ..close();
    canvas.drawPath(area, Paint()..color = p.surface);

    final line = Path()
      ..moveTo(at(scene.profile.first).dx, at(scene.profile.first).dy);
    for (final o in scene.profile.skip(1)) {
      line.lineTo(at(o).dx, at(o).dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = p.text3
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final me = scene.profileMe;
    if (me != null) {
      final walked = Path()
        ..moveTo(at(scene.profile.first).dx, at(scene.profile.first).dy);
      for (final o in scene.profile.skip(1)) {
        if (o.dx > me.dx) break;
        walked.lineTo(at(o).dx, at(o).dy);
      }
      walked.lineTo(at(me).dx, at(me).dy);
      canvas
        ..drawPath(
          walked,
          Paint()
            ..color = done
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        )
        ..drawCircle(at(me), 5, Paint()..color = p.signal);
    }

    String m(double e) {
      final digits = e.round().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
      return '$digits m';
    }

    final start = _label(m(scene.startEle), p.text2, size: 10);
    final end = _label(m(scene.endEle), p.text2, size: 10);
    final top = _label('highest ${m(scene.maxEle)}', p.text2, size: 10);
    start.paint(canvas, const Offset(padX, 2));
    end.paint(canvas, Offset(size.width - padX - end.width, 2));
    top.paint(canvas, Offset((size.width - top.width) / 2, 2));
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.scene != scene || old.p != p || old.done != done;
}
