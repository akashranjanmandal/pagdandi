import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/sos_colour.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/models/active_trek_view.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:pagdandi_app/screens/trek_actions.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/deck_key.dart';
import 'package:pagdandi_app/widgets/direction_dial.dart';
import 'package:pagdandi_app/widgets/group_row.dart';
import 'package:pagdandi_app/widgets/hold_button.dart';
import 'package:pagdandi_app/widgets/key_button.dart';
import 'package:pagdandi_app/widgets/nav_style.dart';
import 'package:pagdandi_app/widgets/ptt_key.dart';
import 'package:pagdandi_app/widgets/route_panel.dart';
import 'package:pagdandi_app/widgets/screen_parts.dart';
import 'package:pagdandi_app/widgets/stat_triplet.dart';
import 'package:pagdandi_app/widgets/status_tag.dart';
import 'package:pagdandi_app/widgets/toast_line.dart';
import 'package:pagdandi_app/widgets/trek_map.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// The screen the trekker looks at while walking: glance zone, map, and the
/// thumb zone (group row + key deck). Renders [view]; sends [actions].
class ActiveTrekScreen extends StatelessWidget {
  /// Creates the screen.
  const ActiveTrekScreen({
    required this.view,
    this.actions = const TrekActions(),
    super.key,
  });

  /// What to show.
  final ActiveTrekView view;

  /// What the buttons do.
  final TrekActions actions;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    final nav = view.nav;
    final color = nav.color(p);
    final glyph = switch (nav) {
      NavState.wrongWay => AppIcon.uturn,
      NavState.gpsLost => AppIcon.gps,
      // No route, so no direction to point in: a pin, not an arrow.
      NavState.free => AppIcon.pin,
      _ => null,
    };

    // The glance zone truncates before the controls or the map give way:
    // its text scale is capped at 1.3.
    final glance = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: GlanceStrip(
        accuracy: view.accuracy,
        battery: view.battery,
        tint: nav.tint(p),
        tag: StatusTag(icon: nav.icon, label: nav.tagLabel, color: color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DirectionDial(
                  angle: view.dialAngle,
                  color: color,
                  glyph: glyph,
                  semanticsLabel: '${view.hero}. ${view.sub}',
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        view.hero,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TypeScale.hero.copyWith(
                          color: p.text,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        view.sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TypeScale.body.copyWith(color: p.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            StatTriplet(
              header: view.statsHeader,
              stats: view.stats,
              paused: view.stationary,
            ),
            if (view.stationary) ...[
              const SizedBox(height: 8),
              Text(
                'Paused · tracking resumes when you move',
                style: TypeScale.body.copyWith(color: p.text),
              ),
            ],
          ],
        ),
      ),
    );

    final snoozed = view.snoozeLeft != null;
    String mmss(Duration d) =>
        '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    // At large text the snooze key gives up height so the map keeps room.
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 16 * 1.3;
    // Walking home down the same trail is not a mistake: one tap turns the
    // guidance around.
    final headBack = view.live && nav == NavState.wrongWay
        ? Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: KeyButton(
              compact: largeText,
              icon: AppIcon.uturn,
              iconColor: p.warn,
              label: 'I’m heading back',
              sub: largeText ? null : 'Follow the trail the other way',
              onPressed: actions.onReverseRoute,
            ),
          )
        : null;

