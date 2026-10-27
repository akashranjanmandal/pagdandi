# PAGDANDI — Engineering Prompt
FIRST ACTION: save this entire prompt verbatim as docs/PROMPT.md, and create
CLAUDE.md at the repo root with a short summary of the "Always" rules at the end of
this prompt plus links to docs/PROMPT.md and docs/DESIGN.md.

APP_NAME = "Pagdandi"   (defined once; renaming must be a one-line change)

You are a senior Flutter + Android engineer building Pagdandi: an offline-first
trekking safety and group app for a small private group of friends in India
(Northeast, Darjeeling/Sikkim hills, Himalayas). Sideloaded APK, no Play Store.
Must work with ZERO network (airplane mode + GPS). Lives may depend on it:
correctness and reliability matter more than speed.

All UI and visual work must follow docs/DESIGN.md (provided in the next message)
and the approved prototypes in docs/design/.

## 1. Hard constraints
- Zero cost: free open-source packages and free no-key APIs only. No servers,
  Firebase, Google Maps SDK, Mapbox, paid APIs, runtime Google Fonts fetching, or
  bulk downloading from openstreetmap.org tile servers.
- Flutter (latest stable) + Dart for UI and core logic; Kotlin for Android native
  plugins. Android only. minSdk 29, latest stable targetSdk.
- Strict TDD: failing test first, minimum code, refactor. No production code
  without a test that requires it.
- If a requirement conflicts with Android platform rules or would cost money, STOP
  and explain instead of silently working around it.

## 2. Architecture
Monorepo with melos:
packages/
  core_model        immutable data types
  core_common       Clock, GpsTimeSource, Result types, logging interface
  core_geo          distance, bearing, cross-track, grid spatial index, sun times
  core_crypto       group key, QR payload, AES-GCM (package:cryptography)
  core_db           Drift (SQLite) schema, DAOs, migrations
  core_ports        abstract hardware interfaces
  engine_trekstate  statechart reducer + ResourceArbiter
  engine_tracking   location pipeline, breadcrumb, take-me-back
  engine_navigation route matching, off-route, wrong-way, junctions, time estimates
  engine_alerts     alert priority queue, escalation, output routing
  engine_safety     SOS outbox, check-in, fall detection, lost mode (SAFETY KERNEL)
  engine_group      envelope, encryption, dedup, relay, peers, sync
  engine_ptt        floor-control state (audio path is native)
  engine_health     ascent rate, storm warning, self-health watchdog
  native_bridge     Pigeon definitions + Dart adapters implementing core_ports
  testing           fakes for every port + multi-phone simulation harness
app/                Flutter UI (thin: renders state, sends commands)
android/            Kotlin plugin "pagdandi_native"

Rules:
1. core_* and engine_* are pure Dart (no package:flutter, no dart:ui, no platform
   code); tested with package:test.
2. Engines reach hardware only via core_ports: LocationSource, MotionSensor,
   Accelerometer, Barometer, Transport, BeaconTransport, SmsGateway, SignalMonitor,
   AudioOutput, HapticOutput, TorchOutput, SirenOutput, AlarmScheduler, Clock,
   GpsTimeSource, BatteryMonitor, PttAudio.
3. engine_safety depends on core_* only. Failure anywhere else must never stop SOS,
   SMS outbox, torch/siren or fall detection.
4. Fail safe: when uncertain, alert rather than stay silent.
5. Inject Clock and randomness everywhere (deterministic tests).
6. GPS time is the trusted clock for timestamps and sync; system time only without
   a fix, and flagged.

Runtime model:
- Kotlin foreground service (types location|microphone|connectedDevice), started
  only from a user action ("Start trek"), hosts a HEADLESS FlutterEngine running
  the Dart trek-core entrypoint (@pragma('vm:entry-point')). All engines run there.
- The UI FlutterEngine is a thin client: sends Commands, receives TrekState
  snapshots via a typed bridge. If the UI dies or closes, the trek continues.
- Native safety guard (Kotlin, minimal): watches a heartbeat from the Dart core.
  If missing > 30 s: keeps SOS SMS outbox flushing, keeps beacon/siren on if SOS
  is active, posts a warning notification, restarts the Dart core.
- Shared SQLite (Drift, WAL). Native guard only reads sms_outbox and updates its
  own status columns inside transactions.
