import 'package:core_model/core_model.dart';
import 'package:test/test.dart';

void main() {
  test('AccelSample keeps its axes and time', () {
    const s = AccelSample(x: 1, y: -2, z: 9.8, at: Duration(seconds: 3));
    expect([s.x, s.y, s.z], [1, -2, 9.8]);
    expect(s.at, const Duration(seconds: 3));
  });

  test('PressureSample keeps pressure and time', () {
    const s = PressureSample(hPa: 1013.2, at: Duration(minutes: 1));
    expect(s.hPa, 1013.2);
    expect(s.at, const Duration(minutes: 1));
  });

  test('SMS values have consistent hash codes', () {
    expect(
      const SmsMessage(id: 'a', to: '1', body: 'x').hashCode,
      const SmsMessage(id: 'a', to: '1', body: 'x').hashCode,
    );
    expect(
      const SmsReport(id: 'a', status: SmsStatus.sent).hashCode,
      const SmsReport(id: 'a', status: SmsStatus.sent).hashCode,
    );
  });
}
