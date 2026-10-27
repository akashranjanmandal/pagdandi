import 'package:core_model/core_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_bridge/native_bridge.dart';

class _Host extends PagdandiHostApi {
  int battery = 77;
  DeviceCapabilities caps = DeviceCapabilities(
    sdkInt: 34,
    leCodedPhySupported: true,
    leExtendedAdvertisingSupported: false,
    hasBarometer: true,
    hasSignificantMotion: false,
  );
  final haptics = <HapticRequest>[];
  int cancels = 0;

  @override
  Future<int> batteryLevel() async => battery;

  @override
  Future<DeviceCapabilities> deviceCapabilities() async => caps;

  @override
  Future<void> playHaptic(HapticRequest request) async => haptics.add(request);

  @override
  Future<void> cancelHaptic() async => cancels++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeBatteryMonitor', () {
    test('reads the initial level from the host', () async {
      final m = await NativeBatteryMonitor.create(_Host());
      expect(m.level, 77);
    });

    test('updates level and emits changes when the host reports one', () async {
      final m = await NativeBatteryMonitor.create(_Host());
      final seen = <int>[];
      m.changes.listen(seen.add);
      m.onBatteryLevel(41);
      expect(m.level, 41);
      expect(seen, [41]);
    });

    test('clamps nonsense values into 0..100', () async {
      final m = await NativeBatteryMonitor.create(_Host());
      m.onBatteryLevel(140);
      expect(m.level, 100);
      m.onBatteryLevel(-3);
      expect(m.level, 0);
    });
  });

  group('NativeHapticOutput', () {
    test('sends the waveform of the pattern to the host', () async {
      final host = _Host();
      await NativeHapticOutput(host).play(HapticPattern.junction);
      final r = host.haptics.single;
      expect(r.timings, HapticPattern.junction.waveform);
      expect(r.repeat, isFalse);
      expect(r.strong, isFalse);
    });

    test('passes repeat and strong flags', () async {
      final host = _Host();
      final out = NativeHapticOutput(host);
      await out.play(HapticPattern.sos);
      await out.play(HapticPattern.holdComplete);
      expect(host.haptics[0].repeat, isTrue);
      expect(host.haptics[1].strong, isTrue);
    });

    test('cancel is forwarded', () async {
      final host = _Host();
      await NativeHapticOutput(host).cancel();
      expect(host.cancels, 1);
    });
  });

  group('beaconCapabilitiesFrom', () {
    test('maps coded PHY and extended advertising support', () async {
      final caps = await _Host().deviceCapabilities();
      final b = beaconCapabilitiesFrom(caps);
      expect(b.codedPhy, isTrue);
      expect(b.extendedAdvertising, isFalse);
    });
  });
}
