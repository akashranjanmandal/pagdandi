package app.pagdandi.pagdandi_native

import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.ServiceCompat

/**
 * Keeps the trek alive: an ongoing foreground notification, the headless Dart
 * core, and the native safety guard ticking every few seconds. Started only
 * from a user action ("Start trek") or the boot receiver.
 */
class TrekForegroundService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var core: CoreLauncher? = null
    private var ticking = false
    private lateinit var heartbeat: HeartbeatStore

    private val tick = object : Runnable {
        override fun run() {
            runGuardOnce()
            if (ticking) handler.postDelayed(this, GUARD_PERIOD_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        heartbeat = HeartbeatStore(this)
        Notifications.ensureChannels(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            heartbeat.trekActive = false
            ticking = false
            handler.removeCallbacks(tick)
            core?.stop()
            ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }
        // A restart by the system has no intent: treat it like boot (no microphone type).
        val atBoot = intent?.getBooleanExtra(EXTRA_AT_BOOT, false) ?: true
        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            Notifications.trek(this),
            foregroundServiceTypes(this, atBoot),
        )
        heartbeat.trekActive = true
        if (core == null) core = HeadlessCoreLauncher(this)
        core?.start()
        if (!ticking) {
            ticking = true
            handler.postDelayed(tick, GUARD_PERIOD_MS)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        ticking = false
        handler.removeCallbacks(tick)
        core?.stop()
        super.onDestroy()
    }

    private fun runGuardOnce() {
        val file = GuardPaths.databaseFile(this)
        if (!file.exists()) return
        var db: SQLiteDatabase? = null
        try {
            db = GuardDatabase.open(file)
            val outbox = GuardOutbox(db)
            GuardRunner(outbox, heartbeat, ServiceGuardActions(this, outbox, core), System::currentTimeMillis).runOnce()
        } catch (e: Exception) {
            // A guard that crashes protects nobody: swallow and try again next tick.
        } finally {
            db?.close()
        }
    }

    companion object {
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_TREK = Notifications.CHANNEL_TREK
        const val ACTION_STOP = "app.pagdandi.pagdandi_native.STOP_TREK"
        const val EXTRA_AT_BOOT = "at_boot"
        private const val GUARD_PERIOD_MS = 10_000L
    }
}

/** The guard's hands: its own SMS sender, the warning notification, the core. */
class ServiceGuardActions(
    private val context: Context,
    private val outbox: GuardOutbox,
    private val core: CoreLauncher?,
) : GuardActions {
    private val sms = SmsSender(context, defaultSmsManager(context)) { id, status ->
        // Report into the guard's own columns, never Dart's.
        outbox.markGuard(id, status.name.lowercase(), System.currentTimeMillis())
    }

    override fun sendSms(m: GuardMessage) = sms.send(m.id, m.to, m.body)

    override fun showWarning(show: Boolean) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (show) nm.notify(ID_WARNING, Notifications.engineWarning(context)) else nm.cancel(ID_WARNING)
    }

    // The native beacon and siren do not exist yet; the decision is made, the action is a TODO.
    override fun keepAlarms(on: Boolean) {}

    override fun restartCore() {
        core?.restart()
    }

    private companion object {
        const val ID_WARNING = 1002
    }
}
