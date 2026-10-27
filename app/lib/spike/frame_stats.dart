/// Frame timing recorder for the map spike: build and raster time per frame,
/// jank counts and percentiles.
class FrameStats {
  /// Creates a recorder; frames slower than [budget] count as janky
  /// (default 16 ms, one frame at 60 Hz).
  FrameStats({this.budget = const Duration(milliseconds: 16)});

  /// Per-frame time budget.
  final Duration budget;
  final List<Duration> _frameTimes = [];

  /// Records one frame.
  void add({required Duration build, required Duration raster}) {
    _frameTimes.add(build > raster ? build : raster);
  }

  /// Forgets all frames.
  void reset() => _frameTimes.clear();

  /// Frames recorded.
  int get frames => _frameTimes.length;

  /// Frames slower than the budget.
  int get jankyFrames => _frameTimes.where((t) => t > budget).length;

  /// Frames slower than twice the budget.
  int get severeFrames => _frameTimes.where((t) => t > budget * 2).length;

  /// Share of janky frames in percent.
  double get jankPercent => frames == 0 ? 0 : jankyFrames * 100 / frames;

  /// The slowest frame.
  Duration get worst => _frameTimes.isEmpty
      ? Duration.zero
      : _frameTimes.reduce((a, b) => a > b ? a : b);

  /// Frame time at quantile [q] (0 to 1), nearest rank.
  Duration percentile(double q) {
    if (_frameTimes.isEmpty) return Duration.zero;
    final sorted = [..._frameTimes]..sort();
    final rank = (q * sorted.length).ceil().clamp(1, sorted.length);
    return sorted[rank - 1];
  }

  /// One-line report.
  String get summary =>
      '$frames frames · jank ${jankPercent.round()}% · '
      'p95 ${percentile(0.95).inMilliseconds} ms · '
      'worst ${worst.inMilliseconds} ms';
}
