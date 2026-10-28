import 'package:core_common/core_common.dart';
import 'package:meta/meta.dart';

/// What to tell a user so their phone does not stop the trek in the
/// background. Pagdandi cannot check these settings, so the text only says
/// what to do, never that it was done.
@immutable
class BatteryGuide {
  const BatteryGuide._(this.brand, this.steps);

  /// The guide for a phone [manufacturer] (as Android reports it), or the
  /// general one.
  factory BatteryGuide.forManufacturer(String? manufacturer) {
    final m = (manufacturer ?? '').trim().toLowerCase();
    if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) {
      return const BatteryGuide._('Xiaomi', [
        'Open Settings, then Apps, then Manage apps, then $kAppName.',
        'Turn on Autostart.',
        'Tap Battery saver and choose No restrictions.',
      ]);
    }
    if (m.contains('samsung')) {
      return const BatteryGuide._('Samsung', [
        'Open Settings, then Battery, then Background usage limits.',
        'Tap Never sleeping apps and add $kAppName.',
      ]);
    }
    if (m.contains('realme')) {
      return const BatteryGuide._('Realme', _colorOs);
    }
    if (m.contains('oppo')) return const BatteryGuide._('Oppo', _colorOs);
    if (m.contains('oneplus')) {
      return const BatteryGuide._('OnePlus', _colorOs);
    }
    if (m.contains('vivo') || m.contains('iqoo')) {
      return const BatteryGuide._('Vivo', [
        'Open Settings, then Battery, then Background power consumption.',
        'Find $kAppName and choose Allow.',
        'In i Manager, open App manager, then Autostart, and allow $kAppName.',
      ]);
    }
    return const BatteryGuide._('Android', [
      'Open Settings, then Apps, then $kAppName, then Battery.',
      'Choose Unrestricted (or Don’t optimise).',
    ]);
  }

  static const _colorOs = [
    'Open Settings, then Battery, then App battery management.',
    'Find $kAppName and allow background activity.',
    'Also allow auto launch for $kAppName.',
  ];

  /// Brand name, or "Android" for the general guide.
  final String brand;

  /// What to do, in order.
  final List<String> steps;
}
