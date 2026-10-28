# Pagdandi M1 test report

**Update 2026-10-28 (fix pass):** see the end of this file for the re-run. The first run is kept below as it was.

Date: 2026-10-28. Build: debug APK from the current working tree (nothing committed since e602114).
Scope: the whole M1 wiring (UI, core, native), tested in phases. Every issue found is in [ISSUES.md](ISSUES.md); nothing was fixed beyond what the wiring needed. Awaiting your verification.

## Phase results

| # | Phase | What was run | Result |
|---|---|---|---|
| 1 | Unit | Dart packages (13): 438 tests. Kotlin (Robolectric): 115 tests. Tooling: 7 tests | All pass |
| 2 | Coverage gate | `tool/check_coverage.dart` (lines 90%, engine_safety 100% branches) | Pass: engine_safety 100/100, core_db 100/100, engine_tracking 100/100, trek_core 98.7/93.2 |
| 3 | Integration | `assembleTrekCore` with a fake Android: command to state round trip, SOS through SMS adapter, health issues, settings reload | Pass (14 tests) |
| 4 | UI / widget | App: 374 tests: behaviour of every screen, root navigation, controller, permission service, client | All pass |
| 5 | Visual / golden | Existing D2 goldens plus new M1 goldens (Basecamp x5, Setup x2, card x2, contacts, free trek). Text 1.5x, glove and sunlight variants | Pass; two goldens reviewed by eye and corrected (two primary keys, floating content) |
| 6 | Static analysis | `dart analyze --fatal-infos` on the workspace | 1 warning (deprecated lint in analysis_options), no other findings |
| 7 | Security / config review | Manifests, exported components, secrets scan, tracked key files | 3 findings (I-09, I-10, I-11); no secrets in the repo, no key files tracked |
| 8 | System, on emulator (Pixel 8, Android 15) | Install, first launch, Setup, real permission prompts | Partial: first run opens Setup; keyboard bug found and fixed (I-00); SMS permission prompt and system settings link work. The rest of the flow was not driven to the end (see below) |
| 9 | Not done | Service start, headless core, kill/reboot, real SMS, real GPS, release APK, TalkBack, performance profile, monkey run | Needs a real phone or a scripted UI driver; listed in ISSUES.md as I-01..I-03 |

## Found and fixed during the run
- Keyboard hid the Continue key on every text screen (Android 15 edge-to-edge ignores adjustResize). Fixed in `ScreenFrame` with a regression test.
- Contacts changed in Setup did not reach the running core. Fixed: settings reload with every health read, test added.
- Free trek showed sample friends, a sample map and push-to-talk. Fixed: live trek shows the real position, no group, an End trek hold key.
- Colour rule: missing items first used the SOS red; now amber with an octagon (design rule keeps red for SOS only).
- Two orange keys on one screen in Setup; fixed.

## Process notes
Tests were written before the code for the core wiring, health, free trek, screen frame, Basecamp and live trek screens. For the UI client, readiness, permission service, controller, Setup, card and root, the tests and code were written together and I did not watch them fail first. That breaks the strict TDD rule; flagged as I-24.

## Counts
Dart packages 438, app 374, tooling 7, Kotlin 115: 934 automated tests, 0 failing.


## Re-run after the fix pass (2026-10-28)
| Phase | Result |
|---|---|
| Dart packages | 438 + new bridge tests pass; trek_core 78 |
| App | 430 pass (was 374) |
| Kotlin | 123 pass (was 115) |
| Tooling | 7 pass |
| Analyzer | clean, no warnings |
| Coverage gate | pass (engine_safety 100/100, core_db 100/100, engine_tracking 100/100, trek_core 98.7/93.3) |
| Emulator (Android 15) | Release APK launches and opens Setup (was crashing at start-up). Reboot with an active trek: boot receiver (not exported) fires, trek foreground service and headless engine restart. Permission prompts work. |
| Still not done | Real GPS, real SMS, service-kill, TalkBack, performance, monkey run: need a real phone |


## Second re-run (2026-10-28, after "fix all")
| Phase | Result |
|---|---|
| Analyzer | clean |
| Dart packages | all pass (native_bridge 34, trek_core 78, others unchanged) |
| App | 454 pass |
| Kotlin | 151 pass (was 123) |
| Tooling | 7 pass |
| Coverage gate | pass |
| **End-to-end on the emulator** (`tool/qa/run_integration.sh`) | **Pass in 43 s.** Real app, real native bridge, real foreground service and headless core: first-run Setup, Basecamp, Start trek, live trek screen, SOS (hold 3 s), SOS screen with the real count, cancel (hold 5 s), End trek (hold 3 s), back to Basecamp. The outbox row ended as `sent` with the guard recording `delivered`. |
| Reboot with an active trek | Boot receiver (not exported) restarts the trek service |
| Release APK | Opens Setup (R8 rules added) |
| Still needs a real phone | Real GPS in the hills, a real SIM and carrier delivery reports, killing the service by hand, TalkBack, battery and performance, cold-weather behaviour |


## Final run (2026-10-28)
| Phase | Result |
|---|---|
| Analyzer (workspace and app) | clean |
| Dart packages | 589 pass (14 packages) |
| App | 540 pass |
| Tooling | 18 pass |
| Kotlin | 173 pass |
| Total automated | **1,320 pass, 0 fail** |
| Coverage gate | pass (engine_safety 100/100, engine_navigation 98.9/96.9, core_db 100/100, trek_core 98.2/93.8) |
| End-to-end on the emulator | pass: first run, route chosen, Start trek, real route guidance on the trail, off the trail and back (GPS fed along the real Brahmatal path), SOS, cancel, End trek |
| Release build | arm64 18.5 MB, signed with the project key, launches, no crash |
| Database | 0 errors in the device log after the shared-file fix |
| Still needs a real phone | real GPS in the hills, a real SIM and delivery reports, TalkBack, battery over a day, cold-weather behaviour |
