import 'dart:async';

import 'package:core_db/core_db.dart';
import 'package:core_model/core_model.dart';
import 'package:core_ports/core_ports.dart';
import 'package:engine_navigation/engine_navigation.dart';
import 'package:engine_trekstate/engine_trekstate.dart';
import 'package:flutter/foundation.dart';
import 'package:pagdandi_app/client/core_client.dart';
import 'package:pagdandi_app/models/readiness.dart';
import 'package:pagdandi_app/models/route_summary.dart';
import 'package:pagdandi_app/permissions/battery_guide.dart';
import 'package:pagdandi_app/permissions/permission_service.dart';
import 'package:pagdandi_app/routes/route_library.dart';
import 'package:trek_core/trek_core.dart';

/// Which top-level screen is showing.
enum AppRoute {
  /// First-run setup.
  setup,

  /// Readiness and Start trek.
  basecamp,

  /// A trek is running.
  trek,
}

/// Blood group, allergies and medicines a helper can read.
@immutable
class EmergencyCard {
  /// Creates a card.
  const EmergencyCard({
    this.bloodGroup = '',
    this.allergies = '',
    this.medicines = '',
  });

  /// e.g. "B+".
  final String bloodGroup;

  /// Free text.
  final String allergies;

  /// Free text.
  final String medicines;

  /// Whether anything is filled in.
  bool get isFilled =>
      bloodGroup.isNotEmpty || allergies.isNotEmpty || medicines.isNotEmpty;
}

/// Holds what the UI knows (settings, permissions, the core's state) and does
/// what the user asks. It decides nothing about safety: the core does.
class AppController extends ChangeNotifier {
  /// Creates the controller.
  AppController({
    required this._client,
    required this._settings,
    required this._permissions,
    required this._service,
    this._manufacturer,
    this._siren,
    this._torch,
    this._dialer,
    this._signal,
    this._routes,
    DateTime Function()? now,
    this._utcOffset,
  }) : _now = now ?? DateTime.now {
    _sub = _client.states.listen(_onCoreState);
    _signalSub = _signal?.changes.listen((_) => notifyListeners());
  }

  final CoreClient _client;
  final SettingsRepository _settings;
  final PermissionService _permissions;
  final TrekService _service;
  final Future<String?> Function()? _manufacturer;
  final SirenOutput? _siren;
  final TorchOutput? _torch;
  final Dialer? _dialer;
  final SignalMonitor? _signal;
  final RouteLibrary? _routes;
  final DateTime Function() _now;
  final Duration? _utcOffset;
  String? _routeId;
  Route? _route;
  StreamSubscription<SignalState>? _signalSub;
  bool _sirenOn = false;
  bool _torchOn = false;
  StreamSubscription<CoreStateMessage>? _sub;

  List<String> _batteryGuide = BatteryGuide.forManufacturer(null).steps;
  bool _setupDone = false;
  bool _leftHanded = false;
  int _setupStep = 0;
  List<String> _contacts = const [];
  String _name = '';
  EmergencyCard _card = const EmergencyCard();
  Set<AppPermission> _granted = const {};

  /// The permission the last [fix] could not get, so the screen can offer
  /// the system settings.
  ReadyItem? lastRefused;

  /// Routes the user can choose (empty without a library).
  List<RouteInfo> get routeOptions => _routes?.available ?? const [];

  /// The chosen route id, or null for a free trek.
  String? get selectedRouteId => _routeId;

  /// The chosen route, loaded, or null.
  Route? get selectedRoute => _route;

  /// What to tell about the chosen route today, or null on a free trek.
  RouteSummary? get routeSummary {
    final r = _route;
    if (r == null) return null;
    final now = _now();
    return RouteSummary.of(
      r,
      day: DateTime.utc(now.year, now.month, now.day),
      utcOffset: _utcOffset ?? now.timeZoneOffset,
    );
  }

  /// Whether the siren, torch and dialer exist. Their keys are shown only
  /// then: a key that does nothing is worse than no key.
  bool get toolsAvailable =>
      _siren != null && _torch != null && _dialer != null;

  /// Siren sounding.
  bool get sirenOn => _sirenOn;

  /// SOS torch strobe on.
  bool get torchOn => _torchOn;

  /// Any mobile signal, even emergency-only, which is enough for 112.
  bool get signalAvailable {
    final s = _signal?.current;
    return s == SignalState.inService || s == SignalState.emergencyOnly;
  }

