import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pagdandi_app/design/palette.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/spike/frame_stats.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';

/// Where the spike reads its tiles from and where it starts.
class MapSpikeConfig {
  /// Creates a config.
  const MapSpikeConfig({
    this.pmtilesPath = _defaultPath,
    this.center = const LatLng(27.036, 88.2627), // Darjeeling
    this.zoom = 12,
  });

  static const String _defaultPath = String.fromEnvironment(
    'PMTILES_PATH',
    defaultValue:
        '/data/user/0/app.pagdandi.pagdandi_app/files/darjeeling_z14.pmtiles',
  );

  /// Local PMTiles file (offline; never a URL in the app).
  final String pmtilesPath;

  /// Initial map centre.
  final LatLng center;

  /// Initial zoom.
  final double zoom;
}

/// M0 spike: offline vector map from a local PMTiles file plus live frame
/// timing, to judge smoothness on a real phone. Not product UI.
class MapSpikePage extends StatefulWidget {
  /// Creates the spike page.
  const MapSpikePage({this.config = const MapSpikeConfig(), super.key});

  /// Configuration.
  final MapSpikeConfig config;

  @override
  State<MapSpikePage> createState() => _MapSpikePageState();
}

class _MapSpikePageState extends State<MapSpikePage> {
  final _stats = FrameStats();
  late final Future<PmTilesVectorTileProvider> _provider;
  late final TimingsCallback _timings;

  @override
  void initState() {
    super.initState();
    _provider = PmTilesVectorTileProvider.fromSource(widget.config.pmtilesPath);
    _timings = (timings) {
      for (final t in timings) {
        _stats.add(build: t.buildDuration, raster: t.rasterDuration);
      }
      if (mounted) setState(() {});
    };
    SchedulerBinding.instance.addTimingsCallback(_timings);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_timings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const p = Palette.normal;
    return ColoredBox(
      color: p.bg,
      child: Stack(
        children: [
          FutureBuilder<PmTilesVectorTileProvider>(
            future: _provider,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Cannot open ${widget.config.pmtilesPath}\n${snap.error}',
                    textDirection: TextDirection.ltr,
                    style: TypeScale.body.copyWith(color: p.warn),
                  ),
                );
              }
              if (!snap.hasData) return const SizedBox.expand();
              return FlutterMap(
                options: MapOptions(
                  initialCenter: widget.config.center,
                  initialZoom: widget.config.zoom,
                  maxZoom: 14,
                  backgroundColor: p.bg,
                ),
                children: [
                  VectorTileLayer(
                    theme: ProtomapsThemes.blackV4(),
                    tileProviders: TileProviders({'protomaps': snap.data!}),
                    fileCacheTtl: Duration.zero,
                  ),
                ],
              );
            },
          ),
          Positioned(
            left: 18,
            top: 40,
            child: GestureDetector(
              onTap: () => setState(_stats.reset),
              child: ColoredBox(
                color: p.surface,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _stats.summary,
                    textDirection: TextDirection.ltr,
                    style: TypeScale.label.copyWith(color: p.text),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
