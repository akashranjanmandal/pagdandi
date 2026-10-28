import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_tracking/src/fix_filter.dart';

/// Takes raw fixes from the GPS port, filters them, keeps the breadcrumb in
/// memory and writes accepted fixes to storage in batches (fewer wake-ups).
class TrackingPipeline {
  /// Creates a pipeline writing batches through [_sink].
  TrackingPipeline({
    required this._location,
    required this._sink,
    required Logger logger,
    FixFilter? filter,
    this.batchSize = 10,
    this.maxBuffered = 500,
  }) : _log = logger,
       _filter = filter ?? FixFilter();

  final LocationSource _location;
  final Future<void> Function(List<LocationFix> batch) _sink;
  final Logger _log;
  final FixFilter _filter;

  /// Accepted fixes that trigger a write.
  final int batchSize;

  /// Most unwritten fixes kept if storage keeps failing (oldest dropped).
  final int maxBuffered;

  final _breadcrumb = <LocationFix>[];
  final _buffer = <LocationFix>[];
  final _accepted = StreamController<LocationFix>.broadcast(sync: true);
  final _rejected = <FixVerdict, int>{};
  StreamSubscription<LocationFix>? _sub;

  /// Every accepted fix this trek, oldest first.
  List<LocationFix> get breadcrumb => List.unmodifiable(_breadcrumb);

  /// Accepted fixes as they happen.
  Stream<LocationFix> get accepted => _accepted.stream;

  /// How many fixes were rejected, by reason.
  Map<FixVerdict, int> get rejected => Map.unmodifiable(_rejected);

  /// Starts (or restarts) listening and asks the hardware for [request].
  Future<void> start(LocationRequest request) async {
    await _sub?.cancel();
    _sub = _location.fixes.listen(_onFix);
    await _location.request(request);
  }

  /// Restores a breadcrumb read from storage (after a restart). It is not
  /// written again.
  void seed(List<LocationFix> fixes) {
    _breadcrumb
      ..clear()
      ..addAll(fixes);
    if (fixes.isNotEmpty) _filter.seed(fixes.last);
  }

  void _onFix(LocationFix f) {
    final verdict = _filter.check(f);
    if (verdict != FixVerdict.accepted) {
      _rejected.update(verdict, (n) => n + 1, ifAbsent: () => 1);
      return;
    }
    _breadcrumb.add(f);
    _buffer.add(f);
    if (_buffer.length > maxBuffered) _buffer.removeAt(0);
    _accepted.add(f);
    if (_buffer.length >= batchSize) unawaited(flush());
  }

  /// Writes buffered fixes. On failure they stay buffered for the next try.
  Future<void> flush() async {
    if (_buffer.isEmpty) return;
    final batch = List<LocationFix>.of(_buffer);
    try {
      await _sink(batch);
      _buffer.removeRange(0, batch.length.clamp(0, _buffer.length));
    } on Object catch (e) {
      _log.warn('tracking', 'could not write ${batch.length} fixes', error: e);
    }
  }

  /// Flushes and stops the hardware.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await flush();
    await _location.stop();
  }
}
