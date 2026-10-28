package app.pagdandi.pagdandi_native

import android.content.Context

/**
 * Small shared state between the Dart core and the native guard: the core's
 * heartbeat, whether a trek is running (so boot can resume it), and when the
 * guard last restarted the core.
 */
class HeartbeatStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences("pagdandi_guard", Context.MODE_PRIVATE)

    fun beat(atMs: Long) = prefs.edit().putLong(KEY_BEAT, atMs).commit().let { }

    fun last(): Long? = if (prefs.contains(KEY_BEAT)) prefs.getLong(KEY_BEAT, 0) else null

    var trekActive: Boolean
        get() = prefs.getBoolean(KEY_TREK, false)
        set(v) {
            prefs.edit().putBoolean(KEY_TREK, v).commit()
        }

    fun lastRestart(): Long? = if (prefs.contains(KEY_RESTART)) prefs.getLong(KEY_RESTART, 0) else null

    fun recordRestart(atMs: Long) {
        prefs.edit().putLong(KEY_RESTART, atMs).commit()
    }

    fun clear() {
        prefs.edit().clear().commit()
    }

    private companion object {
        const val KEY_BEAT = "heartbeat"
        const val KEY_TREK = "trek_active"
        const val KEY_RESTART = "last_restart"
    }
}
