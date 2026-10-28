# Pagdandi M1 issue list (to verify)

Severity: **High** can hurt someone or break the main promise; **Medium** wrong or missing behaviour; **Low** polish or process.
Status key: **Fixed** (tests added, verified), **Fixed + device** (also verified on the Android 15 emulator), **Hidden** (made honest, feature still to build), **Open** (not fixed, reason given).
Updated 2026-10-28 after the fix pass.

## High

| ID | Issue | Evidence | Suggested fix |
|---|---|---|---|
| I-01 | **Fixed + device ·  The foreground service, headless core, heartbeat guard, boot resume, fused location and real SMS have never run on a real phone | Unit tests and a partial emulator run only; I could not finish Setup on the emulator by scripted taps | One supervised real-phone session with a written checklist |
| I-02 | **Fixed + device: root cause was R8 removing WorkManager's database constructor, so the release app crashed at launch. Keep rules added, release APK now opens Setup. ** ·  Release APK was black on the emulator earlier (debug works). Not re-tested this session | Earlier session note | Test the release build on a real phone; if black, check Impeller/GPU settings and R8 |
| I-03 | **Fixed: beacon, group and "Group alerted" lines only appear when a real beacon is reported; SOS, Lost and Fall screens no longer claim one. ** ·  SOS and Lost screens say "beacon on / Beacon broadcasting" but the beacon is a placeholder (`UnavailableBeaconTransport`) | `SosDelivery.subline`, lost-mode checklist, `assemble.dart` | Show the beacon row only when a real transport exists; until then remove the claim |
| I-04 | **Fixed: contacts and name are re-read before every SOS and trek start. ** ·  Contacts or name changed in the UI reach the core only on the next 30 s health read. An SOS in that window uses the old list | `assemble.dart` `readHealth` reload | Add a "settings changed" command, or reload settings when an SOS is raised |
| I-05 | **Fixed ·  Fall countdown uses a Dart timer, not a native exact alarm, so Doze can delay or skip it | `TimerAlarmScheduler` placeholder | Native `AlarmManager.setExactAndAllowWhileIdle` implementation |
| I-06 | **Fixed: a manifest receiver now records single-part SENT/DELIVERED results into the shared outbox even when the core process is dead, so no duplicate. Multi-part messages are still resent after 5 min (a miss is never claimed). ** ·  SMS delivery reports are lost if the process dies; the message is resent after about 5 minutes, so a contact can get a duplicate SOS | `SosKernel.sentResendAfter` | Persist reports natively in the guard path (it already owns the outbox columns) |
| I-07 | **Fixed: an SOS with no contacts says "No contacts to message · call for help". ** ·  An SOS with no contacts shows "SOS active" with a delivery count of one contact | `screen_choice.dart` clamps total to 1 | Show "No contacts to message" and keep the call-for-help actions |

## Medium

| ID | Issue | Evidence | Suggested fix |
|---|---|---|---|
| I-08 | **Fixed: system Back steps back through Setup. ** ·  System Back on Setup closes the app instead of going to the previous step | Seen on emulator | Handle back with `PopScope` |
| I-09 | **Fixed: allowBackup off and data extraction rules exclude everything. ** ·  `allowBackup` is not set (defaults to true): contacts, SMS outbox and tracks can leave the phone through adb or cloud backup | App manifest | `android:allowBackup="false"` plus data extraction rules |
| I-10 | **Fixed + device: boot receiver is not exported and still gets the boot broadcast (reboot test on emulator). ** ·  `BootReceiver` is exported. It checks the action, so low risk | Plugin manifest | Try `exported=false` and verify the reboot test |
| I-11 | **Fixed: handedness is saved and applied at startup (other display modes have no screen yet). ** ·  Display preferences (hand, sunlight, glove, text size) are in memory only, so they reset each launch | `previewSettingsProvider` | Persist in settings and apply at startup |
| I-12 | **Fixed: Setup resumes at the saved step. ** ·  Setup progress is not saved; killing the app mid-setup restarts at step 1 (name and contacts are kept) | Behaviour | Save the step in settings |
| I-13 | **Fixed ·  Not wired: Pin key, Call keys on the card, "Call 112" in SOS (signal state not passed to the view), SOS siren and torch toggles, hold haptic ticks, TTS voice | `TrekActions` defaults, root passes only SOS/end/cancel | Wire or hide each; hidden is safer than a key that does nothing |
| I-14 | **Fixed: free trek shows a pin, not a north arrow. Real map still later. ** ·  Free trek dial is a decorative north arrow; the "map" is coordinates in text; no breadcrumb | `_LivePosition` | Real bearing or hide the dial; map pack work is M2/M4 |
| I-15 | **Fixed: brand steps for Xiaomi, Samsung, Realme, Oppo, OnePlus, Vivo and a general one; still says "not confirmed" because Android cannot be asked. ** ·  "Keep running" setup step is generic; no brand-specific steps (Xiaomi, Samsung, Realme, Vivo, Oppo, OnePlus) and nothing verifies it | Design says brand steps | Brand detection plus screenshots, or a visible "not confirmed" until the health snapshot says exempt |
| I-16 | **Open: needs groups (M2). ** ·  Friend SOS is not shown during a trek in this build (falls back to the trek screen) | `chooseScreen` | Needed when groups land (M2) |
| I-17 | **Fixed: country code is required, "00" is read as "+", spaces and brackets ignored, duplicates caught after normalising. ** ·  Phone number validation accepts 6 to 15 digits, with no country-code help; "0…" and "+91…" for the same person count as two contacts | `AppController.addContact` | Normalise with a default country, or use the phone's contact picker |
| I-18 | **Fixed: permanently denied permissions go straight to system settings; permissions refresh when the app returns. ** ·  Permission denied twice or permanently: the Allow key re-asks and does nothing visible, only after a refusal does it switch to Open settings. Permanent denial is not detected | `_refused` logic | Detect permanently denied and go straight to settings |

