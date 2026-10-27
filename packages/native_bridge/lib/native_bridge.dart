/// Pigeon bridge to the Kotlin plugin `pagdandi_native`, exposed as core_ports.
library;

export 'src/adapters.dart';
export 'src/generated/native_api.g.dart'
    show DeviceCapabilities, HapticRequest, PagdandiFlutterApi, PagdandiHostApi;
