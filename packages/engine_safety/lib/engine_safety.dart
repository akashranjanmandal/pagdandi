/// The safety kernel. Depends on core packages only, so a failure anywhere
/// else can never stop SOS, the SMS outbox, torch/siren or fall detection.
library;

export 'src/backoff.dart';
export 'src/fall_detector.dart';
export 'src/sos_kernel.dart';
export 'src/sos_message.dart';
