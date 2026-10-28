# Pagdandi

Offline-first trekking safety and group app (Flutter + Kotlin, Android only).
`APP_NAME = "Pagdandi"` is defined once; renaming must be a one-line change.

- Full engineering spec: [docs/PROMPT.md](docs/PROMPT.md)
- Design spec (tokens, components, screens, flows, design batches D1-D4): [docs/DESIGN.md](docs/DESIGN.md)
- Approved prototypes: `docs/design/`
- Design review decisions override DESIGN.md where they differ: see the decisions log in [docs/design/tokens.md](docs/design/tokens.md)

## Always
- Read docs/PROMPT.md and docs/DESIGN.md before any milestone.
- Strict TDD. One milestone at a time, then stop and report.
- Pure Dart in core_* and engine_*. Safety kernel must survive any other failure.
- UI only from approved prototypes in docs/design/; every element needs a reason.
- Zero cost. Stop and ask on any conflict.
- Simple, readable code; document every public interface.

## Decisions (override the prompts where they differ)
- **English only.** Hindi is dropped (decided 2026-10-27): no Hindi strings, fonts, voices, goldens or review. Hindi text in the HTML prototypes is ignored. Localisation can be added later behind the string layer.
- Buttons are rounded squares, not circles (see docs/design/tokens.md decisions log).
- Pure Dart workspace uses Dart pub workspaces + melos.
- **D2 decisions:** fall-countdown ring red; wrong way = 3 short; GPS lost = 1 long; SOS headline hero size; own-phone SOS buzz every 30 s until first delivery.
- **D2 implemented in Flutter (preview build):** Active Trek, Lost mode, Friend SOS, Fall countdown and SOS active are in `app/lib/screens`, opened from a gallery (`app/lib/preview`). Active Trek bottom reworked (group row + key deck). Goldens in `app/test/goldens`.
- **M1 wired (2026-10-28):** UI is a thin client of a headless core in a foreground service, talking through a native relay. Brahmatal route (`app/assets/routes/lohajung_brahmatal.gpx`, OpenStreetMap relation 12155768, elevation Open-Meteo) is bundled; `engine_navigation` does GPX import, route matching, off-route / wrong-way / GPS-lost, sunrise and sunset. Fall detector, siren, torch, dialer, voice (TextToSpeech), exact alarms and pins are built. A claim on screen must come from real state; sample values live only in previews and tests. QA: `docs/qa/`, end-to-end test `tool/qa/run_integration.sh`.
