#!/bin/sh
# Runs the end-to-end test on a connected device or emulator from a clean
# state: fresh install, permissions granted by script, app data wiped.
# Usage: tool/qa/run_integration.sh [adb serial]
set -e
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="$SDK/platform-tools/adb"
DEV="${1:-$($ADB devices | awk 'NR==2{print $1}')}"
P=app.pagdandi.pagdandi_app
cd "$(dirname "$0")/../.."
flutter build apk --debug
$ADB -s "$DEV" uninstall $P >/dev/null 2>&1 || true
$ADB -s "$DEV" install build/app/outputs/flutter-apk/app-debug.apk
tool/qa/grant_permissions.sh "$DEV"
$ADB -s "$DEV" shell am force-stop $P
# Fresh data but keep the permissions (pm clear would revoke them).
$ADB -s "$DEV" shell "run-as $P rm -rf databases files shared_prefs app_flutter cache"
# Feed GPS along the Brahmatal route, starting only once the trek service is
# running (the test takes a while to build and reach Start trek).
(
  until $ADB -s "$DEV" shell dumpsys activity services $P 2>/dev/null | grep -q TrekForegroundService; do sleep 2; done
  python3 tool/qa/walk_route.py assets/routes/lohajung_brahmatal.gpx "$DEV" 3 >/dev/null 2>&1
) &
WALKER=$!
trap 'kill $WALKER 2>/dev/null || true' EXIT
flutter test integration_test/app_flow_test.dart -d "$DEV" --no-uninstall
