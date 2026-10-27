import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/sos_colour.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/direction_dial.dart';
import 'package:pagdandi_app/widgets/key_button.dart';
import 'package:pagdandi_app/widgets/ptt_key.dart';
import 'package:pagdandi_app/widgets/screen_parts.dart';
import 'package:pagdandi_app/widgets/status_tag.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// What happened to the friend.
enum FriendKind {
  /// The friend sent an SOS.
  sentSos,

  /// The friend went out of range.
  outOfRange,

  /// You acknowledged and are guiding to them.
  guiding,
}

/// Snapshot of the friend alert.
@immutable
class FriendSosView {
  /// Creates a view.
  const FriendSosView({
    this.kind = FriendKind.sentSos,
    this.signal = false,
    this.cardOpen = false,
    this.pttState = PttState.idle,
  });

  /// What happened.
  final FriendKind kind;

  /// Whether any mobile signal exists (Call 112 enabled).
  final bool signal;

  /// Emergency card sheet open.
  final bool cardOpen;

  /// Push-to-talk state.
  final PttState pttState;
}

/// Full-screen takeover for everyone else: who, what, where, how to act.
/// "Guide me there" also acknowledges (the repeating buzz stops).
class FriendSosScreen extends StatelessWidget {
  /// Creates the screen.
  const FriendSosScreen({
    required this.view,
    this.onGuide,
    this.onCard,
    this.onCloseCard,
    this.onCall,
    this.onTalkStart,
    this.onTalkEnd,
    this.onBackToTrek,
    super.key,
  });

  /// What to show.
  final FriendSosView view;

  /// "Guide me there": acknowledges and starts guiding.
  final VoidCallback? onGuide;

  /// Open the friend's emergency card.
  final VoidCallback? onCard;

  /// Close the card.
  final VoidCallback? onCloseCard;

  /// Call 112.
  final VoidCallback? onCall;

  /// PTT pressed.
  final VoidCallback? onTalkStart;

  /// PTT released.
  final VoidCallback? onTalkEnd;

  /// Return to the trek map.
  final VoidCallback? onBackToTrek;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    void noop() {}
    final sos = view.kind != FriendKind.outOfRange;
    final accent = sos ? sosColour(p) : p.signal;
    final guiding = view.kind == FriendKind.guiding;

    final strip = GlanceStrip(
      accuracy: 'GPS ±6 m',
      battery: 71,
      tint: sos ? sosTint(p) : p.tintSignal,
      tag: sos
          ? StatusTag(icon: AppIcon.octagon, label: 'Friend SOS', color: accent)
          : StatusTag(
              icon: AppIcon.radar,
              label: 'Friend out of range',
              color: accent,
            ),
    );

    final (title, sub) = switch (view.kind) {
      FriendKind.sentSos => (
        'Rahul sent SOS',
        '4 min ago · last known position',
      ),
      FriendKind.outOfRange => (
        'Rahul out of range',
        'seen 3 min ago · last known position',
      ),
      FriendKind.guiding => (
        'Going to Rahul',
        'Your group knows you are going',
      ),
    };

    final call = KeyButton(
      icon: AppIcon.call,
      label: 'Call 112',
      sub: view.signal ? null : 'No signal yet',
      enabled: view.signal,
      onPressed: onCall ?? noop,
    );

    final callRow = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      textDirection: prefs.leftHanded ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              call,
              if (!view.signal)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Needs any mobile signal. Enables the moment one appears.',
                    style: TypeScale.caption.copyWith(color: p.text2),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: prefs.space(12)),
        SizedBox(
          width: prefs.target(132),
          child: PttKey(
            state: view.pttState,
            onTalkStart: onTalkStart ?? noop,
            onTalkEnd: onTalkEnd ?? noop,
          ),
        ),
      ],
    );

    final thumb = ThumbPanel(
      children: [
        if (!guiding) ...[
          KeyButton(
            icon: AppIcon.card,
            label: 'Rahul’s emergency card',
            onPressed: onCard ?? noop,
          ),
          KeyButton(
            variant: KeyVariant.primary,
            icon: AppIcon.arrow,
            label: 'Guide me there',
            onPressed: onGuide ?? noop,
          ),
        ] else
          KeyButton(
            icon: AppIcon.back,
            label: 'Back to trek map',
            onPressed: onBackToTrek ?? noop,
          ),
        callRow,
      ],
    );

    return ScreenFrame(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              strip,
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BigInstruction(title: title, sub: sub),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            DirectionDial(
                              big: true,
                              angle: 25,
                              color: accent,
                              semanticsLabel: '340 metres, uphill',
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '340',
                                          style: TypeScale.display.copyWith(
                                            color: p.text,
                                            height: 1,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' m',
                                          style: TypeScale.body.copyWith(
                                            color: p.text2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'to last known position',
                                    style: TypeScale.label.copyWith(
                                      color: p.text2,
                                    ),
                                  ),
                                  Text(
                                    '±8 m · uphill',
                                    style: TypeScale.label.copyWith(
                                      color: p.text2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              thumb,
            ],
          ),
          if (view.cardOpen) ...[
            const Scrim(),
            SheetPanel(
              title: 'Rahul’s emergency card',
              children: [
                for (final kv in const [
                  ('Blood group', 'B+'),
                  ('Allergies', 'Penicillin'),
                  ('Medicines', 'None'),
                  ('Contact', 'Meera · +91 98xxx xx210'),
                ])
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: p.hairline,
                          width: p.lineScale,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          kv.$1,
                          style: TypeScale.body.copyWith(color: p.text2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            kv.$2,
                            textAlign: TextAlign.right,
                            style: TypeScale.body.copyWith(color: p.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                KeyButton(label: 'Close', onPressed: onCloseCard ?? noop),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
