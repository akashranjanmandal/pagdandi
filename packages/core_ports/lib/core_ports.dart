/// Abstract hardware interfaces. Engines reach hardware only through these.
library;

export 'package:core_common/core_common.dart' show Clock, GpsTimeSource;

export 'src/audio_ports.dart';
export 'src/channel_ports.dart';
export 'src/comms_ports.dart';
export 'src/outbox_store.dart';
export 'src/output_ports.dart';
export 'src/sensor_ports.dart';
export 'src/service_ports.dart';
export 'src/snapshot_store.dart';