  /// What to do so this phone does not stop the trek in the background.
  List<String> get batteryGuide => _batteryGuide;

  /// Left-handed layout, remembered across launches.
  bool get leftHanded => _leftHanded;

  /// The Setup step to resume at (0 on a first run).
  int get setupStep => _setupStep;

  /// Saved emergency contacts.
  List<String> get contacts => _contacts;

  /// What the group calls this person.
  String get name => _name;

  /// The emergency card.
  EmergencyCard get card => _card;

  /// The newest state from the core, if any.
  CoreStateMessage? get coreState => _client.latest;

  bool get _trekRunning {
    final s = _client.latest?.state;
    return s != null && s.activity.name != 'idle';
  }

  /// Where the app should be.
  AppRoute get route {
    if (!_setupDone) return AppRoute.setup;
    return _trekRunning ? AppRoute.trek : AppRoute.basecamp;
  }

  /// Whether the phone is ready for a trek.
  Readiness get readiness => Readiness(
    contactCount: _contacts.length,
    location: _granted.contains(AppPermission.location),
    sms: _granted.contains(AppPermission.sms),
    notifications: _granted.contains(AppPermission.notifications),
    backgroundLocation: _granted.contains(AppPermission.backgroundLocation),
    cardFilled: _card.isFilled,
    trekRunning: _trekRunning,
  );

  /// Loads everything saved and the current permissions.
  Future<void> load() async {
    _setupDone = await _settings.get('setup_done') == 'true';
    _leftHanded = await _settings.get('pref_left_handed') == 'true';
    _setupStep = int.tryParse(await _settings.get('setup_step') ?? '') ?? 0;
    final raw = await _settings.get('emergency_contacts') ?? '';
    _contacts = raw.isEmpty ? const [] : raw.split(',');
    _name = await _settings.get('member_name') ?? '';
    _card = EmergencyCard(
      bloodGroup: await _settings.get('card_blood_group') ?? '',
      allergies: await _settings.get('card_allergies') ?? '',
      medicines: await _settings.get('card_medicines') ?? '',
    );
    await _loadRoute(await _settings.get('active_route'));
    _granted = await _permissions.granted();
    try {
      _batteryGuide = BatteryGuide.forManufacturer(
        await _manufacturer?.call(),
      ).steps;
    } on Object {
      // Not knowing the maker only means the general steps are shown.
    }
    notifyListeners();
  }

  /// Marks first-run setup as done.
  Future<void> finishSetup() async {
    await _settings.set('setup_done', 'true');
    _setupDone = true;
    notifyListeners();
  }

  Future<void> _loadRoute(String? id) async {
    _routeId = null;
    _route = null;
    if (id == null || id.isEmpty || _routes == null) return;
    try {
      _route = await _routes.load(id);
      if (_route != null) _routeId = id;
    } on Object {
      // A damaged route file means a free trek, never a blocked start.
    }
  }

  /// Chooses the route for the next trek (null = free trek).
  Future<void> selectRoute(String? id) async {
    await _loadRoute(id);
    await _settings.set('active_route', _routeId ?? '');
    notifyListeners();
  }

  /// Tells the core to follow the route the other way (walking home).
  Future<void> reverseRoute() => _client.reverseRoute();

  /// Drops a pin at the current position.
  Future<void> dropPin() => _client.dropPin();

  /// Silences off-route alerts for 10 minutes.
  Future<void> snoozeAlerts() => _client.snoozeAlerts();

  /// Brings the alerts back.
  Future<void> resumeAlerts() => _client.resumeAlerts();

  /// Remembers the handedness choice.
  Future<void> setLeftHanded({required bool left}) async {
    await _settings.set('pref_left_handed', '$left');
    _leftHanded = left;
    notifyListeners();
  }

  /// Remembers how far Setup got.
  Future<void> saveSetupStep(int step) async {
    await _settings.set('setup_step', '$step');
    _setupStep = step;
  }

  /// Re-reads permissions (after returning from system settings).
  Future<void> refreshPermissions() async {
    _granted = await _permissions.granted();
    notifyListeners();
  }

  static final _phone = RegExp(r'^\+\d{6,15}$');

