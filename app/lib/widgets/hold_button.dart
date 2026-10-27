import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/motion.dart';
import 'package:pagdandi_app/design/shape.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/key_body.dart';
import 'package:pagdandi_app/widgets/key_style.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

enum _Shape { square, wide }

/// A key that must be held for [seconds] to act: protects dangerous or
/// irreversible actions from pockets, gloves and stumbles. Progress fills in
/// [color]; releasing early springs back; a single tap never completes.
class HoldButton extends StatefulWidget {
  /// Dock-size square key (80 dp) with a label and optional sub-line.
  const HoldButton.square({
    required this.label,
    required this.semanticsLabel,
    required this.seconds,
    required this.color,
    required this.onComplete,
    this.sub,
    this.onTick,
    super.key,
  }) : _shape = _Shape.square,
       icon = null;

  /// Full-width key with a leading icon.
  const HoldButton.wide({
    required this.label,
    required this.semanticsLabel,
    required this.seconds,
    required this.color,
    required this.onComplete,
    this.icon,
    this.onTick,
    super.key,
  }) : _shape = _Shape.wide,
       sub = null;

  final _Shape _shape;

  /// Visible text.
  final String label;

  /// Second line (square variant).
  final String? sub;

  /// Leading icon (wide variant).
  final AppIcon? icon;

  /// Spoken label, e.g. "SOS, hold 3 seconds".
  final String semanticsLabel;

  /// Hold time.
  final int seconds;

  /// Action colour: progress and icon.
  final Color color;

  /// Called once when the hold completes.
  final VoidCallback onComplete;

  /// Called with the elapsed whole second while holding (haptic tick).
  final void Function(int second)? onTick;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  int _lastTick = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c =
        AnimationController(
            vsync: this,
            duration: Duration(seconds: widget.seconds),
          )
          ..addListener(_onValue)
          ..addStatusListener(_onStatus);
  }

  void _onValue() {
    if (_c.status != AnimationStatus.forward) return;
    final s = (_c.value * widget.seconds).floor();
    // Emit every whole second reached, even if a slow frame skipped some.
    while (_lastTick < s && _lastTick + 1 < widget.seconds) {
      _lastTick++;
      widget.onTick?.call(_lastTick);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_done) {
      _done = true;
      setState(() {});
      widget.onComplete();
    }
  }

  void _down() {
    if (_done) return;
    _lastTick = 0;
    _c.forward();
  }

  void _up() {
    if (_done) return;
    _c.animateBack(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Motion.enter,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    final base = KeyStyle.neutral(p);
    final style = _done
        ? KeyStyle(
            face: widget.color,
            rim: widget.color,
            edge: base.edge,
            content: p.bg,
          )
        : base;
    final square = widget._shape == _Shape.square;
    final size = prefs.target(80);
    final radius = square ? Radii.hold : Radii.control;

    final Widget content = square
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: TypeScale.body.copyWith(
                    color: _done ? p.bg : widget.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.sub != null)
                  Text(
                    widget.sub!,
                    style: TypeScale.caption.copyWith(
                      color: _done ? p.bg : p.text2,
                    ),
                  ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  AppIconView(widget.icon!, color: _done ? p.bg : widget.color),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    style: TypeScale.body.copyWith(
                      color: _done ? p.bg : p.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );

    final progress = AnimatedBuilder(
      animation: _c,
      builder: (context, _) => square
          ? CustomPaint(
              painter: _OutlineProgress(
                value: _c.value,
                color: widget.color,
                track: p.text3,
                radius: radius - 5,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius - 1),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  key: const Key('hold-fill'),
                  widthFactor: _c.value,
                  heightFactor: 1,
                  child: ColoredBox(color: widget.color.withValues(alpha: 0.4)),
                ),
              ),
            ),
    );

    final body = KeyBody(
      height: square ? size : null,
      minHeight: square ? null : prefs.target(Targets.primary),
      style: style,
      radius: radius,
      pressed: false,
      child: square
          ? Stack(
              fit: StackFit.expand,
              children: [if (!_done) progress, content],
            )
          : Stack(
              children: [
                if (!_done) Positioned.fill(child: progress),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Align(alignment: Alignment.centerLeft, child: content),
                ),
              ],
            ),
    );

    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _down(),
        onPointerUp: (_) => _up(),
        onPointerCancel: (_) => _up(),
        child: square ? SizedBox(width: size, height: size, child: body) : body,
      ),
    );
  }
}

/// Draws a rounded-square outline progress, clockwise from the top.
class _OutlineProgress extends CustomPainter {
  _OutlineProgress({
    required this.value,
    required this.color,
    required this.track,
    required this.radius,
  });

  final double value;
  final Color color;
  final Color track;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 5.0;
    const l = inset;
    const t = inset;
    final r = size.width - inset;
    final b = size.height - inset;
    final rr = radius;
    final path = Path()
      ..moveTo(l + rr, t)
      ..lineTo(r - rr, t)
      ..arcToPoint(Offset(r, t + rr), radius: Radius.circular(rr))
      ..lineTo(r, b - rr)
      ..arcToPoint(Offset(r - rr, b), radius: Radius.circular(rr))
      ..lineTo(l + rr, b)
      ..arcToPoint(Offset(l, b - rr), radius: Radius.circular(rr))
      ..lineTo(l, t + rr)
      ..arcToPoint(Offset(l + rr, t), radius: Radius.circular(rr))
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = track.withValues(alpha: 0.5),
    );
    if (value <= 0) return;
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * value),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_OutlineProgress old) =>
      old.value != value || old.color != color || old.track != track;
}
