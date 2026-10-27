import 'dart:math';

import 'package:testing/src/fake_clock.dart';
import 'package:testing/src/fake_outputs.dart';
import 'package:testing/src/fake_sensors.dart';
import 'package:testing/src/fake_transport.dart';
import 'package:testing/src/sim_scheduler.dart';

/// One virtual phone: a full set of fakes sharing the world's clock.
class VirtualPhone {
  VirtualPhone._(this.id, this.clock, this.transport)
    : alarms = FakeAlarmScheduler(clock),
      gpsTime = FakeGpsTimeSource(clock);

  /// Member id.
  final String id;

  /// The shared world clock.
  final FakeClock clock;

  /// Radio link to other phones.
  final FakeTransport transport;

  /// GPS receiver.
  final location = FakeLocationSource();

  /// Significant-motion sensor.
  final motion = FakeMotionSensor();

  /// Accelerometer.
  final accelerometer = FakeAccelerometer();

  /// Barometer.
  final barometer = FakeBarometer();

  /// Mobile signal.
  final signal = FakeSignalMonitor();

  /// Vibration motor.
  final haptic = FakeHapticOutput();

  /// Torch.
  final torch = FakeTorchOutput();

  /// Siren.
  final siren = FakeSirenOutput();

  /// Battery.
  final battery = FakeBatteryMonitor();

  /// Voice output.
  final audio = FakeAudioOutput();

  /// Push-to-talk audio.
  final ptt = FakePttAudio();

  /// SMS radio.
  final sms = FakeSmsGateway();

  /// BLE beacon.
  final beacon = FakeBeaconTransport();

  /// Exact alarms.
  final FakeAlarmScheduler alarms;

  /// GPS time.
  final FakeGpsTimeSource gpsTime;
}

/// Several virtual phones on one fake clock and one simulated radio medium.
class SimWorld {
  /// Creates a world starting at [start]. [seed] makes it reproducible.
  SimWorld({
    required DateTime start,
    required int seed,
    double rangeM = 100,
    double lossRate = 0,
    double duplicateRate = 0,
    Duration latency = const Duration(milliseconds: 50),
    Duration jitter = Duration.zero,
  }) : clock = FakeClock(start) {
    sim = SimScheduler(clock);
    network = FakeTransportNetwork(
      sim,
      random: Random(seed),
      rangeM: rangeM,
      lossRate: lossRate,
      duplicateRate: duplicateRate,
      latency: latency,
      jitter: jitter,
    );
  }

  /// The single clock all phones share.
  final FakeClock clock;

  /// Event scheduler.
  late final SimScheduler sim;

  /// Radio medium.
  late final FakeTransportNetwork network;

  final _phones = <String, VirtualPhone>{};

  /// All phones by id.
  Map<String, VirtualPhone> get phones => Map.unmodifiable(_phones);

  /// Adds a phone at ([x], [y]) metres.
  VirtualPhone addPhone(String id, {required double x, required double y}) {
    if (_phones.containsKey(id)) {
      throw ArgumentError.value(id, 'id', 'already used');
    }
    final phone = VirtualPhone._(id, clock, network.node(id, x: x, y: y));
    _phones[id] = phone;
    return phone;
  }

  /// Runs the world for [d] of simulated time.
  void run(Duration d) => sim.runFor(d);
}
