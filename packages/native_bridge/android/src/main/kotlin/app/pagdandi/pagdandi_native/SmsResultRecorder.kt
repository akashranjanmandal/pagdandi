package app.pagdandi.pagdandi_native

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase

/**
 * Writes an SMS result into the shared outbox even when the Dart core is not
 * running (its process died), so the guard and the core know the message left
 * the phone and no duplicate SOS is sent.
 *
 * Only single-part messages are recorded: with several parts, reports can
 * arrive out of order, and claiming "delivered" too early would be worse than
 * a duplicate. Failures are never recorded here; the core retries them.
 */
object SmsResultRecorder {
    fun record(
        db: SQLiteDatabase,
        action: String,
        id: String,
        parts: Int,
        resultCode: Int,
        nowMs: Long,
    ) {
        if (parts != 1 || resultCode != Activity.RESULT_OK) return
        val status = when (action) {
            SmsSender.ACTION_DELIVERED -> "delivered"
            SmsSender.ACTION_SENT -> "sent"
            else -> return
        }
        try {
            val outbox = GuardOutbox(db)
            // A late "sent" must never undo "delivered".
            if (status == "sent" && outbox.guardStatus(id) == "delivered") return
            outbox.markGuard(id, status, nowMs)
        } catch (e: Exception) {
            // Recording is best effort; the core's own path still runs.
        }
    }
}

/**
 * Receives the radio's SENT / DELIVERED results straight from the system,
 * also when the app process was restarted for them.
 */
class SmsResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(SmsSender.EXTRA_ID) ?: return
        val parts = intent.getIntExtra(SmsSender.EXTRA_PARTS, 0)
        val action = intent.action ?: return
        val file = GuardPaths.databaseFile(context)
        if (!file.exists()) return
        var db: SQLiteDatabase? = null
        try {
            db = GuardDatabase.open(file)
            SmsResultRecorder.record(db, action, id, parts, resultCode, System.currentTimeMillis())
        } catch (e: Exception) {
            // Never crash the receiver.
        } finally {
            db?.close()
        }
    }
}
