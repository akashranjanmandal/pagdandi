package app.pagdandi.pagdandi_native

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Exact alarms that fire even in Doze and wake a dead process. Without the
 * exact-alarm permission the alarm is still scheduled (it may fire a little
 * late): an alarm is never silently dropped.
 */
class ExactAlarms(private val context: Context) {
    private val manager get() = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun schedule(id: Int, atMs: Long) {
        val pi = pending(id)
        val m = manager
        if (m.canScheduleExactAlarms()) {
            m.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMs, pi)
        } else {
            m.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMs, pi)
        }
    }

    fun cancel(id: Int) {
        manager.cancel(pending(id))
    }

    private fun pending(id: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            id,
            Intent(ACTION).setPackage(context.packageName).putExtra(EXTRA_ID, id),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    companion object {
        const val ACTION = "app.pagdandi.pagdandi_native.ALARM"
        const val EXTRA_ID = "alarm_id"
    }
}

/** Alarms that fired while the core was not running, kept until the core asks. */
class FiredAlarmStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences("pagdandi_alarms", Context.MODE_PRIVATE)

    @Synchronized
    fun add(id: Int) {
        val set = prefs.getStringSet(KEY, emptySet())!!.toMutableSet()
        set.add(id.toString())
        prefs.edit().putStringSet(KEY, set).commit()
    }

    /** Returns every kept alarm once and forgets them. */
    @Synchronized
    fun take(): List<Int> {
        val ids = prefs.getStringSet(KEY, emptySet())!!.mapNotNull { it.toIntOrNull() }
        prefs.edit().remove(KEY).commit()
        return ids
    }

    private companion object {
        const val KEY = "fired"
    }
}

/** Where a fired alarm goes when the core engine is running. */
object AlarmBus {
    @Volatile var coreSink: ((Int) -> Unit)? = null
}

object AlarmDispatcher {
    /**
     * An alarm fired. A running core gets it now; otherwise it is kept and,
     * if a trek is on, the trek service starts the core, which then asks for it.
     */
    fun dispatch(context: Context, id: Int) {
        val store = FiredAlarmStore(context)
        store.add(id)
        val sink = AlarmBus.coreSink
        if (sink != null) {
            try {
                val taken = store.take()
                taken.forEach { sink(it) }
            } catch (e: Exception) {
                // Keep it for the next core rather than lose it.
                store.add(id)
            }
            return
        }
        if (HeartbeatStore(context).trekActive) {
            try {
                context.startForegroundService(
                    Intent(context, TrekForegroundService::class.java).putExtra(TrekForegroundService.EXTRA_AT_BOOT, false),
                )
            } catch (e: Exception) {
                // The guard's own checks still run; the alarm stays stored.
            }
        }
    }
}

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!intent.hasExtra(ExactAlarms.EXTRA_ID)) return
        AlarmDispatcher.dispatch(context, intent.getIntExtra(ExactAlarms.EXTRA_ID, -1))
    }
}
