import 'package:core_model/core_model.dart';
import 'package:test/test.dart';

void main() {
  test('no service: neither SMS nor 112', () {
    expect(SignalState.noService.canSendSms, isFalse);
    expect(SignalState.noService.canCallEmergency, isFalse);
  });

  test('emergency only: 112 works, SMS does not', () {
    expect(SignalState.emergencyOnly.canSendSms, isFalse);
    expect(SignalState.emergencyOnly.canCallEmergency, isTrue);
  });

  test('in service: both work', () {
    expect(SignalState.inService.canSendSms, isTrue);
    expect(SignalState.inService.canCallEmergency, isTrue);
  });
}
