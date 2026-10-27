import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/sos_colour.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Large number inside a draining ring: the 60 s before an SOS goes out.
/// The ring is red by design decision (final seconds before SOS).
class CountdownRing extends StatelessWidget {
  /// Creates the ring showing [secondsLeft] of [totalSeconds].
  const CountdownRing({
    required this.secondsLeft,
    this.totalSeconds = 60,
    this.size = 176,
    super.key,
  });

  /// Whole seconds remaining.
  final int secondsLeft;

  /// Length of the whole countdown.
  final int totalSeconds;

  /// Edge length.
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    return Semantics(
      label: 'Sending SOS in $secondsLeft seconds',
      liveRegion: false,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                fraction: (secondsLeft / totalSeconds).clamp(0, 1).toDouble(),
                color: sosColour(p),
                track: p.hairline,
              ),
            ),
            Text(
              '$secondsLeft',
              style: TypeScale.display.copyWith(
                fontSize: 72,
                color: p.text,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(8);
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = track,
    );
    canvas.drawArc(
      r,
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.butt
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}
