#!/bin/sh
# Grants the runtime permissions Pagdandi needs on a connected device or
# emulator, so integration tests can run without tapping system dialogs.
# Usage: tool/qa/grant_permissions.sh [adb serial]
ADB="${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb"
S="${1:+-s $1}"
P=app.pagdandi.pagdandi_app
for perm in ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION ACCESS_BACKGROUND_LOCATION SEND_SMS READ_PHONE_STATE POST_NOTIFICATIONS; do
  $ADB $S shell pm grant $P android.permission.$perm
done
