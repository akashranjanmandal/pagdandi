import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/models/sos_delivery.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// One line of a status checklist: what the app is doing, in plain words.
class ChecklistRow {
  /// Creates a row.
  const ChecklistRow({
    required this.icon,
    required this.label,
    required this.status,
    required this.state,
  });

  /// Icon (replaced by a live pulse when [state] is [RowState.live]).
  final AppIcon icon;

  /// Sentence a scared person can read aloud.
  final String label;

  /// Status word.
  final String status;

  /// Colouring and pulse.
  final RowState state;
}

/// StatusChecklist: live rows with icon, words and state.
class StatusChecklist extends StatelessWidget {
  /// Creates a checklist.
  const StatusChecklist({required this.rows, this.rowHeight = 52, super.key});

  /// Rows.
  final List<ChecklistRow> rows;

  /// Minimum row height before glove scaling.
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    return Column(
      children: [
        for (final r in rows)
          Semantics(
            container: true,
            label: '${r.label}: ${r.status}',
            excludeSemantics: true,
            child: Container(
              constraints: BoxConstraints(minHeight: prefs.target(rowHeight)),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: p.hairline, width: p.lineScale),
                ),
              ),
              child: Row(
                children: [
                  if (r.state == RowState.live)
                    _PulseDot(color: p.signal, live: !prefs.reduceMotion)
                  else
                    AppIconView(r.icon, color: p.text),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      r.label,
                      style: TypeScale.body.copyWith(color: p.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    r.status,
                    textAlign: TextAlign.right,
                    style: TypeScale.label.copyWith(
                      color: switch (r.state) {
                        RowState.done => p.ok,
                        RowState.live => p.signal,
                        RowState.wait => p.warn,
                        RowState.off => p.text2,
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The beacon dot: the only thing in an emergency allowed to pulse.
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color, required this.live});

  final Color color;
  final bool live;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.live) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 22,
    height: 22,
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        painter: _PulsePainter(widget.color, widget.live ? _c.value : 0),
      ),
    ),
  );
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.color, this.t);

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, 5, Paint()..color = color);
    if (t > 0) {
      canvas.drawCircle(
        c,
        5 + 6 * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.9 * (1 - t)),
      );
    }
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t || old.color != color;
}
