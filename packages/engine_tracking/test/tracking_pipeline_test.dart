import 'package:core_common/core_common.dart';
import 'package:core_geo/core_geo.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_tracking/engine_tracking.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

class _Log implements Logger {
  final lines = <String>[];
  @override
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => lines.add('${level.name}:$message');
}

final t0 = DateTime.utc(2026, 10, 27, 9);
const origin = GeoPoint(27.036, 88.2627);

LocationFix at(double meters, int seconds, {double accuracy = 6}) {
  final p = destination(origin, bearing: 90, distanceM: meters);
  return LocationFix(
    latitude: p.lat,
    longitude: p.lon,
    accuracyM: accuracy,
    gpsTime: t0.add(Duration(seconds: seconds)),
  );
}

void main() {
  late FakeLocationSource gps;
  late List<List<LocationFix>> written;
  late _Log log;
  late TrackingPipeline pipe;
  Error? sinkError;

  setUp(() {
    gps = FakeLocationSource();
    written = [];
    sinkError = null;
    log = _Log();
    pipe = TrackingPipeline(
      location: gps,
      sink: (batch) async {
        if (sinkError != null) throw sinkError!;
        written.add(List.of(batch));
      },
      logger: log,
      batchSize: 3,
      maxBuffered: 5,
    );
  });

  const request = LocationRequest(interval: Duration(seconds: 5));

  test('start asks the hardware for fixes with the given request', () async {
    await pipe.start(request);
    expect(gps.requests.single.interval, const Duration(seconds: 5));
    expect(gps.isRunning, isTrue);
  });

  test('accepted fixes go to the breadcrumb and the accepted stream', () async {
    await pipe.start(request);
    final seen = <LocationFix>[];
    pipe.accepted.listen(seen.add);
    gps
      ..emit(at(0, 0))
      ..emit(at(20, 10));
    expect(pipe.breadcrumb, hasLength(2));
    expect(seen, hasLength(2));
  });

  test('rejected fixes are counted by reason and not recorded', () async {
    await pipe.start(request);
    gps
      ..emit(at(0, 0))
      ..emit(at(2, 5)) // too close
      ..emit(at(500, 6)) // impossible speed
      ..emit(at(30, 15, accuracy: 90)); // poor accuracy
    expect(pipe.breadcrumb, hasLength(1));
    expect(pipe.rejected[FixVerdict.tooClose], 1);
    expect(pipe.rejected[FixVerdict.impossibleSpeed], 1);
    expect(pipe.rejected[FixVerdict.poorAccuracy], 1);
  });

  test('accepted fixes are written in batches, not one by one', () async {
    await pipe.start(request);
    gps
      ..emit(at(0, 0))
      ..emit(at(20, 10));
    await Future<void>.delayed(Duration.zero);
    expect(written, isEmpty, reason: 'batch of 3 not reached');
    gps.emit(at(40, 20));
    await Future<void>.delayed(Duration.zero);
    expect(written, hasLength(1));
    expect(written.single, hasLength(3));
  });

  test('flush writes whatever is buffered', () async {
    await pipe.start(request);
    gps.emit(at(0, 0));
    await pipe.flush();
    expect(written.single, hasLength(1));
    await pipe.flush();
    expect(written, hasLength(1), reason: 'nothing left to write');
  });

  test('stop flushes and stops the hardware', () async {
    await pipe.start(request);
    gps.emit(at(0, 0));
    await pipe.stop();
    expect(written.single, hasLength(1));
    expect(gps.isRunning, isFalse);
    gps.emit(at(50, 30));
    expect(pipe.breadcrumb, hasLength(1), reason: 'no longer listening');
  });

  test(
    'a failing sink keeps the points and retries them on the next flush',
    () async {
      await pipe.start(request);
      sinkError = StateError('disk full');
      gps.emit(at(0, 0));
      await pipe.flush();
      expect(written, isEmpty);
      expect(log.lines.any((l) => l.startsWith('warn')), isTrue);
      sinkError = null;
      gps.emit(at(20, 10));
      await pipe.flush();
      expect(written.single, hasLength(2));
    },
  );

  test(
    'the buffer is bounded when the sink keeps failing: oldest dropped',
    () async {
      await pipe.start(request);
      sinkError = StateError('disk full');
      for (var i = 0; i < 8; i++) {
        gps.emit(at(i * 20.0, i * 10));
        await Future<void>.delayed(Duration.zero);
      }
      sinkError = null;
      await pipe.flush();
      expect(written.single, hasLength(5));
      expect(written.single.first.gpsTime, t0.add(const Duration(seconds: 30)));
      expect(
        pipe.breadcrumb,
        hasLength(8),
        reason: 'memory breadcrumb is kept',
      );
    },
  );

  test(
    'seed restores the breadcrumb after a restart without re-writing it',
    () async {
      await pipe.start(request);
      pipe.seed([at(0, 0), at(20, 10)]);
      expect(pipe.breadcrumb, hasLength(2));
      await pipe.flush();
      expect(written, isEmpty);
      gps.emit(at(40, 20));
      expect(
        pipe.breadcrumb,
        hasLength(3),
        reason: 'filter baseline is the last seed',
      );
    },
  );

  test('restarting the pipeline replaces the request', () async {
    await pipe.start(request);
    await pipe.start(const LocationRequest(interval: Duration(seconds: 1)));
    expect(gps.requests.last.interval, const Duration(seconds: 1));
    gps.emit(at(0, 0));
    expect(pipe.breadcrumb, hasLength(1), reason: 'not subscribed twice');
  });

  test('stop when never started is harmless', () async {
    await pipe.stop();
    expect(gps.isRunning, isFalse);
  });
}
