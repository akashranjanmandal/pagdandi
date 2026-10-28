package app.pagdandi.pagdandi_native

import android.Manifest
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager

/**
 * After a reboot: flush any pending SOS SMS (WorkManager), and if a trek was
 * running resume it - or ask the user to tap if background location was not
 * granted (Android will not let a location service start from the background
 * without it).
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        OutboxFlushWorker.enqueue(context)
        if (!HeartbeatStore(context).trekActive) return
        val background = context.checkSelfPermission(Manifest.permission.ACCESS_BACKGROUND_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
        if (background) {
            context.startForegroundService(
                Intent(context, TrekForegroundService::class.java)
                    .putExtra(TrekForegroundService.EXTRA_AT_BOOT, true),
            )
        } else {
            Notifications.ensureChannels(context)
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(Notifications.ID_RESUME, Notifications.tapToResume(context))
        }
    }
}
