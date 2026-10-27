import 'package:core_common/core_common.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/models/active_trek_view.dart';
import 'package:pagdandi_app/models/nav_state.dart';
import 'package:pagdandi_app/preview/preview_settings.dart';
import 'package:pagdandi_app/preview/previews.dart';
import 'package:pagdandi_app/screens/friend_sos_screen.dart';
import 'package:pagdandi_app/screens/lost_mode_screen.dart';
import 'package:pagdandi_app/widgets/key_button.dart';
import 'package:pagdandi_app/widgets/ptt_key.dart';
import 'package:pagdandi_app/widgets/screen_parts.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

typedef _Entry = (String, Widget Function());

/// Preview build home: every approved screen in every state, plus the display
/// switches. Product navigation replaces this later.
class Gallery extends ConsumerWidget {
  /// Creates the gallery.
  const Gallery({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    final s = ref.watch(previewSettingsProvider);
    final n = ref.read(previewSettingsProvider.notifier);

    final sections = <(String, List<_Entry>)>[
      (
        'Active Trek',
        [
          ('On route', () => const ActiveTrekPreview(nav: NavState.onRoute)),
          ('Junction', () => const ActiveTrekPreview(nav: NavState.junction)),
          ('Off route', () => const ActiveTrekPreview(nav: NavState.offRoute)),
          ('Wrong way', () => const ActiveTrekPreview(nav: NavState.wrongWay)),
          ('GPS lost', () => const ActiveTrekPreview(nav: NavState.gpsLost)),
          ('Regroup', () => const ActiveTrekPreview(nav: NavState.regroup)),
          (
            'Stationary',
            () => const ActiveTrekPreview(
              nav: NavState.onRoute,
              stationary: true,
            ),
          ),
          (
            'Message toast',
            () => const ActiveTrekPreview(
              nav: NavState.onRoute,
              toast: ToastMessage('Rahul', 'Take left fork'),
            ),
          ),
          (
            'Off route, snoozed',
            () =>
                const ActiveTrekPreview(nav: NavState.offRoute, snoozed: true),
          ),
          (
            'PTT receiving',
            () => const PttStatePreview(state: PttState.receiving),
          ),
          (
            'PTT channel busy',
            () => const PttStatePreview(state: PttState.busy),
          ),
        ],
      ),
      (
        'Lost mode',
        [
          ('Stay where you are', LostPreview.new),
          ('Group reached', () => const LostPreview(groupReached: true)),
          ('Reason prompt', () => const LostPreview(stage: LostStage.prompt)),
          ('Backtrack', () => const LostPreview(stage: LostStage.backtrack)),
          ('Found', () => const LostPreview(stage: LostStage.found)),
        ],
      ),
      (
        'Friend SOS',
        [
          ('Rahul sent SOS', FriendPreview.new),
          ('With signal', () => const FriendPreview(signal: true)),
          (
            'Out of range',
            () => const FriendPreview(kind: FriendKind.outOfRange),
          ),
          ('Guiding', () => const FriendPreview(kind: FriendKind.guiding)),
        ],
      ),
      (
        'Fall countdown',
        [
          ('Countdown running', FallPreview.new),
          ('Last 8 seconds', () => const FallPreview(start: 8)),
        ],
      ),
      (
        'SOS active',
        [
          ('Nothing delivered', SosPreview.new),
          ('Delivered to 2 of 3', () => const SosPreview(delivered: 2)),
          (
            'Delivered, signal on',
            () => const SosPreview(delivered: 3, signal: true),
          ),
          ('Cancelled', () => const SosPreview(cancelled: true)),
        ],
      ),
    ];

    Widget switchKey(String label, VoidCallback tap, {required bool on}) =>
        SizedBox(
          width: 150,
          child: KeyButton(
            compact: true,
            label: label,
            sub: on ? 'On' : 'Off',
            variant: on ? KeyVariant.primary : KeyVariant.neutral,
            onPressed: tap,
          ),
        );

    return ScreenFrame(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kAppName, style: TypeScale.display.copyWith(color: p.text)),
            const SizedBox(height: 4),
            Text(
              'Design preview · screens from docs/design',
              style: TypeScale.body.copyWith(color: p.text2),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                switchKey('Sunlight', n.toggleSunlight, on: s.prefs.sunlight),
                switchKey('Glove', n.toggleGlove, on: s.prefs.glove),
                switchKey(
                  'Left-handed',
                  n.toggleLeftHanded,
                  on: s.prefs.leftHanded,
                ),
                switchKey('Text 1.5×', n.toggleLargeText, on: s.largeText),
                switchKey(
                  'Reduce motion',
                  n.toggleReduceMotion,
                  on: s.prefs.reduceMotion,
                ),
              ],
            ),
            for (final (title, entries) in sections) ...[
              const SizedBox(height: 24),
              Text(title, style: TypeScale.title.copyWith(color: p.text)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (label, build) in entries)
                    SizedBox(
                      width: 156,
                      child: KeyButton(
                        compact: true,
                        icon: AppIcon.chevron,
                        iconColor: p.text2,
                        label: label,
                        onPressed: () => openScreen(context, build()),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