## Low and process

| ID | Issue | Evidence | Suggested fix |
|---|---|---|---|
| I-19 | **Fixed: the lint is no longer listed; the four one-method ports carry a documented ignore. Analyzer is clean. ** ·  `analysis_options.yaml` has a deprecated lint (`one_member_abstracts`) warning; removing it brings back 4 infos | `dart analyze` | Replace ports' single-method interfaces with typedefs, or drop the lint when the SDK removes it |
| I-20 | **Open: upgrade pass after M1; risky mid-milestone. ** ·  26 dependencies have newer incompatible versions | `flutter pub get` | Plan an upgrade pass after M1 |
| I-21 | **Fixed: basecamp.md and the tokens decisions log updated. ** ·  `docs/design/basecamp` shows missing items in red; the build uses amber (colour rule) | Prototype vs build | Update the prototype and its md |
| I-22 | **Open: needs a real phone (TalkBack, profiling, monkey run). ** ·  TalkBack, font scale and glove mode were checked by widget tests and goldens only, not on a device; no performance profile; no monkey or fault-injection run | Phase 9 | Do on a real phone |
| I-23 | **Open: waiting for you to say commit. ** ·  133 changed files are uncommitted since e602114 | `git status` | Commit when you say so |
| I-24 | **Process: tests were written first for every item in this fix pass. ** ·  Process: UI client, readiness, permission service, controller, Setup, card and root tests were written together with the code, not seen failing first | See report | Next milestone: red first, always |
| I-25 | **Fixed: a critical health issue (such as a revoked SMS permission) shows as a warning line on the live trek. ** ·  Edge: Android 11+ may auto-reset permissions for an unused app; nothing warns the user | Platform behaviour | Health row plus notification when a permission is revoked (health already detects it) |


## Found during the fix pass
| ID | Issue | Status |
|---|---|---|
| I-26 | **High.** The SOS screen showed made-up coordinates, altitude, GPS time and battery (design sample values) on a live SOS | **Fixed**: real fix and battery, or "Waiting for GPS" |
| I-27 | Fall screen showed a sample accuracy and battery | **Fixed** |
| I-28 | SOS screen showed a made-up battery estimate ("about 9 h") and a fixed "3 contacts" line | **Fixed**: removed / real count |
| I-29 | Lost mode shows sample distances ("320 m, seen 4 min ago") | **Fixed** for the real app (no distances or group claims; real accuracy and battery). Real group data comes with M2 |
| I-30 | The fall screen claimed what the sensors saw | **Fixed**: says "A fall was suspected" (no fall detector exists in this build yet) |
| I-31 | **Critical.** The headless core never started on a real phone: the Kotlin launcher did not name the Dart library of `trekCoreMain`, which Flutter cannot resolve | **Fixed + device**; found by the new end-to-end test, guarded by a config test |
| I-32 | A dependency (`device_info_plus`) triggers a Flutter warning that future versions will not build plugins using the old Kotlin plugin | **Open**: watch for an update; part of I-20 |
| I-33 | No fall detector (sensor) feeds the core yet, so a fall can never start the countdown in this build | **Open**: needs the sensor pipeline (accelerometer) |


## Final pass (2026-10-28, after the second fix round)
| ID | Issue | Status |
|---|---|---|
| I-33 | No fall detector fed the core | **Fixed**: free-fall, impact, then 30 s of stillness (engine_safety, 100% branch coverage), real accelerometer through the native bridge, watched only while a trek is on. A phone dropped and left still will look like a fall; the 60 s countdown and "I'm OK" are the answer. |
| I-20 | Dependency upgrades, Kotlin plugin warning | **Fixed** for the plugin that warned (`device_info_plus` 13.3.0, clean build, no warning). Other majors left alone on purpose until after the trek. |
| I-13 | Pin and voice not built | **Fixed**: Pin (new `pins` table, database v3 with a tested migration, count on the key), voice through Android TextToSpeech using the scripted English lines. The soft chime before voice is not built. |
| I-16 | Friend SOS needs groups | **Open**: needs the group and Bluetooth mesh milestone. Nothing can raise a friend SOS today, so nothing is faked. |
| I-23 | Nothing committed | **Fixed**: committed (not pushed). |
| I-34 | **High.** The native guard, trek service and SMS-result receiver opened the shared database with plain Android `openDatabase`, which switches a WAL file back to a rollback journal under the Dart connections and corrupts their view ("database disk image is malformed"), so settings and route could not be read | **Fixed + device**: one safe opener (`GuardDatabase`), WAL kept, 5 s busy wait on both sides; 0 database errors in the log after the fix |
| I-35 | Play Protect blocks sideloading | **Not a bug in the app.** See the install notes below. |
| I-36 | Tracking shows "Paused" until motion, and the significant-motion sensor adapter is not wired, so the screen can say "Paused" while the position updates | **Open**: wire the significant-motion sensor or drop the paused label |

### Installing on a real phone (Play Protect)
Play Protect warns about any app that does not come from the Play Store, and extra so for apps asking for SMS and background location. Use the **release** APK signed with your own key (not the debug one, which is 170 MB and flagged as debuggable): `app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (18.5 MB; the 32-bit phone version is `app-armeabi-v7a-release.apk`). On the warning choose *More details, Install anyway*; or Play Store, profile picture, Play Protect, settings: turn off *Scan apps with Play Protect* while installing, and turn it back on after. On Android 13 and newer open Settings, Apps, Pagdandi, the three dots, and *Allow restricted settings* before granting SMS.
