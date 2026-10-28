package app.pagdandi.pagdandi_native

import android.app.Activity
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class SmsResultRecorderTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private lateinit var file: File
    private lateinit var db: SQLiteDatabase
    private val now = 1_761_573_600_000L

    @Before
    fun setUp() {
        file = File(context.cacheDir, "recorder-test.sqlite")
        file.delete()
        db = SQLiteDatabase.openOrCreateDatabase(file, null)
        db.execSQL(
            """CREATE TABLE sms_outbox (
              id TEXT NOT NULL PRIMARY KEY, recipient TEXT NOT NULL, body TEXT NOT NULL,
              kind TEXT NOT NULL, status TEXT NOT NULL, attempts INTEGER NOT NULL,
              created_at TEXT NOT NULL, next_attempt_at TEXT NOT NULL, last_attempt_at TEXT NULL,
              guard_status TEXT NULL, guard_attempts INTEGER NOT NULL DEFAULT 0, guard_updated_at TEXT NULL)""",
        )
        db.execSQL(
            "INSERT INTO sms_outbox (id, recipient, body, kind, status, attempts, created_at, next_attempt_at) VALUES ('m1','+91','b','sos','sending',1,'t','t')",
        )
    }

    @After
    fun tearDown() {
        db.close()
        file.delete()
    }

    private fun guard(id: String = "m1"): String? =
        db.rawQuery("SELECT guard_status FROM sms_outbox WHERE id = ?", arrayOf(id)).use {
            if (it.moveToFirst()) it.getString(0) else null
        }

    @Test
    fun a_delivered_single_part_message_is_recorded_as_delivered() {
        SmsResultRecorder.record(db, SmsSender.ACTION_DELIVERED, "m1", parts = 1, resultCode = Activity.RESULT_OK, nowMs = now)
        assertEquals("delivered", guard())
    }

    @Test
    fun a_sent_single_part_message_is_recorded_as_sent() {
        SmsResultRecorder.record(db, SmsSender.ACTION_SENT, "m1", parts = 1, resultCode = Activity.RESULT_OK, nowMs = now)
        assertEquals("sent", guard())
    }

    @Test
    fun sent_never_downgrades_a_delivered_record() {
        SmsResultRecorder.record(db, SmsSender.ACTION_DELIVERED, "m1", 1, Activity.RESULT_OK, now)
        SmsResultRecorder.record(db, SmsSender.ACTION_SENT, "m1", 1, Activity.RESULT_OK, now + 1)
        assertEquals("delivered", guard())
    }

    @Test
    fun a_failure_is_never_recorded_as_success() {
        SmsResultRecorder.record(db, SmsSender.ACTION_DELIVERED, "m1", 1, Activity.RESULT_CANCELED, now)
        SmsResultRecorder.record(db, SmsSender.ACTION_SENT, "m1", 1, Activity.RESULT_CANCELED, now)
        assertNull(guard())
    }

    @Test
    fun multi_part_messages_are_left_to_the_core_so_a_miss_is_never_claimed() {
        SmsResultRecorder.record(db, SmsSender.ACTION_DELIVERED, "m1", parts = 2, resultCode = Activity.RESULT_OK, nowMs = now)
        assertNull(guard())
    }

    @Test
    fun an_unknown_message_changes_nothing_and_does_not_crash() {
        SmsResultRecorder.record(db, SmsSender.ACTION_DELIVERED, "nope", 1, Activity.RESULT_OK, now)
        assertNull(guard())
        assertEquals("sending", db.rawQuery("SELECT status FROM sms_outbox WHERE id='m1'", null).use { it.moveToFirst(); it.getString(0) })
    }

    @Test
    fun a_closed_database_is_swallowed() {
        db.close()
        SmsResultRecorder.record(db, SmsSender.ACTION_DELIVERED, "m1", 1, Activity.RESULT_OK, now)
    }
}
