import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// One number with its unit and caption.
@immutable
class Stat {
  /// Creates a stat.
  const Stat({required this.value, required this.unit, required this.caption});

  /// The number as text, e.g. "6.2".
  final String value;

  /// Unit, e.g. "km".
  final String unit;

  /// Caption, e.g. "distance".
  final String caption;
}

/// Three numbers about today's destination, headed "to camp".
class StatTriplet extends StatelessWidget {
  /// Creates a triplet.
  const StatTriplet({
    required this.header,
    required this.stats,
    this.paused = false,
    super.key,
  }) : assert(stats.length == 3, 'exactly three stats');

  /// Heading, e.g. "to camp".
  final String header;

  /// The three stats.
  final List<Stat> stats;

  /// Paused (stationary): numbers dim to the secondary colour.
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    final numColor = paused ? p.text2 : p.text;
    return Semantics(
      container: true,
      label:
          '$header: '
          '${stats.map((s) => '${s.value} ${s.unit} ${s.caption}').join(', ')}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: p.hairline, width: p.lineScale),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(header, style: TypeScale.caption.copyWith(color: p.text2)),
            const SizedBox(height: 6),
            IntrinsicHeight(
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) Container(width: p.lineScale, color: p.hairline),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: stats[i].value,
                                    style: TypeScale.hero.copyWith(
                                      fontSize: 26,
                                      color: numColor,
                                      height: 1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ${stats[i].unit}',
                                    style: TypeScale.label.copyWith(
                                      color: p.text2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stats[i].caption,
                              style: TypeScale.caption.copyWith(color: p.text2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
