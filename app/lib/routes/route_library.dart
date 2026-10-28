import 'package:engine_navigation/engine_navigation.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// A route the app ships with.
@immutable
class RouteInfo {
  /// Creates the entry.
  const RouteInfo(this.id, this.name, this.asset);

  /// Stable id, saved in settings.
  final String id;

  /// What the user sees.
  final String name;

  /// Path of the GPX asset.
  final String asset;
}

/// Where routes come from. The core and the UI both read it.
abstract interface class RouteLibrary {
  /// Routes the user can choose.
  List<RouteInfo> get available;

  /// The route with [id], or null when there is none. Throws
  /// [FormatException] when the file is damaged.
  Future<Route?> load(String id);
}

/// Routes bundled as GPX assets. Data is OpenStreetMap contributors (ODbL),
/// with elevation from Open-Meteo; see `tool/route/osm_route_to_gpx.dart`.
class AssetRouteLibrary implements RouteLibrary {
  /// Creates the library.
  const AssetRouteLibrary();

  static const _routes = [
    RouteInfo(
      'lohajung-brahmatal',
      'Lohajung to Brahmatal',
      'assets/routes/lohajung_brahmatal.gpx',
    ),
  ];

  @override
  List<RouteInfo> get available => _routes;

  @override
  Future<Route?> load(String id) async {
    for (final r in _routes) {
      if (r.id == id) {
        return parseGpx(await rootBundle.loadString(r.asset), id: r.id);
      }
    }
    return null;
  }
}
