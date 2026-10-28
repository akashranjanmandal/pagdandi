package app.pagdandi.pagdandi_native

import android.database.sqlite.SQLiteDatabase
import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter

/** A message the guard may send. */
data class GuardMessage(val id: String, val to: String, val body: String, val kind: String)

/**
 * The guard's view of the shared SQLite `sms_outbox`. It reads the Dart
 * columns and writes ONLY its own (`guard_*`), each update in a transaction,
 * so the two writers never overwrite each other.
 */
class GuardOutbox(private val db: SQLiteDatabase) {
    /** Messages the guard should send now. */
    fun dueForGuard(nowMs: Long): List<GuardMessage> {
        val now = iso(nowMs)
        val stale = iso(nowMs - STALE_SENT_MS)
        val out = mutableListOf<GuardMessage>()
        db.rawQuery(
            """SELECT id, recipient, body, kind FROM sms_outbox
               WHERE status NOT IN ('delivered','cancelled')
                 AND COALESCE(guard_status,'') NOT IN ('sending','sent','delivered')
                 AND ( (status IN ('queued','failed') AND next_attempt_at <= ?)
                    OR (status IN ('sending','sent') AND last_attempt_at IS NOT NULL AND last_attempt_at <= ?) )
               ORDER BY created_at, rowid""",
            arrayOf(now, stale),
        ).use { c ->
            while (c.moveToNext()) out.add(GuardMessage(c.getString(0), c.getString(1), c.getString(2), c.getString(3)))
        }
        return out
    }

    /** Records the guard's progress on one message. Only `sending` counts as an attempt. */
    fun markGuard(id: String, status: String, nowMs: Long) {
        db.beginTransaction()
        try {
            db.execSQL(
                "UPDATE sms_outbox SET guard_status = ?, guard_attempts = guard_attempts + ?, guard_updated_at = ? WHERE id = ?",
                arrayOf<Any>(status, if (status == "sending") 1 else 0, iso(nowMs), id),
            )
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    /** The guard's recorded status for [id], or null. */
    fun guardStatus(id: String): String? =
        db.rawQuery("SELECT guard_status FROM sms_outbox WHERE id = ?", arrayOf(id)).use { c ->
            if (c.moveToFirst()) c.getString(0) else null
        }

    /** Messages not yet delivered or cancelled. */
    fun pendingCount(): Int =
        db.rawQuery(
            """SELECT COUNT(*) FROM sms_outbox
               WHERE status NOT IN ('delivered','cancelled') AND COALESCE(guard_status,'') != 'delivered'""",
            null,
        ).use { c -> if (c.moveToFirst()) c.getInt(0) else 0 }

    /** Whether the latest SOS has not been cancelled. */
    fun sosActive(): Boolean {
        data class Row(val id: String, val kind: String, val status: String)
        val rows = mutableListOf<Row>()
        db.rawQuery("SELECT id, kind, status FROM sms_outbox ORDER BY created_at, rowid", null).use { c ->
            while (c.moveToNext()) rows.add(Row(c.getString(0), c.getString(1), c.getString(2)))
        }
        val latest = rows.lastOrNull { it.kind == "sos" } ?: return false
        val sosId = latest.id.substringBefore('|')
        return rows.none { (it.id == sosId || it.id.startsWith("$sosId|")) && (it.kind == "cancel" || it.status == "cancelled") }
    }

    companion object {
        private const val STALE_SENT_MS = 5 * 60_000L

        // Same shape as Dart's toIso8601String for UTC with milliseconds, so
        // text comparison in SQL orders times correctly.
        private val FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").withZone(ZoneOffset.UTC)

        fun iso(ms: Long): String = FORMAT.format(Instant.ofEpochMilli(ms))
    }
}
