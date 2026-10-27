/// The haptic vocabulary (docs/design/tokens.md). A pattern is never reused
/// for another meaning, so every value here is distinct.
enum HapticPattern {
  /// 10 ms light tick on a tap.
  tap([0, 10]),

  /// Checkpoint reached or action OK: one short pulse.
  checkpoint([0, shortMs]),

  /// Junction ahead: two short pulses.
  junction([0, shortMs, gapMs, shortMs]),

  /// Off route: three long pulses, repeating until resolved or snoozed.
  offRoute([0, longMs, gapMs, longMs, gapMs, longMs], repeats: true),

  /// Wrong way (heading back toward the start): three short pulses.
  wrongWay([0, shortMs, gapMs, shortMs, gapMs, shortMs]),

  /// GPS lost: one long pulse.
  gpsLost([0, longMs]),

  /// Danger zone: long, short, long.
  danger([0, longMs, gapMs, shortMs, gapMs, longMs]),

  /// Friend lost: two long pulses.
  friendLost([0, longMs, gapMs, longMs]),

  /// SOS (own or friend): three short, three long, three short, repeating.
  sos(
    [
      0, shortMs, gapMs, shortMs, gapMs, shortMs, letterGapMs, //
      longMs, gapMs, longMs, gapMs, longMs, letterGapMs,
      shortMs, gapMs, shortMs, gapMs, shortMs,
    ],
    repeats: true,
  ),

  /// Light tick every second while a HoldButton is held.
  holdProgress([0, 15]),

  /// One strong pulse when a HoldButton completes.
  holdComplete([0, 200], strong: true);

  const HapticPattern(
    this.waveform, {
    this.repeats = false,
    this.strong = false,
  });

  /// Duration of a short pulse in milliseconds.
  static const int shortMs = 80;

  /// Duration of a long pulse in milliseconds.
  static const int longMs = 400;

  /// Pause between pulses in milliseconds.
  static const int gapMs = 150;

  /// Pause between SOS letters in milliseconds.
  static const int letterGapMs = 400;

  /// Android `VibrationEffect.createWaveform` timings: delay, on, off, on, ...
  final List<int> waveform;

  /// Whether the pattern repeats until cancelled.
  final bool repeats;

  /// Whether the pulse uses full amplitude.
  final bool strong;
}
