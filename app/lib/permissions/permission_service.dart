import 'package:permission_handler/permission_handler.dart';

/// The permissions Pagdandi needs.
enum AppPermission {
  /// Location while the app is open.
  location,

  /// Location with the screen off.
  backgroundLocation,

  /// Sending SOS texts.
  sms,

  /// Showing the trek notification.
  notifications,
}

/// Asks for and reports permissions. Screens use this; they never touch the
/// platform plugin.
abstract interface class PermissionService {
  /// Everything currently granted.
  Future<Set<AppPermission>> granted();

  /// Asks for [permission]; true when it ends up granted.
  Future<bool> request(AppPermission permission);

  /// Whether the system will no longer show a prompt for [permission]
  /// (denied for good). Only the system settings can change that.
  Future<bool> isPermanentlyDenied(AppPermission permission);

  /// Opens the system settings page of the app.
  Future<void> openSettings();
}

/// The few platform calls the service needs, by permission name.
abstract interface class PermissionApi {
  /// Whether [name] is granted.
  Future<bool> isGranted(String name);

  /// Shows the system prompt for [name]; true when granted.
  Future<bool> request(String name);

  /// Whether [name] was denied for good.
  Future<bool> isPermanentlyDenied(String name);

  /// Opens the system settings page of the app.
  Future<void> openSettings();
}

/// [PermissionService] with the Android ordering rule and fail-safe errors.
class PlatformPermissionService implements PermissionService {
  /// Creates the service.
  PlatformPermissionService(this._api);

  final PermissionApi _api;

  @override
  Future<Set<AppPermission>> granted() async {
    final result = <AppPermission>{};
    for (final p in AppPermission.values) {
      try {
        if (await _api.isGranted(p.name)) result.add(p);
      } on Object {
        // Unknown counts as not granted: the screen then offers the fix.
      }
    }
    return result;
  }

  @override
  Future<bool> request(AppPermission permission) async {
    try {
      if (await _api.isGranted(permission.name)) return true;
      // Android only offers background location after foreground location.
      if (permission == AppPermission.backgroundLocation &&
          !await _api.request(AppPermission.location.name)) {
        return false;
      }
      return await _api.request(permission.name);
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> isPermanentlyDenied(AppPermission permission) async {
    try {
      if (await _api.isGranted(permission.name)) return false;
      return await _api.isPermanentlyDenied(permission.name);
    } on Object {
      return false;
    }
  }

  @override
  Future<void> openSettings() async {
    try {
      await _api.openSettings();
    } on Object {
      // Nothing more can be done.
    }
  }
}

/// [PermissionApi] backed by the permission_handler plugin.
class HandlerPermissionApi implements PermissionApi {
  /// Creates the API.
  const HandlerPermissionApi();

  Permission _of(String name) => switch (name) {
    'location' => Permission.locationWhenInUse,
    'backgroundLocation' => Permission.locationAlways,
    'sms' => Permission.sms,
    'notifications' => Permission.notification,
    _ => throw ArgumentError.value(name, 'name'),
  };

  @override
  Future<bool> isGranted(String name) => _of(name).isGranted;

  @override
  Future<bool> request(String name) async =>
      (await _of(name).request()).isGranted;

  @override
  Future<bool> isPermanentlyDenied(String name) =>
      _of(name).isPermanentlyDenied;

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
