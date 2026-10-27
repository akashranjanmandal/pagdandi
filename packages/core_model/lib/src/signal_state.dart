/// Mobile network availability.
enum SignalState {
  /// No network at all.
  noService(canSendSms: false, canCallEmergency: false),

  /// Only emergency calls (112) are possible.
  emergencyOnly(canSendSms: false, canCallEmergency: true),

  /// Normal service.
  inService(canSendSms: true, canCallEmergency: true);

  const SignalState({required this.canSendSms, required this.canCallEmergency});

  /// Whether an SMS can be sent now.
  final bool canSendSms;

  /// Whether a 112 call can be placed now.
  final bool canCallEmergency;
}
