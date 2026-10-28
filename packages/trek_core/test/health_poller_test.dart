// fakeAsync runs scheduled work synchronously: no await needed.

import 'package:core_common/core_common.dart';
import 'package:engine_health/engine_health.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
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
  }) => lines.add('${level.name}:$message');
}

HealthInputs inputs(int n) => HealthInputs(
  now: DateTime.utc(2026, 10, 27, 14).add(Duration(seconds: n)),
  trekActive: false,
  trekStartedAt: null,
  lastFixAt: null,
  locationPermission: true,
  backgroundLocationPermission: true,
  smsPermission: true,
  batteryOptimizationExempt: true,
  storageFreeMb: 5000,
  batteryPercent: 80,
);

void main() {
  test('reads once at start, then every period', () {
    fakeAsync((async) {
      var reads = 0;
      final got = <HealthInputs>[];
      HealthPoller(
        read: () async => inputs(reads++),
        onInputs: got.add,
        logger: _Log(),
      ).start();
      async.flushMicrotasks();
      expect(got, hasLength(1));
      async.elapse(const Duration(seconds: 30));
      expect(got, hasLength(2));
      async.elapse(const Duration(seconds: 60));
      expect(got, hasLength(4));
    });
  });

  test('a failing read is logged and polling continues', () {
    fakeAsync((async) {
      var calls = 0;
      final got = <HealthInputs>[];
      final log = _Log();
      HealthPoller(
        read: () async {
          calls++;
          if (calls == 1) throw StateError('host gone');
          return inputs(calls);
        },
        onInputs: got.add,
        logger: log,
      ).start();
      async.flushMicrotasks();
      expect(got, isEmpty);
      expect(log.lines.where((l) => l.startsWith('warn')), hasLength(1));
      async.elapse(const Duration(seconds: 30));
      expect(got, hasLength(1));
    });
  });

  test('stop ends polling; starting twice does not double it', () {
    fakeAsync((async) {
      final got = <HealthInputs>[];
      final p =
          HealthPoller(
              read: () async => inputs(0),
              onInputs: got.add,
              logger: _Log(),
            )
            ..start()
            ..start();
      async.elapse(const Duration(seconds: 30));
      expect(got, hasLength(2));
      p.stop();
      async.elapse(const Duration(minutes: 5));
      expect(got, hasLength(2));
    });
  });

  test('stop without start is harmless', () {
    HealthPoller(
      read: () async => inputs(0),
      onInputs: (_) {},
      logger: _Log(),
    ).stop();
  });
}
