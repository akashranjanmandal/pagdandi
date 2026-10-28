import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/models/readiness.dart';
import 'package:pagdandi_app/models/route_summary.dart';
import 'package:pagdandi_app/routes/route_library.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/key_button.dart';
import 'package:pagdandi_app/widgets/screen_parts.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Before a trek there are two questions: am I ready, and start.
/// Rows show exactly what decides whether an SOS works; Start is disabled
/// and says why while a critical item is missing.
class BasecampScreen extends StatelessWidget {
  /// Creates the screen.
  const BasecampScreen({
    required this.readiness,
    this.onStart,
    this.onOpenTrek,
    this.onFix,
    this.onEmergencyCard,
    this.routes = const [],
    this.selectedRouteId,
    this.summary,
    this.onSelectRoute,
    super.key,
  });

  /// What is ready and what is not.
  final Readiness readiness;

  /// Start trek pressed (only reachable when [Readiness.canStart]).
  final VoidCallback? onStart;

  /// Open trek pressed (a trek is already running).
  final VoidCallback? onOpenTrek;

  /// The fix button of a row was pressed.
  final ValueChanged<ReadyItem>? onFix;

  /// Emergency card key pressed.
  final VoidCallback? onEmergencyCard;

  /// Routes the user can choose; none hides the route section.
  final List<RouteInfo> routes;

  /// The chosen route, or null for a free trek.
  final String? selectedRouteId;

  /// What to tell about the chosen route.
  final RouteSummary? summary;

  /// A route (or null = free trek) was chosen.
  final ValueChanged<String?>? onSelectRoute;

  static String _fixLabel(ReadyItem item) => switch (item) {
    ReadyItem.contacts => 'Add',
    ReadyItem.background => 'Check',
    ReadyItem.card => 'Fill',
    ReadyItem.location || ReadyItem.sms || ReadyItem.notifications => 'Allow',
  };

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    void noop() {}

    Widget row(ReadyRow r) {
      final (icon, color) = switch (r.status) {
        ReadyStatus.ok => (AppIcon.ok, p.ok),
        ReadyStatus.warn => (AppIcon.warn, p.warn),
        // Red is reserved for SOS itself; a missing item is told apart by its
        // octagon shape, its words and its place at the top.
        ReadyStatus.critical => (AppIcon.octagon, p.warn),
      };
      return Container(
        constraints: BoxConstraints(minHeight: prefs.target(60)),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: p.hairline, width: p.lineScale),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                container: true,
                label: '${r.label}: ${r.stateText}',
                excludeSemantics: true,
                child: Row(
                  children: [
                    AppIconView(icon, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.label,
                            style: TypeScale.body.copyWith(color: p.text),
                          ),
                          Text(
                            r.stateText,
                            style: TypeScale.label.copyWith(color: color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (r.status != ReadyStatus.ok)
              _FixButton(
                label: _fixLabel(r.id),
                onTap: () => onFix?.call(r.id),
              ),
          ],
        ),
      );
    }

    final running = readiness.showOpenTrek;
    return ScreenFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pagdandi',
                  style: TypeScale.display.copyWith(color: p.text),
                ),
                Text(
                  running ? 'Trek running' : 'Ready to trek?',
                  style: TypeScale.label.copyWith(color: p.text2),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!running && routes.isNotEmpty) ...[
                    _RouteSection(
                      routes: routes,
                      selectedId: selectedRouteId,
                      summary: summary,
                      onSelect: onSelectRoute,
                    ),
                  ],
                  if (!running) ...[
                    for (final r in readiness.rows) row(r),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last trek',
                            style: TypeScale.label.copyWith(color: p.text2),
                          ),
                          Text(
                            'None yet',
                            style: TypeScale.body.copyWith(color: p.text2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ThumbPanel(
            children: [
              if (running)
                KeyButton(
                  label: 'Open trek',
                  icon: AppIcon.arrow,
                  variant: KeyVariant.primary,
                  onPressed: onOpenTrek ?? noop,
                )
              else
                KeyButton(
                  label: 'Start trek',
                  sub: readiness.blockedReason,
                  icon: AppIcon.arrow,
                  variant: KeyVariant.primary,
                  enabled: readiness.canStart,
                  onPressed: onStart ?? noop,
                ),
              KeyButton(
                label: 'Emergency card',
                icon: AppIcon.card,
                onPressed: onEmergencyCard ?? noop,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FixButton extends StatelessWidget {
  const _FixButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            minWidth: prefs.target(56),
            minHeight: prefs.target(44),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: p.contour, width: p.lineScale),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, style: TypeScale.body.copyWith(color: p.text)),
        ),
      ),
    );
  }
}

class _RouteSection extends StatelessWidget {
  const _RouteSection({
    required this.routes,
    required this.selectedId,
    required this.summary,
    required this.onSelect,
  });

  final List<RouteInfo> routes;
  final String? selectedId;
  final RouteSummary? summary;
  final ValueChanged<String?>? onSelect;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;

    Widget option(String label, String? id) {
      final chosen = id == selectedId;
      return Semantics(
        button: true,
        selected: chosen,
        label: label,
        excludeSemantics: true,
        onTap: () => onSelect?.call(id),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect?.call(id),
          child: Container(
            constraints: BoxConstraints(minHeight: prefs.target(56)),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: p.hairline, width: p.lineScale),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: chosen
                      ? AppIconView(AppIcon.check, color: p.nav)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TypeScale.body.copyWith(
                      color: chosen ? p.text : p.text2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget line(String text, {Color? color}) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TypeScale.body.copyWith(color: color ?? p.text)),
    );

    final sum = summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
          child: Text('Route', style: TypeScale.label.copyWith(color: p.text2)),
        ),
        option('Free trek', null),
        for (final r in routes) option(r.name, r.id),
        if (sum != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line(
                  [
                    sum.lengthText,
                    ?sum.climbText,
                    ?sum.elevationText,
                  ].join(' · '),
                ),
                for (final pl in sum.places)
                  line('${pl.name} · ${pl.kmText}', color: p.text2),
                if (sum.sun != null) ...[
                  line(
                    'Sunrise ${sum.sun!.sunriseText} · '
                    'Sunset ${sum.sun!.sunsetText}',
                  ),
                  line(
                    'Suggested turn back by ${sum.sun!.turnBackText}, '
                    'so you are heading down well before dark.',
                    color: p.text2,
                  ),
                ],
                if (sum.winterNote != null)
                  line(sum.winterNote!, color: p.warn),
                Text(
                  'Route data: ${sum.attribution}',
                  style: TypeScale.caption.copyWith(color: p.text3),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
