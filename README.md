# Pagdandi

Offline-first trekking safety and group app for a small private group (Flutter + Kotlin, Android only, sideloaded).

- Engineering spec: [docs/PROMPT.md](docs/PROMPT.md)
- Design spec and approved prototypes: [docs/DESIGN.md](docs/DESIGN.md), `docs/design/`
- Working rules and decisions: [CLAUDE.md](CLAUDE.md)

## Status
M1 is wired end to end: Setup, Basecamp (route choice, readiness, winter advice), live trek guidance on the bundled Lohajung to Brahmatal route, SOS with a persisted SMS outbox, fall detection, siren, torch, dial 112, voice alerts, pins, exact alarms, boot resume and a native safety guard. 1,000+ automated tests, plus an end-to-end test on the emulator. Groups, BLE mesh, offline map tiles and a friend-SOS screen are the next milestones. QA reports and the issue list are in [docs/qa](docs/qa).

## Develop
```
flutter pub get                      # resolves the pub workspace
dart pub global activate melos
melos run analyze                    # zero warnings, infos fail
melos run test:dart && melos run test:flutter
dart run tool/check_coverage.dart    # coverage gates
cd app && flutter build apk --release
tool/qa/run_integration.sh          # end-to-end on a connected emulator/phone
```
Map stack decision: `docs/decisions/0001-map-stack.md`. Rebuild the route file: `tool/route/osm_route_to_gpx.dart`.