- Boot recovery: auto-resume if background location granted; otherwise post
  "Tap to resume trek". SMS outbox must still flush after reboot via WorkManager.

Native plugins (Kotlin, each behind Pigeon, unit-tested with JUnit + Robolectric):
- Location: FusedLocationProvider with batching (setMaxUpdateDelayMillis), GPS-only
  fallback, significant-motion trigger sensor, sensor batching (barometer,
  accelerometer).
- Nearby Connections (P2P_CLUSTER); discovery only on demand or in Regroup.
- BLE beacon: extended advertising on LE Coded PHY when supported
  (isLeCodedPhySupported / isLeExtendedAdvertisingSupported), legacy fallback;
  low-power duty-cycled scanning.
- SMS send + delivery reports; TelephonyCallback service-state listener.
- Audio: TTS with AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK and
  USAGE_ASSISTANCE_NAVIGATION_GUIDANCE, chime before speech, headphone events,
  speaker fallback; siren on alarm stream (works in silent mode).
- PTT audio fully native: phone mic (never Bluetooth headset mic) -> Opus via
  MediaCodec -> 40-60 ms frames -> Nearby; receiver jitter buffer -> AudioTrack
  with ducking. Dart controls floor state only.
- Haptics (VibrationEffect waveforms), torch (CameraManager), exact alarms,
  full-screen intent for fall countdown, battery level, boot receiver.

Other free packages: flutter_map with offline tiles (M0 spike: vector PMTiles
generated with Planetiler + vector_map_tiles, vs mapsforge_flutter; choose by
smoothness and file size; document the decision), Riverpod (UI state), Drift,
package:cryptography, mobile_scanner + qr_flutter, just_audio, http (Open-Meteo
only when online), melos.

## 3. State management
- Statechart, four parallel regions:
  Activity:   Idle, Moving, Stationary (+ MapOpen overlay)
  Group:      Solo, Connected, PartiallyConnected, Regroup
  Emergency:  None, FallCountdown, LostMode, SosActive, FriendSos
  Navigation: NoRoute, OnRoute, OffRoute, WrongWay, NearJunction, GpsLost
- Unidirectional: sealed TrekEvent -> pure reduce(state, event, now) ->
  Transition(newState, effects). Effects run in handlers. reduce() has no side
  effects.
- ONE serialized event queue; no concurrent state mutation.
- Engines isolated: an exception is caught, logged, raised as a health warning;
  other engines continue.
- ResourceArbiter: engines declare GPS/sensor/radio demands; merged (fastest
  interval wins; batching only if all allow) into one hardware request.
- Snapshot persisted on every transition; must-happen work in outbox tables;
  restore from both on restart.
- UI: Riverpod providers subscribe to TrekState; no business logic in UI.

## 4. Engine mechanisms
Tracking: reject poor-accuracy and impossible-speed fixes; ignore moves < 5-10 m;
batched DB writes; breadcrumb; take-me-back; auto-pause via significant motion.

Navigation: GPX import; polyline + grid index; cross-track and progress. Off-route
when distance > max(25 m, 2 x accuracy) for 3 consecutive fixes; clear below 15 m.
Wrong-way on steadily decreasing progress. Precompute junctions. Adaptive GPS
demand (live ~5 s within ~200 m of junction/danger pin, batched otherwise).
Naismith estimates calibrated by pace history. Turnaround and sunset alerts.
GpsLost state (no false off-route).

Alerts: priority SOS > FriendSos > Fall > Danger > OffRoute > WrongWay > Junction >
GroupGap > Health > Info. Cooldowns, escalation, snooze ("I know, exploring" 10
min). English + Hindi. Haptic vocabulary is defined in docs/DESIGN.md; implement
it exactly.

Safety kernel: SOS outbox persisted BEFORE sending; flush on signal; delivery
reports; retry with backoff; message has coords, accuracy, GPS time, altitude,
battery, maps link. Fall detection: free-fall -> impact -> ~30 s stillness -> 60 s
cancellable countdown -> auto SOS (configurable thresholds). Check-in timer (exact
alarm). Lost mode: guidance + last known group position + beacon + SOS armed.
Torch SOS strobe. Siren in silent mode.

