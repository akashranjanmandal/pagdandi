import 'dart:math' as math;

import 'package:core_model/core_model.dart';
import 'package:engine_safety/engine_safety.dart';
import 'package:test/test.dart';

const g = 9.81;

/// Builds accelerometer samples at 25 Hz from a function of time (seconds)
/// returning the magnitude in m/s^2 (all on the z axis).
class Rig {
  Rig() : detector = FallDetector();

  final FallDetector detector;
  Duration _t = Duration.zero;
  int fired = 0;

  /// Runs [seconds] of signal [f] (magnitude as a function of seconds into
  /// this stretch). Returns how many times a fall was reported.
  int run(double seconds, double Function(double t) f) {
    var n = 0;
    final steps = (seconds * 25).round();
    for (var i = 0; i < steps; i++) {
      final s = AccelSample(x: 0, y: 0, z: f(i / 25), at: _t);
      _t += const Duration(milliseconds: 40);
      if (detector.onSample(s)) {
        n++;
        fired++;
      }
    }
    return n;
  }

  /// Lying or sitting still: gravity only, tiny noise.
  int still(double seconds) => run(seconds, (t) => g + 0.15 * math.sin(t * 40));

  /// Walking: strong periodic acceleration.
  int walk(double seconds) =>
      run(seconds, (t) => g + 6 * math.sin(t * 2 * math.pi * 1.8));

  /// A fall: [freeFall] seconds of weightlessness, then one impact sample
  /// of [impact] m/s^2 (a second of settling follows).
  int fall({double freeFall = 0.2, double impact = 32}) {
    var n = run(freeFall, (_) => 1.0);
    n += run(0.04, (_) => impact);
    return n + run(0.5, (_) => g + 0.3);
  }
}

void main() {
  test('walking and sitting never raise a fall', () {
    final r = Rig();
    expect(r.walk(60) + r.still(60) + r.walk(60), 0);
  });

  test('free fall, impact, then 30 s of stillness is a fall', () {
    final r = Rig();
    r.still(5);
    expect(r.fall(), 0);
    expect(r.still(28), 0, reason: 'not yet 30 s');
    expect(r.still(4), 1, reason: 'reported once');
    expect(r.still(60), 0, reason: 'and only once');
  });

  test('stillness must be continuous: getting up cancels it', () {
    final r = Rig();
    r.fall();
    expect(r.still(20), 0);
    expect(r.walk(3), 0);
    expect(
      r.still(25),
      0,
      reason: 'the 30 s starts over, and the fall is stale',
    );
  });

  test('a hard impact alone counts even without a clean free fall', () {
    final r = Rig();
    r.run(0.04, (_) => 45); // 4.6 g
    expect(r.still(35), 1);
  });

  test('a medium bump with no free fall is not a fall', () {
    final r = Rig();
    r.run(0.04, (_) => 30);
    expect(r.still(60), 0);
  });

  test('a free fall without an impact soon after is not a fall', () {
    final r = Rig();
    r.run(0.3, (_) => 1.0);
    r.still(2);
    r.run(0.04, (_) => 30);
    expect(r.still(40), 0, reason: 'the impact came too late to belong to it');
  });

  test('a one-sample glitch is not a free fall', () {
    final r = Rig();
    r.run(0.04, (_) => 1.0);
    r.run(0.04, (_) => 30);
    expect(r.still(40), 0);
  });

  test('a fall that is never followed by stillness times out', () {
    final r = Rig();
    r.fall();
    r.walk(150);
    expect(
      r.still(40),
      0,
      reason: 'stale candidate, new stillness is just rest',
    );
  });

  test('after a report there is a cooldown, then it works again', () {
    final r = Rig();
    r.fall();
    expect(r.still(32), 1);
    r.fall();
    expect(r.still(40), 0, reason: 'within the cooldown');
    r.walk(5);
    // Wait out the cooldown (5 minutes), then fall again.
    r.run(300, (t) => g + 6 * math.sin(t * 2 * math.pi * 1.8));
    r.fall();
    expect(r.still(32), 1);
    expect(r.fired, 2);
  });

  test('samples out of order are ignored', () {
    final d = FallDetector();
    d.onSample(
      const AccelSample(x: 0, y: 0, z: g, at: Duration(seconds: 10)),
    );
    expect(
      d.onSample(
        const AccelSample(x: 0, y: 0, z: 45, at: Duration(seconds: 5)),
      ),
      isFalse,
    );
  });

  test('magnitude uses all three axes', () {
    final d = FallDetector();
    var t = Duration.zero;
    bool feed(double x, double y, double z) {
      final r = d.onSample(AccelSample(x: x, y: y, z: z, at: t));
      t += const Duration(milliseconds: 40);
      return r;
    }

    // 3-4-12 triangle: magnitude 13. A hard impact split over axes (30,30,30
    // is 52 m/s^2) followed by stillness is a fall.
    feed(30, 30, 30);
    var fired = false;
    for (var i = 0; i < 25 * 35; i++) {
      fired = feed(0, 0, g) || fired;
    }
    expect(fired, isTrue);
  });

  test('thresholds can be tuned', () {
    final d = FallDetector(stillFor: const Duration(seconds: 5));
    var t = Duration.zero;
    bool feed(double z) {
      final r = d.onSample(AccelSample(x: 0, y: 0, z: z, at: t));
      t += const Duration(milliseconds: 40);
      return r;
    }

    feed(50);
    var fired = false;
    for (var i = 0; i < 25 * 6; i++) {
      fired = feed(g) || fired;
    }
    expect(fired, isTrue);
  });
}
