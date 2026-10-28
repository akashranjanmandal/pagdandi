import 'package:core_common/core_common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/permissions/battery_guide.dart';

void main() {
  test('Xiaomi family gets Autostart and No restrictions steps', () {
    for (final m in ['Xiaomi', 'xiaomi', 'Redmi', 'POCO']) {
      final g = BatteryGuide.forManufacturer(m);
      expect(g.brand, 'Xiaomi', reason: m);
      expect(g.steps.join(' '), contains('Autostart'));
      expect(g.steps.join(' '), contains('No restrictions'));
    }
  });

  test('each named brand maps to its own guide', () {
    expect(BatteryGuide.forManufacturer('samsung').brand, 'Samsung');
    expect(BatteryGuide.forManufacturer('realme').brand, 'Realme');
    expect(BatteryGuide.forManufacturer('OPPO').brand, 'Oppo');
    expect(BatteryGuide.forManufacturer('OnePlus').brand, 'OnePlus');
    expect(BatteryGuide.forManufacturer('vivo').brand, 'Vivo');
    expect(BatteryGuide.forManufacturer('iQOO').brand, 'Vivo');
  });

  test('unknown or missing manufacturer gets the general steps', () {
    expect(BatteryGuide.forManufacturer('Fairphone').brand, 'Android');
    expect(BatteryGuide.forManufacturer(null).brand, 'Android');
    expect(BatteryGuide.forManufacturer('').brand, 'Android');
  });

  test('every guide has steps and names the app from the one definition', () {
    for (final m in [
      'xiaomi',
      'samsung',
      'realme',
      'oppo',
      'oneplus',
      'vivo',
      'other',
      null,
    ]) {
      final g = BatteryGuide.forManufacturer(m);
      expect(g.steps, isNotEmpty);
      expect(g.steps.join(' '), contains(kAppName), reason: '$m');
    }
  });

  test('never claims the setting was checked', () {
    final text = BatteryGuide.forManufacturer('xiaomi').steps.join(' ');
    expect(text.toLowerCase(), isNot(contains('verified')));
  });
}
