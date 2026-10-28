package app.pagdandi.pagdandi_native

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo

private fun granted(context: Context, permission: String) =
    context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

/**
 * Foreground service types for what is allowed right now. Location always;
 * microphone (push-to-talk) only with the permission, and never when started
 * from a boot receiver (Android 15 forbids it there); connected device only
 * with a Bluetooth permission. Asking for a type without its permission
 * crashes the service on Android 14+, so each is conditional.
 */
fun foregroundServiceTypes(context: Context, atBoot: Boolean): Int {
    var types = ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
    if (!atBoot && granted(context, Manifest.permission.RECORD_AUDIO)) {
        types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
    }
    if (granted(context, Manifest.permission.BLUETOOTH_CONNECT) ||
        granted(context, Manifest.permission.BLUETOOTH_ADVERTISE) ||
        granted(context, Manifest.permission.BLUETOOTH_SCAN)
    ) {
        types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
    }
    return types
}
