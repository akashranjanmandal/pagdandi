import 'package:core_model/core_model.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/app/screen_choice.dart';
import 'package:trek_core/trek_core.dart';

final t0 = DateTime.utc(2026, 10, 28, 8);

CoreStateMessage msg({
  Emergency emergency = const NoEmergency(),
  SosSummary sos = const SosSummary.none(),
  LocationFix? fix,
  int battery = 80,
}) => CoreStateMessage(
  state: TrekState(
    activity: Activity.moving,
    emergency: emergency,
    mapOpen: false,
  ),
  sos: sos,
  issues: const [],
  stats: const TrekStats(
    distanceM: 0,
    climbM: 0,
    elapsed: Duration.zero,
    altitudeM: null,
  ),
  battery: battery,
  fix: fix,
  at: t0,
);

SosSummary summary({int total = 3, int delivered = 0}) => SosSummary(
  active: true,
  total: total,
  queued: total - delivered,
  sending: 0,
  sent: 0,
  delivered: delivered,
  failed: 0,
  cancelled: 0,
);

void main() {
  test('no emergency shows the trek', () {
    expect(chooseScreen(msg(), Duration.zero), isA<TrekChoice>());
  });

  test('my SOS shows the SOS screen with the real delivery count', () {
    final c = chooseScreen(
      msg(emergency: const SosActive(), sos: summary(delivered: 2)),
      Duration.zero,
    );
    expect(c, isA<SosChoice>());
    final d = (c as SosChoice).view.delivery;
    expect([d.total, d.delivered], [3, 2]);
  });

  test('an SOS with nobody to tell never crashes the screen', () {
    final c = chooseScreen(
      msg(emergency: const SosActive(), sos: summary(total: 0)),
      Duration.zero,
    );
    expect(c, isA<SosChoice>());
    expect((c as SosChoice).view.delivery.total, 0);
  });

  test(
    'the fall countdown counts down from the trusted time of the message',
    () {
      final deadline = t0.add(const Duration(seconds: 60));
      final c = chooseScreen(
        msg(emergency: FallCountdown(deadline)),
        const Duration(seconds: 12, milliseconds: 400),
      );
      expect((c as FallChoice).view.secondsLeft, 48);
    },
  );

  test('a passed deadline shows zero, never a negative number', () {
    final c = chooseScreen(
      msg(emergency: FallCountdown(t0.add(const Duration(seconds: 5)))),
      const Duration(seconds: 30),
    );
    expect((c as FallChoice).view.secondsLeft, 0);
  });

  test('lost mode shows the lost screen', () {
    expect(
      chooseScreen(msg(emergency: const LostMode()), Duration.zero),
      isA<LostChoice>(),
    );
  });

  test('a friend SOS falls back to the trek screen in this build', () {
    expect(
      chooseScreen(msg(emergency: const FriendSos('a')), Duration.zero),
      isA<TrekChoice>(),
    );
  });

  test('the SOS screen gets the real fix and battery, not the sample', () {
    final fix = LocationFix(
      latitude: 12.5,
      longitude: 77.5,
      accuracyM: 5,
      gpsTime: t0,
      altitudeM: 900,
    );
    final c = chooseScreen(
      msg(emergency: const SosActive(), sos: summary(), fix: fix, battery: 63),
      Duration.zero,
    ) as SosChoice;
    expect(c.view.toolsAvailable, isFalse);
    expect(c.view.position?.latText, '12.5000° N');
    expect(c.view.battery, 63);
  });

  test('an SOS before the first fix has no position, not a made-up one', () {
    final c = chooseScreen(
      msg(emergency: const SosActive(), sos: summary()),
      Duration.zero,
    ) as SosChoice;
    expect(c.view.position, isNull);
  });

  test('the fall screen shows the real accuracy and battery', () {
    final fix = LocationFix(
      latitude: 12.5,
      longitude: 77.5,
      accuracyM: 5,
      gpsTime: t0,
    );
    final c = chooseScreen(
      msg(
        emergency: FallCountdown(t0.add(const Duration(seconds: 60))),
        fix: fix,
        battery: 63,
      ),
      Duration.zero,
    ) as FallChoice;
    expect(c.view.accuracy, 'GPS ±5 m');
    expect(c.view.battery, 63);
  });

  test('with tools given, the SOS screen shows them with their real state', () {
    final c = chooseScreen(
      msg(emergency: const SosActive(), sos: summary()),
      Duration.zero,
      tools: const SosTools(siren: true, torch: false, signal: true),
    ) as SosChoice;
    expect(c.view.toolsAvailable, isTrue);
    expect(c.view.siren, isTrue);
    expect(c.view.torch, isFalse);
    expect(c.view.signal, isTrue);
  });

  test('without tools the SOS screen hides them', () {
    final c = chooseScreen(
      msg(emergency: const SosActive(), sos: summary()),
      Duration.zero,
    ) as SosChoice;
    expect(c.view.toolsAvailable, isFalse);
  });

  test('a real fall never claims what the sensors saw', () {
    final c = chooseScreen(
      msg(emergency: FallCountdown(t0.add(const Duration(seconds: 60)))),
      Duration.zero,
    ) as FallChoice;
    expect(c.view.detail, 'A fall was suspected');
  });

  test('the lost screen is live, with the real accuracy and battery', () {
    final c = chooseScreen(
      msg(emergency: const LostMode(), battery: 63),
      Duration.zero,
    ) as LostChoice;
    expect(c.view.live, isTrue);
    expect(c.view.battery, 63);
    expect(c.view.accuracy, 'GPS ±—');
  });
}
