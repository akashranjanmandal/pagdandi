#!/usr/bin/env bash
# Extracts a region from the free Protomaps/Planetiler planet build into a
# single offline vector PMTiles file. No key, no tile-server scraping: it reads
# byte ranges of one published archive (about 11 MB for 100 x 100 km, z0-14).
#
#   tool/map/extract_region.sh <build-date YYYYMMDD> <out.pmtiles> <minLon,minLat,maxLon,maxLat> [maxzoom]
#
# Needs the pmtiles CLI (brew install pmtiles). Example (Darjeeling and Sikkim):
#   tool/map/extract_region.sh 20261026 darjeeling_z14.pmtiles 88.0,26.95,88.9,27.85 14
set -euo pipefail
date="${1:?build date}"; out="${2:?output file}"; bbox="${3:?bbox}"; maxzoom="${4:-14}"
pmtiles extract "https://build.protomaps.com/${date}.pmtiles" "$out" --bbox="$bbox" --maxzoom="$maxzoom"
pmtiles show "$out" | head -8
