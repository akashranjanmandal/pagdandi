import 'dart:async';

import 'package:core_ports/core_ports.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/client/core_client.dart';
import 'package:trek_core/trek_core.dart';

class _Channel implements UiChannel {
  final controller = StreamController<String>.broadcast(sync: true);
  final sent = <String>[];
  final log = <String>[];
  bool listening = false;

  @override
  Stream<String> get states => controller.stream;
  @override
  Future<void> send(String json) async => sent.add(json);
}

String sampleStateJson() => CoreStateMessage(
  state: const TrekState(
    activity: Activity.moving,
    emergency: NoEmergency(),
    mapOpen: false,
  ),
  sos: const SosSummary.none(),
  issues: const [],
  stats: const TrekStats(
    distanceM: 10,
    climbM: 1,
    elapsed: Duration(minutes: 1),
    altitudeM: null,
  ),
  battery: 80,
  fix: null,
  at: DateTime.utc(2026, 10, 28, 8),
).encode();

void main() {
  late _Channel channel;
  late CoreClient client;
  var registeredWhileListening = false;

  setUp(() {
    channel = _Channel();
    registeredWhileListening = false;
    client = CoreClient(
      channel: channel,
      register: () async =>
          registeredWhileListening = channel.controller.hasListener,
    );
  });

  test(
    'registers with the relay only after it is listening for states',
    () async {
      await client.connect();
      expect(registeredWhileListening, isTrue);
    },
  );

  test('shows no state until the core has sent one', () async {
    await client.connect();
    expect(client.latest, isNull);
    expect(client.connected, isFalse);
  });

  test('keeps the newest decoded state and tells listeners', () async {
    await client.connect();
    final seen = <CoreStateMessage>[];
    client.states.listen(seen.add);
    channel.controller.add(sampleStateJson());
    expect(client.latest, isNotNull);
    expect(client.connected, isTrue);
    expect(seen, hasLength(1));
  });

  test(
    'ignores malformed or forged messages and keeps the last good one',
    () async {
      await client.connect();
      channel.controller.add(sampleStateJson());
      final good = client.latest;
      channel.controller.add('not json');
      channel.controller.add('{"v":99}');
      expect(client.latest, same(good));
    },
  );

  test('knows how long ago the newest state arrived', () async {
    await client.connect();
    expect(client.sinceReceived, Duration.zero);
    channel.controller.add(sampleStateJson());
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(client.sinceReceived, greaterThan(Duration.zero));
    channel.controller.add(sampleStateJson());
    expect(client.sinceReceived, lessThan(const Duration(milliseconds: 20)));
  });

  test('sends commands encoded for the core', () async {
    await client.send(const StartTrek());
    expect(decodeCommand(channel.sent.single), isA<StartTrek>());
  });

  test('reverse-route is sent as its own command', () async {
    await client.reverseRoute();
    expect(isReverseRouteCommand(channel.sent.single), isTrue);
  });

  test('snooze and resume are sent as navigation commands', () async {
    await client.snoozeAlerts();
    await client.resumeAlerts();
    expect(
      channel.sent.map(decodeNavCommand),
      [NavCommand.snoozeAlerts, NavCommand.resumeAlerts],
    );
  });

  test('drop-pin is sent as its own command', () async {
    await client.dropPin();
    expect(isDropPinCommand(channel.sent.single), isTrue);
  });

  test('a failing send never throws into the UI', () async {
    final failing = CoreClient(
      channel: _Failing(),
      register: () async {},
    );
    await failing.send(const SosPressed());
  });
}

class _Failing extends _Channel {
  @override
  Future<void> send(String json) async => throw StateError('relay down');
}
