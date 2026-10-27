# Pagdandi

Offline-first trekking safety and group app for a small private group (Flutter + Kotlin, Android only, sideloaded).

- Engineering spec: [docs/PROMPT.md](docs/PROMPT.md)
- Design spec and approved prototypes: [docs/DESIGN.md](docs/DESIGN.md), `docs/design/`
- Working rules and decisions: [CLAUDE.md](CLAUDE.md)

## Status
M0 (monorepo, CI, design tokens, fakes and simulator, Pigeon bridge, map spike) is done. The five D2 screens (Active Trek, Lost mode, Friend SOS, Fall countdown, SOS active) are implemented in Flutter as a preview build with a gallery home. Trek engines, the foreground service and native safety guard start in M1.

## Develop
```
flutter pub get                      # resolves the pub workspace
dart pub global activate melos
melos run analyze                    # zero warnings, infos fail
melos run test:dart && melos run test:flutter
dart run tool/check_coverage.dart    # coverage gates
cd app && flutter build apk --release
```
Maps for the spike: see `docs/decisions/0001-map-stack.md`.
