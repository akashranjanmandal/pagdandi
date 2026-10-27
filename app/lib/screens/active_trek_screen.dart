import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/sos_colour.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/models/active_trek_view.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:pagdandi_app/screens/trek_actions.dart';
import 'package:pagdandi_app/widgets/deck_key.dart';
import 'package:pagdandi_app/widgets/direction_dial.dart';
import 'package:pagdandi_app/widgets/group_row.dart';
import 'package:pagdandi_app/widgets/hold_button.dart';
import 'package:pagdandi_app/widgets/key_button.dart';
import 'package:pagdandi_app/widgets/nav_style.dart';
import 'package:pagdandi_app/widgets/ptt_key.dart';
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
              header: 'to camp',
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
          DeckKey(icon: AppIcon.pin, label: 'Pin', onPressed: actions.onPin),
          SizedBox(width: prefs.space(12)),
          Expanded(
            child: PttKey(
              state: view.ptt,
              onTalkStart: actions.onTalkStart,
              onTalkEnd: actions.onTalkEnd,
            ),
          ),
        ],
      ),
    );

    return ScreenFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          glance,
          if (view.toast != null)
            ToastLine(sender: view.toast!.sender, message: view.toast!.text),
          Expanded(
            child: TrekMap(
              nav: nav,
              altitude: view.altitude,
              uncertaintyRadius: view.uncertaintyRadius,
            ),
          ),
          ?snooze,
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