  /// Turns what was typed into `+countrycode number`, or null when it
  /// cannot be read without guessing the country. "00" counts as "+".
  static String? normalisePhone(String raw) {
    var n = raw.replaceAll(RegExp(r'[\s\-().]'), '');
    if (n.startsWith('00')) n = '+${n.substring(2)}';
    return _phone.hasMatch(n) ? n : null;
  }

  /// Adds an emergency contact. False when it is not a phone number with a
  /// country code, or is already saved.
  Future<bool> addContact(String raw) async {
    final number = normalisePhone(raw);
    if (number == null || _contacts.contains(number)) return false;
    await _saveContacts([..._contacts, number]);
    return true;
  }

  /// Removes an emergency contact.
  Future<void> removeContact(String number) =>
      _saveContacts(_contacts.where((c) => c != number).toList());

  Future<void> _saveContacts(List<String> list) async {
    await _settings.set('emergency_contacts', list.join(','));
    _contacts = list;
    notifyListeners();
  }

  /// Sets the name shown to the group and in the SOS text.
  Future<void> setName(String value) async {
    final v = value.trim();
    await _settings.set('member_name', v);
    _name = v;
    notifyListeners();
  }

  /// Saves the emergency card.
  Future<void> saveCard(EmergencyCard value) async {
    await _settings.set('card_blood_group', value.bloodGroup.trim());
    await _settings.set('card_allergies', value.allergies.trim());
    await _settings.set('card_medicines', value.medicines.trim());
    _card = EmergencyCard(
      bloodGroup: value.bloodGroup.trim(),
      allergies: value.allergies.trim(),
      medicines: value.medicines.trim(),
    );
    notifyListeners();
  }

  /// Does the one-tap fix of a readiness row.
  Future<void> fix(ReadyItem item) async {
    lastRefused = null;
    final permission = switch (item) {
      ReadyItem.location => AppPermission.location,
      ReadyItem.background => AppPermission.backgroundLocation,
      ReadyItem.sms => AppPermission.sms,
      ReadyItem.notifications => AppPermission.notifications,
      ReadyItem.contacts || ReadyItem.card => null,
    };
    if (permission != null) {
      if (await _permissions.isPermanentlyDenied(permission)) {
        // The system would not show a prompt; only its settings can help.
        lastRefused = item;
        await _permissions.openSettings();
      } else if (!await _permissions.request(permission)) {
        lastRefused = item;
      }
    }
    await refreshPermissions();
  }

  /// Asks for [permission] (Setup), then re-reads what is granted.
  Future<bool> requestPermission(AppPermission permission) async {
    if (await _permissions.isPermanentlyDenied(permission)) {
      await _permissions.openSettings();
      await refreshPermissions();
      return false;
    }
    final ok = await _permissions.request(permission);
    await refreshPermissions();
    return ok;
  }

  /// Turns the siren on or off.
  Future<void> setSiren({required bool on}) async {
    await _siren?.setOn(on: on);
    _sirenOn = on;
    notifyListeners();
  }

  /// Turns the SOS torch strobe on or off.
  Future<void> setTorch({required bool on}) async {
    await _torch?.setStrobe(on: on);
    _torchOn = on;
    notifyListeners();
  }

  /// Opens the dialer on 112 (the person presses call).
  Future<void> callEmergency() => call('112');

  /// Opens the dialer on [number] (the person presses call).
  Future<void> call(String number) async => _dialer?.open(number);

  void _onCoreState(CoreStateMessage m) {
    // The siren and torch belong to an SOS: when it is over they go quiet.
    final inSos = m.state.emergency is SosActive;
    if (!inSos && (_sirenOn || _torchOn)) {
      unawaited(setSiren(on: false));
      unawaited(setTorch(on: false));
    }
    notifyListeners();
  }

  /// Opens the system settings page of the app.
  Future<void> openSettings() => _permissions.openSettings();

  /// Starts a trek: the foreground service first (it must start from a user
  /// action), then the command to the core. Refused while a critical item is
  /// missing.
  Future<void> startTrek() async {
    if (!readiness.canStart) return;
    await _service.start();
    await _client.send(const StartTrek());
  }

  /// Ends the trek.
  Future<void> endTrek() async {
    await _client.send(const EndTrek());
    await _service.stop();
  }

  @override
  void dispose() {
    // Never leave a siren screaming behind a closed screen.
    if (_sirenOn) unawaited(_siren?.setOn(on: false));
    if (_torchOn) unawaited(_torch?.setStrobe(on: false));
    unawaited(_signalSub?.cancel());
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
