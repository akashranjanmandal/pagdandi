# 0001 Map stack (M0 spike)

Status: **provisional. Rendering and file size are measured; smoothness on a real phone is not.** Needs your 10-minute test on a real phone before M1 builds on it.

## Options
- **A. flutter_map + vector_map_tiles + vector_map_tiles_pmtiles**, with a vector PMTiles file built by Planetiler.
- **B. mapsforge_flutter** with Mapsforge `.map` files.

## What I measured
| | A. PMTiles + flutter_map | B. mapsforge_flutter |
|---|---|---|
| Resolves with Flutter 3.47 / Dart 3.13 | yes (flutter_map 7.0.2, vector_map_tiles 8.0.0, pmtiles provider 1.5.0) | yes (4.1.0, pulls in dio and flutter_svg) |
| Renders offline from a local file | **yes**, checked on an Android 15 emulator | not tried |
| Region file size | **10.9 MB** for Darjeeling and Sikkim, about 100 x 100 km, zoom 0 to 14 | not measured; the only ready-made India file is **1.63 GB** (whole country) |
| Free, no key, no server | yes (one public archive read by byte range; Planetiler is open source) | yes |
| Build time for a region | **24 s** with the `pmtiles` CLI (`tool/map/extract_region.sh`) | needs a PBF plus osmosis and the mapsforge writer: not tried |
| Smoothness | **not measured** (see below) | not measured |

Data used: Protomaps build 20261026 (Planetiler 0.10.2, OSM data of 2026-10-26).

## Why smoothness is not a result
The only device available here is an Android emulator with a software GPU and a debug build. It showed 54% janky frames and froze System UI, which says nothing about a real phone. The spike screen records build and raster time per frame (p95, worst, jank %) so the real test is quick.

## Recommendation (provisional)
Choose **A**. It already renders offline, the file is small, one `pmtiles` command makes a region in seconds (good for the Sync Pack), and it keeps `flutter_map` for pins, routes and markers. Keep B as the fallback if A is janky on a real phone.

## Findings that affect the design
1. **No contour lines.** The Protomaps basemap has roads, water, land use and places, but no elevation contours. The design wants real contours in the map. They need a DEM-derived layer (free SRTM or Copernicus data, contours generated with Planetiler or GDAL) merged into the PMTiles. This is a real task for M3 (Sync Pack); I flagged it rather than silently dropping contours.
2. **The built-in "black" theme is almost invisible.** We need our own dark topo style from `docs/design/tokens.md` (muted-line map colours, nav-cyan route). `ThemeReader` accepts a custom style.
3. **Maps must live in the app's private files directory** (`/data/user/0/<id>/files`), not a path pushed with `adb push` (permission error `errno 13`). The Sync Pack will copy files there.
4. **Debug text in the spike is the only UI that is not from an approved prototype.** It is a spike, not product UI.

## Your 10-minute test on a real phone
1. `tool/map/extract_region.sh 20261026 darjeeling_z14.pmtiles 88.0,26.95,88.9,27.85 14`
2. `adb push darjeeling_z14.pmtiles /data/local/tmp/` then `adb shell "run-as app.pagdandi.pagdandi_app sh -c 'mkdir -p files && cp /data/local/tmp/darjeeling_z14.pmtiles files/'"` (after the first install of the debug build).
3. `cd app && flutter run --profile -t lib/spike_main.dart` (profile mode, not debug).
4. Pan and pinch for 30 seconds, then read the line at the top-left (tap it to reset).
5. Pass criterion I suggest: jank under 5% and p95 under 16 ms at the zoom levels we use (12 to 15).


## Update 2026-10-28
The spike code (`app/lib/spike`, `spike_main.dart`) and the four map packages it pulled in (`flutter_map`, `latlong2`, `vector_map_tiles`, `vector_map_tiles_pmtiles`) were removed from the app so the APK carries nothing it does not use. The code is in git history (commit e602114). The decision itself stands: when offline tiles are built (M4) the packages go back in. Until then the trek screen draws the route itself (`RoutePanel`), north up, with an elevation profile, credited to OpenStreetMap contributors.
