package app.pagdandi.pagdandi_native

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context

/** Notification channels and builders shared by the service, the guard and boot. */
object Notifications {
    const val CHANNEL_TREK = "trek"
    const val CHANNEL_ALERT = "trek_alert"
    const val ID_RESUME = 1003

    fun ensureChannels(context: Context) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_TREK, "Trek running", NotificationManager.IMPORTANCE_LOW)
                .apply { description = "Shown while a trek is running" },
        )
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_ALERT, "Trek warnings", NotificationManager.IMPORTANCE_HIGH)
                .apply { description = "The trek engine stopped or needs you" },
        )
    }

    private fun openApp(context: Context): PendingIntent? {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        return PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    fun trek(context: Context): Notification =
        Notification.Builder(context, CHANNEL_TREK)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentTitle("Trek running")
            .setContentText("Tracking your position and watching over your group")
            .setOngoing(true)
            .setContentIntent(openApp(context))
            .build()

    fun engineWarning(context: Context): Notification =
        Notification.Builder(context, CHANNEL_ALERT)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Trek engine stopped")
            .setContentText("Restarting it now. SOS messages still go out.")
            .setOngoing(true)
            .setContentIntent(openApp(context))
            .build()

    fun tapToResume(context: Context): Notification =
        Notification.Builder(context, CHANNEL_ALERT)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Tap to resume trek")
            .setContentText("The phone restarted. Open Pagdandi to keep tracking.")
            .setAutoCancel(true)
            .setContentIntent(openApp(context))
            .build()
}
