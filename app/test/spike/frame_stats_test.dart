import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/spike/frame_stats.dart';

void main() {
  Duration ms(int v) => Duration(milliseconds: v);

  test('an empty recorder reports zeros', () {
    final s = FrameStats();
    expect(s.frames, 0);
    expect(s.jankyFrames, 0);
    expect(s.percentile(0.95), Duration.zero);
    expect(s.jankPercent, 0);
  });

  test('a frame is janky when build or raster exceeds the budget', () {
    final s = FrameStats(budget: ms(16))
      ..add(build: ms(5), raster: ms(5))
      ..add(build: ms(20), raster: ms(2))
      ..add(build: ms(2), raster: ms(17));
    expect(s.frames, 3);
    expect(s.jankyFrames, 2);
    expect(s.jankPercent, closeTo(66.67, 0.01));
  });

  test('severe frames take more than twice the budget', () {
    final s = FrameStats(budget: ms(16))
      ..add(build: ms(10), raster: ms(10))
      ..add(build: ms(40), raster: ms(5));
    expect(s.severeFrames, 1);
  });

  test('percentile uses the slower of build and raster per frame', () {
    final s = FrameStats();
    for (var i = 1; i <= 100; i++) {
      s.add(build: ms(i), raster: ms(1));
    }
    expect(s.percentile(0.5), ms(50));
    expect(s.percentile(0.95), ms(95));
    expect(s.worst, ms(100));
  });

  test('reset clears everything', () {
    final s = FrameStats()..add(build: ms(50), raster: ms(1));
    s.reset();
    expect(s.frames, 0);
    expect(s.worst, Duration.zero);
  });

  test('summary is a one-line readable report', () {
    final s = FrameStats(budget: ms(16))
      ..add(build: ms(5), raster: ms(5))
      ..add(build: ms(30), raster: ms(5));
    expect(s.summary, '2 frames · jank 50% · p95 30 ms · worst 30 ms');
  });
}