Group: QR pairing (groupId + secret key). Envelope: msgId, groupId, senderId, type,
gpsTime, hopCount (max 3), AES-GCM payload, compact binary serialization. Dedup
cache, multi-hop relay, peer registry (last seen, link quality), out-of-range
timeout, last known positions, group gap. Last-write-wins sync (GPS time,
deviceId tiebreak). Roles: leader, sweep, signal-phone rotation. PTT floor
control: earlier GPS time wins, lower member id breaks ties; roger beeps;
channel busy.

Health: ascent-rate warning (sleep altitude > 3000 m rising > 500 m/day); storm
warning (~3 hPa drop in 3 h, configurable); watchdog (GPS fix age, service
alive, permissions, battery exemption, storage).

Extras: Sync Pack (region map files, Open-Meteo cache with saved-time, checklist
incl. offline TTS voice check), trail pins, bundled first-aid + AMS guide, local
music player, Wi-Fi Direct file share, expense ledger, GPX export, backup file,
post-trek summary, GitHub Releases update check when online. Local rotating log,
exportable; never log keys.

Data (Drift): groups, members, trips, track_points, routes, route_points,
junctions, pins, messages, sms_outbox, relay_outbox, state_snapshots, event_log
(bounded), alerts_log, expenses, pace_history, settings. Every migration tested.

## 5. Testing and quality gates
Dart: package:test, mocktail, fake_async, glados (property tests), in-memory Drift.
Flutter: widget tests; golden tests (matchesGoldenFile) for every screen in every
state from docs/DESIGN.md, both handedness, text scale 1.0 and 1.5, English and
Hindi, normal and sunlight mode; goldens must match the approved prototypes.
integration_test + patrol for device flows incl. permission dialogs.
Native: JUnit + Robolectric; instrumented tests on real devices.
Simulation harness: multiple virtual phones, one fake clock; GPX replay with noise,
dropouts, accuracy spikes; FakeTransport with range, loss, latency, duplicates,
reordering; scripted falls, stillness, pressure drops, signal on/off.
Required fault-injection tests: service killed mid-trek; reboot with pending SMS;
permission revoked; GPS lost 10 min; duplicate/out-of-order messages; clock skew;
3-second signal flicker; storage nearly full; Dart core frozen (native guard takes
over); UI engine killed (trek continues).
Performance: frame timing on Active Trek during map pan, alerts and PTT; fail on
jank in key flows; memory stable over a simulated 8-hour trek.
Gates (GitHub Actions, every commit): core + engines >= 90% line coverage;
engine_safety 100% branch coverage; zero analyzer warnings (very_good_analysis);
all tests and goldens green.

## 6. Milestones (one at a time, then STOP and report)
M0  Monorepo, melos, CI, lint, Pigeon, fakes + simulator skeleton, map rendering
    spike, design tokens as Dart code (from docs/DESIGN.md), bundled fonts.
M1  core_*, crypto + QR pairing, Drift v1, statechart (Activity + Emergency),
    arbiter, tracking, safety kernel, snapshots, boot recovery, foreground service
    + headless engine, native guard, watchdog.
    UI: Setup, Basecamp, Active Trek (solo), SOS active, Emergency card,
    lock-screen notification.
M2  Group messaging, Nearby, out-of-range, navigation, alerts (TTS + haptics), fall
    detection, check-in, lost mode, sync.
    UI: Group, Radar, Active Trek states, Lost mode, Fall countdown, Friend SOS,
    Timeline.
M3  PTT (native audio), relay, BLE beacon, junctions + adaptive sampling, health,
    time estimates, Sync Pack, pins, first-aid guide.
    UI: PTT overlay, Quick messages, Trip planner, Pins, Settings, Health banners.
M4  Wi-Fi Direct share, expenses, offline routing, Meshtastic, export/backup,
    update check, post-trek summary, music.
    UI: remaining screens; motion and performance polish.
UI tasks in any milestone may only start once that screen's prototype in
docs/design/ is approved by me.

Report per milestone: what was built, tests and coverage, assumptions,
risks/Android limitations, and exactly what to test on a real phone.

## Always (copy into CLAUDE.md)
- Read docs/PROMPT.md and docs/DESIGN.md before any milestone.
- Strict TDD. One milestone at a time, then stop and report.
- Pure Dart in core_* and engine_*. Safety kernel must survive any other failure.
- UI only from approved prototypes in docs/design/; every element needs a reason.
- Zero cost. Stop and ask on any conflict.
- Simple, readable code; document every public interface.

Do not start M0 until I have sent the design prompt and you have saved both files.
Reply "Ready for the design prompt" when done.
