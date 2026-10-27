import 'dart:async';

import 'package:core_common/core_common.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';

StreamController<T> _sync<T>() => StreamController<T>.broadcast(sync: true);

/// Fake GPS receiver. Call [emit] to deliver a fix.
class FakeLocationSource implements LocationSource {
  final StreamController<LocationFix> _c = _sync<LocationFix>();

  /// Every request made, oldest first.
  final requests = <LocationRequest>[];

  /// True between a request and a stop.
  bool isRunning = false;

  @override
  Stream<LocationFix> get fixes => _c.stream;

  @override
  Future<void> request(LocationRequest request) async {
    requests.add(request);
    isRunning = true;
  }

  @override
  Future<void> stop() async => isRunning = false;

  /// Delivers [fix] to listeners.
  void emit(LocationFix fix) => _c.add(fix);
}

/// Fake significant-motion sensor.
class FakeMotionSensor implements MotionSensor {
  final StreamController<void> _c = _sync<void>();

  @override
  Stream<void> get significantMotion => _c.stream;

  /// Signals significant motion.
  void trigger() => _c.add(null);
}

/// Fake accelerometer. Call [emit] to deliver a sample.
class FakeAccelerometer implements Accelerometer {
  final StreamController<AccelSample> _c = _sync<AccelSample>();

  /// Sampling periods requested, oldest first.
  final periods = <Duration>[];

  @override
  Stream<AccelSample> samples(Duration period) {
    periods.add(period);
    return _c.stream;
  }

  /// Delivers [sample].
  void emit(AccelSample sample) => _c.add(sample);
}

/// Fake barometer. Call [emit] to deliver a reading.
class FakeBarometer implements Barometer {
  final StreamController<PressureSample> _c = _sync<PressureSample>();

  @override
  Stream<PressureSample> get readings => _c.stream;

  /// Delivers [sample].
  void emit(PressureSample sample) => _c.add(sample);
}

/// Fake mobile signal. Starts with no service.
class FakeSignalMonitor implements SignalMonitor {
  final StreamController<SignalState> _c = _sync<SignalState>();
  SignalState _state = SignalState.noService;

  @override
  SignalState get current => _state;

  @override
  Stream<SignalState> get changes => _c.stream;

  /// Changes the state and notifies listeners.
  void set(SignalState state) {
    _state = state;
    _c.add(state);
  }
}

/// Fake source of GPS time tied to a [Clock]'s monotonic time.
class FakeGpsTimeSource implements GpsTimeSource {
  /// Creates a source that stamps readings with the clock's monotonic time.
  FakeGpsTimeSource(this._clock);

  final Clock _clock;
  GpsTimeReading? _latest;

  @override
  GpsTimeReading? get latest => _latest;

  /// Records that GPS reported [gpsTime] just now.
  void receive(DateTime gpsTime) => _latest = GpsTimeReading(
    gpsTime: gpsTime,
    monotonicAtReading: _clock.elapsed(),
  );

  /// Forgets any reading (fix lost for good).
  void clear() => _latest = null;
}
