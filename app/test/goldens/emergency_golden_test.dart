import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/models/sos_delivery.dart';
import 'package:pagdandi_app/screens/fall_countdown_screen.dart';
import 'package:pagdandi_app/screens/friend_sos_screen.dart';
import 'package:pagdandi_app/screens/lost_mode_screen.dart';
import 'package:pagdandi_app/screens/sos_active_screen.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

import 'golden_harness.dart';

typedef _Prefs = (UiPrefs, double);

const _variants = <String, _Prefs>{
  'left_handed': (UiPrefs(leftHanded: true, reduceMotion: true), 1.0),
  'sunlight': (UiPrefs(sunlight: true, reduceMotion: true), 1.0),
  'glove': (UiPrefs(glove: true, reduceMotion: true), 1.0),
  'text_1_5': (UiPrefs(reduceMotion: true), 1.5),
};

void _golden(String name, Widget Function() screen, {_Prefs? prefs}) {
  testWidgets(name, (tester) async {
    await pumpPhone(
      tester,
      screen(),
      prefs: prefs?.$1 ?? const UiPrefs(reduceMotion: true),
      textScale: prefs?.$2 ?? 1,
    );
    await expectLater(
      find.byType(UiScope),
      matchesGoldenFile('emergency/$name.png'),
    );
  });
}

void main() {
  group('Lost mode', () {
    _golden('lost_default', () => const LostModeScreen(view: LostView()));
    _golden(
      'lost_group_reached',
      () =>
          const LostModeScreen(view: LostView(groupReached: true, torch: true)),
    );
    _golden(
      'lost_prompt',
      () => const LostModeScreen(view: LostView(stage: LostStage.prompt)),
    );
    _golden(
      'lost_backtrack',
      () => const LostModeScreen(
        view: LostView(stage: LostStage.backtrack, reason: LostReason.dark),
      ),
    );
    _golden(
      'lost_found',
      () => const LostModeScreen(view: LostView(stage: LostStage.found)),
    );
    for (final e in _variants.entries) {
      _golden(
        'lost_${e.key}',
        () => const LostModeScreen(view: LostView()),
        prefs: e.value,
      );
    }
  });

  group('Friend SOS', () {
    _golden('friend_sos', () => const FriendSosScreen(view: FriendSosView()));
    _golden(
      'friend_sos_signal',
      () => const FriendSosScreen(view: FriendSosView(signal: true)),
    );
    _golden(
      'friend_out_of_range',
      () => const FriendSosScreen(
        view: FriendSosView(kind: FriendKind.outOfRange),
      ),
    );
    _golden(
      'friend_guiding',
      () =>
          const FriendSosScreen(view: FriendSosView(kind: FriendKind.guiding)),
    );
    _golden(
      'friend_card',
      () => const FriendSosScreen(view: FriendSosView(cardOpen: true)),
    );
    for (final e in _variants.entries) {
      _golden(
        'friend_${e.key}',
        () => const FriendSosScreen(view: FriendSosView()),
        prefs: e.value,
      );
    }
  });

  group('Fall countdown', () {
    _golden('fall_60', () => const FallCountdownScreen(view: FallView()));
    _golden(
      'fall_8',
      () => const FallCountdownScreen(view: FallView(secondsLeft: 8)),
    );
    _golden(
      'fall_sent',
      () => const FallCountdownScreen(view: FallView(stage: FallStage.sent)),
    );
    _golden(
      'fall_cancelled',
      () =>
          const FallCountdownScreen(view: FallView(stage: FallStage.cancelled)),
    );
    for (final e in _variants.entries) {
      _golden(
        'fall_${e.key}',
        () => const FallCountdownScreen(view: FallView(secondsLeft: 47)),
        prefs: e.value,
      );
    }
  });

  group('SOS active', () {
    _golden(
      'sos_nothing_delivered',
      () => const SosActiveScreen(view: SosView()),
    );
    _golden(
      'sos_two_of_three',
      () => const SosActiveScreen(
        view: SosView(delivery: SosDelivery(total: 3, delivered: 2)),
      ),
    );
    _golden(
      'sos_all_delivered',
      () => const SosActiveScreen(
        view: SosView(
          delivery: SosDelivery(total: 3, delivered: 3),
          signal: true,
          siren: true,
          torch: true,
        ),
      ),
    );
    _golden(
      'sos_cancelled',
      () => const SosActiveScreen(view: SosView(cancelled: true)),
    );
    for (final e in _variants.entries) {
      _golden(
        'sos_${e.key}',
        () => const SosActiveScreen(view: SosView()),
        prefs: e.value,
      );
    }
  });

  testWidgets('no emergency screen overflows at text 1.5 or in glove mode', (
    tester,
  ) async {
    final screens = <Widget>[
      const LostModeScreen(view: LostView()),
      const LostModeScreen(view: LostView(stage: LostStage.prompt)),
      const FriendSosScreen(view: FriendSosView()),
      const FriendSosScreen(view: FriendSosView(cardOpen: true)),
      const FallCountdownScreen(view: FallView()),
      const SosActiveScreen(view: SosView()),
    ];
    for (final (i, s) in screens.indexed) {
      for (final prefs in [
        (const UiPrefs(reduceMotion: true), 1.5),
        (const UiPrefs(glove: true, reduceMotion: true), 1.0),
      ]) {
        await pumpPhone(tester, s, prefs: prefs.$1, textScale: prefs.$2);
        expect(
          tester.takeException(),
          isNull,
          reason: 'screen $i ${prefs.$2} glove=${prefs.$1.glove}',
        );
      }
    }
  });
}
