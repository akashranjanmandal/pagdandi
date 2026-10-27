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

/// Calls from Dart into Kotlin.
@HostApi()
abstract class PagdandiHostApi {
  DeviceCapabilities deviceCapabilities();

  /// Battery level in percent, 0 to 100.
  int batteryLevel();

  void playHaptic(HapticRequest request);

  void cancelHaptic();
}

/// Calls from Kotlin into Dart.
@FlutterApi()
abstract class PagdandiFlutterApi {
  void onBatteryLevel(int level);
}
