import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/sos_colour.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/models/sos_delivery.dart';
import 'package:pagdandi_app/widgets/checklist.dart';
import 'package:pagdandi_app/widgets/hold_button.dart';
import 'package:pagdandi_app/widgets/key_button.dart';
import 'package:pagdandi_app/widgets/large_toggle.dart';
import 'package:pagdandi_app/widgets/screen_parts.dart';
import 'package:pagdandi_app/widgets/status_tag.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Snapshot of an active SOS.
@immutable
class SosView {
  /// Creates a view.
  const SosView({
    this.delivery = const SosDelivery(total: 3, delivered: 0),
    this.signal = false,
    this.siren = false,
    this.torch = false,
    this.cancelled = false,
  });

  /// How far the SMS has got.
  final SosDelivery delivery;

  /// Any mobile signal (enables Call 112).
  final bool signal;

  /// Siren on.
  final bool siren;

  /// Torch strobe on.
  final bool torch;

  /// SOS was cancelled.
  final bool cancelled;
}

/// My SOS is running: coordinates to read aloud, an honest delivery status,
/// and the few controls I might need. No decorative motion.
class SosActiveScreen extends StatelessWidget {
  /// Creates the screen.
  const SosActiveScreen({
    required this.view,
    this.onSiren,
    this.onTorch,
    this.onCall,
    this.onCancel,
    this.onBackToTrek,
    super.key,
  });

  /// What to show.
  final SosView view;

  /// Siren toggled.
  final ValueChanged<bool>? onSiren;

  /// Torch toggled.
  final ValueChanged<bool>? onTorch;

  /// Call 112.
  final VoidCallback? onCall;

  /// Cancel hold completed.
  final VoidCallback? onCancel;

  /// Back to the trek after cancelling.
  final VoidCallback? onBackToTrek;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    void noop() {}

    if (view.cancelled) {
      return ScreenFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlanceStrip(
              accuracy: 'GPS ±8 m',
              battery: 41,
              tint: p.surface,
              tag: StatusTag(
                icon: AppIcon.ok,
                label: 'SOS cancelled',
                color: p.ok,
              ),
            ),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BigInstruction(
                    title: 'SOS cancelled',
                    sub:
                        'Cancel message will send at first signal · beacon off',
                  ),
                  StatusChecklist(
                    rows: [
                      ChecklistRow(
                        icon: AppIcon.send,
                        label: 'Cancel message to 3 contacts',
                        status: 'queued',
                        state: RowState.wait,
                      ),
                      ChecklistRow(
                        icon: AppIcon.radar,
                        label: 'Beacon',
                        status: 'off',
                        state: RowState.off,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ThumbPanel(
              children: [
                KeyButton(
                  variant: KeyVariant.primary,
                  icon: AppIcon.back,
                  label: 'Back to trek',
                  onPressed: onBackToTrek ?? noop,
                ),
              ],
            ),
          ],
        ),
      );
    }

    final d = view.delivery;
    final groupDone = d.delivered > 0;
    return ScreenFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlanceStrip(
            accuracy: 'GPS ±8 m',
            battery: 41,
            tint: sosTint(p),
            tag: StatusTag(
              icon: AppIcon.octagon,
              label: 'SOS',
              color: sosColour(p),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                    child: Semantics(
                      liveRegion: true,
                      container: true,
                      label: '${d.headline}. ${d.subline}',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.headline,
                            style: TypeScale.hero.copyWith(color: p.text),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.subline,
                            style: TypeScale.body.copyWith(color: p.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                    child: Semantics(
                      container: true,
                      label:
                          'Latitude 27.0410 north, longitude 88.2663 east, '
                          'altitude 3102 metres',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '27.0410° N\n88.2663° E',
                            style: TypeScale.display.copyWith(
                              color: p.text,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '3,102',
                                  style: TypeScale.hero.copyWith(color: p.text),
                                ),
                                TextSpan(
                                  text: ' m altitude',
                                  style: TypeScale.body.copyWith(
                                    color: p.text2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'position ±8 m · GPS time 14:32',
                            style: TypeScale.caption.copyWith(color: p.text2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  StatusChecklist(
                    rowHeight: 46,
                    rows: [
                      ChecklistRow(
                        icon: AppIcon.send,
                        label: 'SMS to ${d.total} contacts',
                        status: d.smsLabel,
                        state: d.smsState,
                      ),
                      const ChecklistRow(
                        icon: AppIcon.radar,
                        label: 'Beacon',
                        status: 'broadcasting',
                        state: RowState.live,
                      ),
                      ChecklistRow(
                        icon: AppIcon.people,
                        label: 'Group alerted',
                        status: groupDone ? '3 received' : 'sending',
                        state: groupDone ? RowState.done : RowState.wait,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                    child: Text(
                      'Battery 41% · about 9 h in SOS mode (estimate)',
                      style: TypeScale.caption.copyWith(color: p.text2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ThumbPanel(
            children: [
              Row(
                children: [
                  Expanded(
                    child: LargeToggle(
                      icon: AppIcon.siren,
                      label: 'Siren',
                      value: view.siren,
                      onChanged: onSiren ?? (_) {},
                    ),
                  ),
                  SizedBox(width: prefs.space(10)),
                  Expanded(
                    child: LargeToggle(
                      icon: AppIcon.torch,
                      label: 'Torch strobe',
                      value: view.torch,
                      onChanged: onTorch ?? (_) {},
                    ),
                  ),
                ],
              ),
              KeyButton(
                icon: AppIcon.call,
                label: 'Call 112',
                sub: view.signal
                    ? null
                    : 'No signal. Enables when any signal appears.',
                enabled: view.signal,
                onPressed: onCall ?? noop,
              ),
              HoldButton.wide(
                label: 'Cancel SOS · hold 5 s',
                semanticsLabel: 'Cancel SOS, hold 5 seconds',
                icon: AppIcon.x,
                seconds: 5,
                color: sosColour(p),
                onComplete: onCancel ?? noop,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