    final snooze = nav == NavState.offRoute
        ? Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: snoozed
                ? KeyButton(
                    compact: largeText,
                    icon: AppIcon.clock,
                    iconColor: p.text2,
                    label: 'Snoozed ${mmss(view.snoozeLeft!)}',
                    sub: largeText ? null : 'Tap to resume alerts',
                    onPressed: actions.onResumeAlerts,
                  )
                : KeyButton(
                    compact: largeText,
                    icon: AppIcon.eye,
                    iconColor: p.warn,
                    label: 'I know, exploring',
                    sub: largeText
                        ? null
                        : 'Silences off-route alerts for 10 min',
                    onPressed: actions.onSnooze,
                  ),
          )
        : null;

    final deck = Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(
          top: BorderSide(color: p.hairline, width: p.lineScale),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: prefs.leftHanded ? TextDirection.rtl : TextDirection.ltr,
        children: [
          HoldButton.square(
            label: 'SOS',
            sub: 'hold 3 s',
            semanticsLabel: 'SOS, hold 3 seconds',
            seconds: 3,
            color: sosColour(p),
            onTick: actions.onSosHoldTick,
            onComplete: actions.onSosStarted,
          ),
          SizedBox(width: prefs.space(12)),
          DeckKey(
            icon: AppIcon.pin,
            label: view.pinCount > 0 ? 'Pin · ${view.pinCount}' : 'Pin',
            onPressed: actions.onPin,
          ),
          if (!view.live) ...[
            SizedBox(width: prefs.space(12)),
            Expanded(
              child: PttKey(
                state: view.ptt,
                onTalkStart: actions.onTalkStart,
                onTalkEnd: actions.onTalkEnd,
              ),
            ),
          ] else ...[
            SizedBox(width: prefs.space(12)),
            Expanded(
              child: HoldButton.wide(
                label: 'End trek · hold 3 s',
                semanticsLabel: 'End trek, hold 3 seconds',
                icon: AppIcon.x,
                seconds: 3,
                color: p.text2,
                onComplete: actions.onEndTrek,
              ),
            ),
          ],
        ],
      ),
    );

    return ScreenFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          glance,
          if (view.alert != null) _AlertLine(text: view.alert!),
          if (view.toast != null)
            ToastLine(sender: view.toast!.sender, message: view.toast!.text),
          Expanded(
            child: view.live
                ? switch (view.route) {
                    final r? => RoutePanel(
                      route: r,
                      state: nav,
                      progressM: view.navView?.progressM ?? 0,
                      me: view.me,
                    ),
                    null => _LivePosition(view: view),
                  }
                : TrekMap(
                    nav: nav,
                    altitude: view.altitude,
                    uncertaintyRadius: view.uncertaintyRadius,
                  ),
          ),
          ?headBack,
          ?snooze,
          if (!view.live)
            GroupRow(
              main: view.groupMain,
              fact: view.groupFact,
              tone: view.groupTone,
              icon: nav == NavState.regroup ? AppIcon.radar : AppIcon.people,
              onTap: actions.onOpenRadar,
            ),
          deck,
        ],
      ),
    );
  }
}

/// Where the real trek is, in words, until the offline map pack is built.
class _LivePosition extends StatelessWidget {
  const _LivePosition({required this.view});

  final ActiveTrekView view;

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    return Semantics(
      container: true,
      label: view.position == null
          ? 'Waiting for a GPS position'
          : 'Your position ${view.position}, altitude ${view.altitude}',
      excludeSemantics: true,
      child: ColoredBox(
        color: p.bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconView(AppIcon.pin, color: p.nav, size: 32),
              const SizedBox(height: 10),
              Text(
                view.position ?? 'Waiting for GPS',
                style: TypeScale.title.copyWith(color: p.text),
              ),
              const SizedBox(height: 4),
              Text(
                'altitude ${view.altitude}',
                style: TypeScale.body.copyWith(color: p.text2),
              ),
              const SizedBox(height: 14),
              Text(
                'The offline map arrives in a later build',
                style: TypeScale.label.copyWith(color: p.text3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A critical problem (for example a revoked permission), in words and with a
/// warning shape, never colour alone.
class _AlertLine extends StatelessWidget {
  const _AlertLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    return Semantics(
      liveRegion: true,
      label: 'Warning: $text',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: p.tintWarn,
          border: Border(
            bottom: BorderSide(color: p.warn, width: p.lineScale),
          ),
        ),
        child: Row(
          children: [
            AppIconView(AppIcon.warn, color: p.warn),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TypeScale.body.copyWith(color: p.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
