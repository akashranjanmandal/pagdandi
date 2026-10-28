import 'package:flutter_test/flutter_test.dart';
import 'package:pagdandi_app/permissions/permission_service.dart';

class _Api implements PermissionApi {
  final granted = <String>{};
  final asked = <String>[];
  final allow = <String>{};
  bool settingsOpened = false;
  final permanent = <String>{};

  @override
  Future<bool> isPermanentlyDenied(String name) async =>
      permanent.contains(name);

  @override
  Future<bool> isGranted(String name) async => granted.contains(name);

  @override
  Future<bool> request(String name) async {
    asked.add(name);
    if (allow.contains(name)) granted.add(name);
    return granted.contains(name);
  }

  @override
  Future<void> openSettings() async => settingsOpened = true;
}

void main() {
  late _Api api;
  late PermissionService svc;

  setUp(() {
    api = _Api();
    svc = PlatformPermissionService(api);
  });

  test('reports exactly what is granted', () async {
    api.granted.addAll(['location', 'sms']);
    expect(await svc.granted(), {AppPermission.location, AppPermission.sms});
  });

  test('requesting a granted permission does not ask again', () async {
    api.granted.add('sms');
    expect(await svc.request(AppPermission.sms), isTrue);
    expect(api.asked, isEmpty);
  });

  test('a denied permission returns false', () async {
    expect(await svc.request(AppPermission.sms), isFalse);
  });

  test('background location is asked only after foreground location', () async {
    api.allow.addAll(['location', 'backgroundLocation']);
    expect(await svc.request(AppPermission.backgroundLocation), isTrue);
    expect(api.asked, ['location', 'backgroundLocation']);
  });

  test('background location is not asked when foreground is refused', () async {
    expect(await svc.request(AppPermission.backgroundLocation), isFalse);
    expect(api.asked, ['location']);
  });

  test('reports a permanently denied permission', () async {
    api.permanent.add('sms');
    expect(await svc.isPermanentlyDenied(AppPermission.sms), isTrue);
    expect(await svc.isPermanentlyDenied(AppPermission.location), isFalse);
  });

  test('a granted permission is never permanently denied', () async {
    api
      ..granted.add('sms')
      ..permanent.add('sms');
    expect(await svc.isPermanentlyDenied(AppPermission.sms), isFalse);
  });

  test('a platform error is not treated as permanent denial', () async {
    final broken = PlatformPermissionService(_Throwing());
    expect(await broken.isPermanentlyDenied(AppPermission.sms), isFalse);
  });

  test('can open the system settings for a permanently denied item', () async {
    await svc.openSettings();
    expect(api.settingsOpened, isTrue);
  });

  test('a platform error counts as not granted, never a crash', () async {
    final broken = PlatformPermissionService(_Throwing());
    expect(await broken.granted(), isEmpty);
    expect(await broken.request(AppPermission.sms), isFalse);
  });
}

class _Throwing implements PermissionApi {
  @override
  Future<bool> isPermanentlyDenied(String name) async => throw StateError('x');
  @override
  Future<bool> isGranted(String name) async => throw StateError('x');
  @override
  Future<bool> request(String name) async => throw StateError('x');
  @override
  Future<void> openSettings() async => throw StateError('x');
}
