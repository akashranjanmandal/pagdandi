import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';
import 'package:trek_core/trek_core.dart';

class _Log implements Logger {
  final lines = <String>[];
  @override
  void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => lines.add('${level.name}: $message');
}

const g = 9.80665;

void main() {
  late FakeAccelerometer accel;
  late _Log log;
  var falls = 0;
  late FallWatcher watcher;
  var t = Duration.zero;

  void feed(double z) {
    accel.emit(AccelSample(x: 0, y: 0, z: z, at: t));
    t += const Duration(milliseconds: 40);
  }

  void fallThenStill() {
    for (var i = 0; i < 5; i++) {
      feed(1);
    }
    feed(40);
    for (var i = 0; i < 25 * 32; i++) {
      feed(g);
    }
  }

  setUp(() {
    accel = FakeAccelerometer();
    log = _Log();
    falls = 0;
    t = Duration.zero;
    watcher = FallWatcher(
      accelerometer: accel,
      onFall: () async => falls++,
      logger: log,
    );
  });
  tearDown(() => watcher.stop());

  test('does nothing, and asks for no sensor, until started', () {
    expect(watcher.running, isFalse);
    expect(accel.periods, isEmpty);
  });

  test('starting asks for 25 samples a second', () {
    watcher.start();
    expect(watcher.running, isTrue);
    expect(accel.periods, [const Duration(milliseconds: 40)]);
  });

  test('a fall followed by stillness is reported once', () {
    watcher.start();
    fallThenStill();
    expect(falls, 1);
  });

  test('walking is not a fall', () {
    watcher.start();
    for (var i = 0; i < 25 * 60; i++) {
      feed(g + 6 * (i.isEven ? 1 : -1));
    }
    expect(falls, 0);
  });

  test('stopping stops listening and forgets a half-seen fall', () {
    watcher.start();
    for (var i = 0; i < 5; i++) {
      feed(1);
    }
    feed(40);
    watcher.stop();
    expect(watcher.running, isFalse);
    watcher.start();
    for (var i = 0; i < 25 * 40; i++) {
      feed(g);
    }
    expect(falls, 0, reason: 'a new run starts clean');
  });

  test('starting twice listens once', () {
    watcher
      ..start()
      ..start();
    expect(accel.periods, hasLength(1));
    fallThenStill();
    expect(falls, 1);
  });

  test('a failing handler is logged and detection carries on', () async {
    final w = FallWatcher(
      accelerometer: accel,
      onFall: () async => throw StateError('runtime busy'),
      logger: log,
    )..start();
    fallThenStill();
    await pumpEventQueue();
    expect(log.lines.any((l) => l.contains('fall countdown')), isTrue);
    w.stop();
  });

  test(
    'a sensor stream that ends (no accelerometer) is noted, not fatal',
    () async {
      final c = StreamController<AccelSample>();
      final w = FallWatcher(
        accelerometer: _Stream(c.stream),
        onFall: () async => falls++,
        logger: log,
      )..start();
      await c.close();
      await pumpEventQueue();
      expect(w.running, isFalse);
      expect(log.lines.any((l) => l.contains('no accelerometer')), isTrue);
    },
  );

  test('a sensor stream that errors is noted, not fatal', () async {
    final c = StreamController<AccelSample>();
    final w = FallWatcher(
      accelerometer: _Stream(c.stream),
      onFall: () async => falls++,
      logger: log,
    )..start();
    c.addError(StateError('sensor died'));
    await pumpEventQueue();
    expect(w.running, isFalse);
    await c.close();
  });
}

class _Stream implements Accelerometer {
  _Stream(this._s);
  final Stream<AccelSample> _s;
  @override
  Stream<AccelSample> samples(Duration period) => _s;
}
