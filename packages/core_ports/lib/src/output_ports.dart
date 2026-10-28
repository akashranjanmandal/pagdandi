import 'package:core_model/core_model.dart';

/// Vibration motor.
abstract interface class HapticOutput {
  /// Plays [pattern]; a repeating pattern runs until [cancel].
  Future<void> play(HapticPattern pattern);

  /// Stops any running pattern.
  Future<void> cancel();
}

/// Camera torch.
abstract interface class TorchOutput {
  /// Steady light on or off.
  Future<void> setOn({required bool on});

  /// SOS strobe on or off.
  Future<void> setStrobe({required bool on});
}

/// Loud siren on the alarm stream (works in silent mode).
// A port is a deliberate one-method interface: fakes and adapters implement it.
// ignore: one_member_abstracts
abstract interface class SirenOutput {
  /// Starts or stops the siren.
  Future<void> setOn({required bool on});
}

/// Speaks short alerts (English), after a soft chime.
abstract interface class VoiceOutput {
  /// Says [text]. An [urgent] line interrupts whatever is being said.
  Future<void> speak(String text, {bool urgent = false});

  /// Stops speaking.
  Future<void> stop();
}

/// Opens the phone dialer with a number filled in. It never places the call:
/// the person presses the call key.
// A port is a deliberate one-method interface: fakes and adapters implement it.
// ignore: one_member_abstracts
abstract interface class Dialer {
  /// Opens the dialer for [number].
  Future<void> open(String number);
}

/// Exact alarms (check-in timer, fall countdown).
abstract interface class AlarmScheduler {
  /// Alarm ids as they fire.
  Stream<int> get fired;

  /// Schedules an exact alarm; replaces an existing alarm with the same [id].
  Future<void> schedule(int id, DateTime at);

  /// Cancels the alarm.
  Future<void> cancel(int id);
}

/// Battery level.
abstract interface class BatteryMonitor {
  /// Level in percent, 0 to 100.
  int get level;

  /// Level changes.
  Stream<int> get changes;
}
