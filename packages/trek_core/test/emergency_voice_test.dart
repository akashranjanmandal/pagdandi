import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';
import 'package:trek_core/trek_core.dart';

class _Log implements Logger {
  @override
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}
}

SosSummary sos({int total = 3, int delivered = 0}) => SosSummary(
  active: true,
  total: total,
  queued: total - delivered,
  sending: 0,
  sent: 0,
  delivered: delivered,
  failed: 0,
  cancelled: 0,
);

TrekState state(Emergency e) =>
    TrekState(activity: Activity.moving, emergency: e, mapOpen: false);

void main() {
  late StreamController<TrekState> states;
  late StreamController<SosSummary> sums;
  late FakeVoiceOutput voice;
  late EmergencyVoice ev;

  setUp(() {
    states = StreamController<TrekState>.broadcast(sync: true);
    sums = StreamController<SosSummary>.broadcast(sync: true);
    voice = FakeVoiceOutput();
    ev = EmergencyVoice(
      states: states.stream,
      sos: sums.stream,
      voice: voice,
      logger: _Log(),
    );
  });
  tearDown(() => ev.dispose());

  test('a fall countdown asks if you fell, urgently', () {
    states.add(state(FallCountdown(DateTime.utc(2026, 12, 14, 8, 1))));
    expect(voice.said, [
      'Did you fall? Sending S.O.S. in 60 seconds. Tap I’m OK to cancel.',
    ]);
    expect(voice.urgent, hasLength(1));
  });

  test('the same state again is not said again', () {
    final s = state(FallCountdown(DateTime.utc(2026, 12, 14, 8, 1)));
    states.add(s);
    states.add(s);
    expect(voice.said, hasLength(1));
  });

  test('an SOS says it is active, and only claims what is true', () {
    states.add(state(const SosActive()));
    expect(voice.said, [
      'S.O.S. active. Your position will be sent at first signal.',
    ]);
    expect(voice.said.single, isNot(contains('delivered')));
  });

  test('delivery is announced when the first contact has it, with counts', () {
    states.add(state(const SosActive()));
    sums.add(sos());
    sums.add(sos(delivered: 1));
    sums.add(sos(delivered: 2));
    expect(voice.said.where((s) => s.contains('delivered')), [
      'S.O.S. delivered to 1 of 3 contacts.',
    ]);
  });

  test('with one contact the wording is singular', () {
    states.add(state(const SosActive()));
    sums.add(sos(total: 1, delivered: 1));
    expect(voice.said.last, 'S.O.S. delivered to 1 of 1 contact.');
  });

  test('a new SOS after the old one is announced afresh', () {
    states.add(state(const SosActive()));
    sums.add(sos(delivered: 1));
    states.add(state(const NoEmergency()));
    states.add(state(const SosActive()));
    sums.add(sos());
    sums.add(sos(delivered: 1));
    expect(voice.said.where((s) => s.contains('delivered')), hasLength(2));
  });

  test('no emergency says nothing', () {
    states.add(state(const NoEmergency()));
    states.add(state(const LostMode()));
    expect(voice.said, isEmpty);
  });

  test('a failing voice is survived', () {
    final bad = EmergencyVoice(
      states: states.stream,
      sos: sums.stream,
      voice: _Bad(),
      logger: _Log(),
    );
    states.add(state(const SosActive()));
    bad.dispose();
  });
}

class _Bad implements VoiceOutput {
  @override
  Future<void> speak(String text, {bool urgent = false}) async =>
      throw StateError('speaker');
  @override
  Future<void> stop() async {}
}
