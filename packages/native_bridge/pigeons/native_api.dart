// Pigeon definitions cannot use named parameters.
// ignore_for_file: avoid_positional_boolean_parameters

// Pigeon definition of the typed bridge to the Kotlin plugin `pagdandi_native`.
// Regenerate with `melos run pigeon` (never edit the generated files).
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/generated/native_api.g.dart',
    dartPackageName: 'native_bridge',
    kotlinOut:
        'android/src/main/kotlin/app/pagdandi/pagdandi_native/NativeApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'app.pagdandi.pagdandi_native'),
  ),
)
/// What the phone's hardware supports.
class DeviceCapabilities {
  DeviceCapabilities({
    required this.sdkInt,
    required this.leCodedPhySupported,
    required this.leExtendedAdvertisingSupported,
    required this.hasBarometer,
    required this.hasSignificantMotion,
  });

  int sdkInt;
  bool leCodedPhySupported;
  bool leExtendedAdvertisingSupported;
  bool hasBarometer;
  bool hasSignificantMotion;
}

/// A vibration waveform: [delay, on, off, on, ...] in milliseconds.
class HapticRequest {
  HapticRequest({
    required this.timings,
    required this.repeat,
    required this.strong,
  });

  List<int> timings;
  bool repeat;
  bool strong;
}

/// Mobile network availability.
enum SignalStateDto { noService, emergencyOnly, inService }

/// Progress of an outgoing SMS as the radio reports it.
enum SmsStatusDto { sending, sent, delivered, failed }

/// What the app asks of the location hardware.
class LocationRequestDto {
  LocationRequestDto({
    required this.intervalMs,
    required this.maxBatchDelayMs,
    required this.minDistanceM,
  });

  int intervalMs;
  int maxBatchDelayMs;
  double minDistanceM;
}

/// One GPS fix. [timeMs] is the GPS time in milliseconds since the epoch.
class LocationFixDto {
  LocationFixDto({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.timeMs,
    this.altitudeM,
    this.speedMps,
    this.bearingDeg,
  });

  double latitude;
  double longitude;
  double accuracyM;
  int timeMs;
  double? altitudeM;
  double? speedMps;
  double? bearingDeg;
}

/// What the phone currently allows, for the health watchdog.
class HealthSnapshotDto {
  HealthSnapshotDto({
    required this.locationPermission,
    required this.backgroundLocationPermission,
    required this.smsPermission,
    required this.notificationPermission,
    required this.batteryOptimizationExempt,
    required this.storageFreeMb,
  });

  bool locationPermission;
  bool backgroundLocationPermission;
  bool smsPermission;
  bool notificationPermission;
  bool batteryOptimizationExempt;
  int storageFreeMb;
}

/// Calls from Dart into Kotlin.
@HostApi()
abstract class PagdandiHostApi {
  DeviceCapabilities deviceCapabilities();

  /// Battery level in percent, 0 to 100.
  int batteryLevel();

  void playHaptic(HapticRequest request);

  void cancelHaptic();

  /// Hands an SMS to the radio; progress arrives via onSmsReport.
  void sendSms(String id, String to, String body);

  SignalStateDto signalState();

  /// Starts location updates (replaces any earlier request).
  void startLocation(LocationRequestDto request);

  void stopLocation();

  /// The SQLite file shared by the Dart core and the native guard.
  String databasePath();

  /// The Dart core is alive; [atMs] is the time of this beat.
  void heartbeat(int atMs);

  /// Starts the foreground trek service (only from a user action).
  void startTrekService();

  /// Stops the trek service and ends the trek.
  void stopTrekService();

  HealthSnapshotDto healthSnapshot();

  /// Registers this engine as "ui" or "core" for the command/state relay.
  void setRole(String role);

  /// UI to core: a command as JSON. Queued until the core is up.
  void sendCommand(String json);

  /// Core to UI: the latest state as JSON.
  void publishState(String json);

  /// Camera torch: steady when [strobe] is false, SOS strobe when true.
  void setTorch(bool on, bool strobe);

  /// Loud siren on the alarm stream (works in silent mode).
  void setSiren(bool on);

  /// Opens the phone dialer with [number] filled in (the user presses call).
  void openDialer(String number);

  /// Schedules an exact alarm at [atMs] (system clock, ms since the epoch).
  void scheduleAlarm(int id, int atMs);

  /// Cancels an alarm.
  void cancelAlarm(int id);

  /// Alarms that fired while the core was not running; each is returned once.
  List<int> takeFiredAlarms();

  /// Speaks [text] in English. An [urgent] line interrupts what is being said.
  void speak(String text, bool urgent);

  /// Stops speaking.
  void stopSpeaking();

  /// Starts accelerometer batches roughly every [periodMs] (fall detection).
  /// Returns false when the phone has no accelerometer.
  bool startAccelerometer(int periodMs);

  /// Stops the accelerometer.
  void stopAccelerometer();
}

/// Calls from Kotlin into Dart.
@FlutterApi()
abstract class PagdandiFlutterApi {
  void onBatteryLevel(int level);

  void onSmsReport(String id, SmsStatusDto status);

  void onSignalState(SignalStateDto state);

  /// A batch of fixes, oldest first.
  void onLocations(List<LocationFixDto> fixes);

  /// Core engine: a command from the UI.
  void onCommand(String json);

  /// UI engine: the core's latest state.
  void onState(String json);

  /// Core engine: an exact alarm fired.
  void onAlarm(int id);

  /// Core engine: accelerometer samples as flat groups of [x, y, z, timeMs]
  /// (m/s^2 and monotonic milliseconds), oldest first.
  void onAccelerometer(List<double> batch);
}
