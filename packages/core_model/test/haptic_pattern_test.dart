import 'package:core_model/core_model.dart';
import 'package:test/test.dart';

void main() {
  test('every pattern is distinct: none is reused for another meaning', () {
    final seen = <String>{};
    for (final p in HapticPattern.values) {
      expect(seen.add('${p.waveform}|${p.repeats}'), isTrue, reason: p.name);
    }
  });

  test('tap is a single 10 ms tick', () {
    expect(HapticPattern.tap.waveform, [0, 10]);
    expect(HapticPattern.tap.repeats, isFalse);
  });

  test('checkpoint is one short pulse', () {
    expect(_pulses(HapticPattern.checkpoint), [HapticPattern.shortMs]);
  });

  test('junction ahead is two short pulses', () {
    expect(_pulses(HapticPattern.junction), [
      HapticPattern.shortMs,
      HapticPattern.shortMs,
    ]);
    expect(HapticPattern.junction.repeats, isFalse);
  });

  test('off route is three long pulses and repeats', () {
    expect(
      _pulses(HapticPattern.offRoute),
      List.filled(3, HapticPattern.longMs),
    );
    expect(HapticPattern.offRoute.repeats, isTrue);
  });

  test('wrong way is three short pulses and does not repeat', () {
    expect(
      _pulses(HapticPattern.wrongWay),
      List.filled(3, HapticPattern.shortMs),
    );
    expect(HapticPattern.wrongWay.repeats, isFalse);
  });

  test('GPS lost is one long pulse', () {
    expect(_pulses(HapticPattern.gpsLost), [HapticPattern.longMs]);
    expect(HapticPattern.gpsLost.repeats, isFalse);
  });

  test('danger zone is long, short, long', () {
    expect(_pulses(HapticPattern.danger), [
      HapticPattern.longMs,
      HapticPattern.shortMs,
      HapticPattern.longMs,
    ]);
  });

  test('friend lost is two long pulses', () {
    expect(
      _pulses(HapticPattern.friendLost),
      List.filled(2, HapticPattern.longMs),
    );
    expect(HapticPattern.friendLost.repeats, isFalse);
  });

  test('SOS is three short, three long, three short and repeats', () {
    const s = HapticPattern.shortMs;
    const l = HapticPattern.longMs;
    expect(_pulses(HapticPattern.sos), [s, s, s, l, l, l, s, s, s]);
    expect(HapticPattern.sos.repeats, isTrue);
  });

  test('hold progress is a lighter tick than hold complete', () {
    expect(
      _pulses(HapticPattern.holdProgress).single,
      lessThan(_pulses(HapticPattern.holdComplete).single),
    );
    expect(HapticPattern.holdComplete.strong, isTrue);
    expect(HapticPattern.holdProgress.strong, isFalse);
  });

  test('waveforms start with a delay and alternate delay/on', () {
    for (final p in HapticPattern.values) {
      expect(p.waveform.length.isEven, isTrue, reason: p.name);
      expect(p.waveform.first, 0, reason: p.name);
    }
  });
}

/// The "on" durations of a waveform ([delay, on, off, on, ...]).
List<int> _pulses(HapticPattern p) => [
  for (var i = 1; i < p.waveform.length; i += 2) p.waveform[i],
];
