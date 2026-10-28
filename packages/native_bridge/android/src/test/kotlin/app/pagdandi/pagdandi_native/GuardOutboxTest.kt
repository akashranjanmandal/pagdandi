package app.pagdandi.pagdandi_native

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class GuardOutboxTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private lateinit var file: File
    private lateinit var db: SQLiteDatabase
    private lateinit var outbox: GuardOutbox

    private val t0 = 1_761_573_600_000L

    @Before
    fun setUp() {
        file = File(context.cacheDir, "trek-test.sqlite")
        file.delete()
        db = SQLiteDatabase.openOrCreateDatabase(file, null)
        db.execSQL(
            """CREATE TABLE sms_outbox (
              id TEXT NOT NULL PRIMARY KEY, recipient TEXT NOT NULL, body TEXT NOT NULL,
              kind TEXT NOT NULL, status TEXT NOT NULL, attempts INTEGER NOT NULL,
              created_at TEXT NOT NULL, next_attempt_at TEXT NOT NULL, last_attempt_at TEXT NULL,
              guard_status TEXT NULL, guard_attempts INTEGER NOT NULL DEFAULT 0, guard_updated_at TEXT NULL)""",
        )
        outbox = GuardOutbox(db)
    }

    @After
    fun tearDown() {
        db.close()
        file.delete()
    }

    private fun iso(ms: Long) = GuardOutbox.iso(ms)

    private fun row(
        id: String,
        status: String = "queued",
        kind: String = "sos",
        next: Long = t0,
        last: Long? = null,
        guard: String? = null,
    ) {
        db.execSQL(
            "INSERT INTO sms_outbox (id, recipient, body, kind, status, attempts, created_at, next_attempt_at, last_attempt_at, guard_status) VALUES (?,?,?,?,?,?,?,?,?,?)",
            arrayOf<Any?>(id, "+91$id", "body $id", kind, status, 0, iso(t0), iso(next), last?.let(::iso), guard),
        )
    }

    @Test
    fun `queued and failed messages that are due are pending for the guard`() {
        row("a", "queued")
        row("b", "failed")
        assertEquals(listOf("a", "b"), outbox.dueForGuard(t0).map { it.id })
    }

    @Test
    fun `a message whose retry time has not come is not due`() {
        row("a", "failed", next = t0 + 10_000)
        assertTrue(outbox.dueForGuard(t0).isEmpty())
        assertEquals(1, outbox.dueForGuard(t0 + 10_000).size)
    }

    @Test
    fun `delivered and cancelled messages are never due`() {
        row("a", "delivered")
        row("b", "cancelled")
        assertTrue(outbox.dueForGuard(t0).isEmpty())
    }

    @Test
    fun `a message the guard already delivered, sent or is sending is not sent twice`() {
        row("a", "queued", guard = "delivered")
        row("b", "queued", guard = "sent")
        row("c", "queued", guard = "sending")
        assertTrue(outbox.dueForGuard(t0).isEmpty())
    }

    @Test
    fun `a message the guard failed on is due again`() {
        row("a", "queued", guard = "failed")
        assertEquals(listOf("a"), outbox.dueForGuard(t0).map { it.id })
    }

    @Test
    fun `a message Dart left in sending or sent for over five minutes is due`() {
        row("a", "sending", last = t0 - 6 * 60_000)
        row("b", "sent", last = t0 - 6 * 60_000)
        row("c", "sending", last = t0 - 60_000)
        assertEquals(listOf("a", "b"), outbox.dueForGuard(t0).map { it.id })
    }

    @Test
    fun `due messages carry what is needed to send them`() {
        row("a")
        val m = outbox.dueForGuard(t0).single()
        assertEquals("+91a", m.to)
        assertEquals("body a", m.body)
        assertEquals("sos", m.kind)
    }

    @Test
    fun `marking a message writes only the guard columns, in one transaction`() {
        row("a", "queued")
        outbox.markGuard("a", "sending", t0)
        val c = db.rawQuery("SELECT status, attempts, guard_status, guard_attempts, guard_updated_at FROM sms_outbox WHERE id='a'", null)
        c.moveToFirst()
        assertEquals("queued", c.getString(0))
        assertEquals(0, c.getInt(1))
        assertEquals("sending", c.getString(2))
        assertEquals(1, c.getInt(3))
        assertEquals(iso(t0), c.getString(4))
        c.close()
    }

    @Test
    fun `only the sending mark counts as an attempt`() {
        row("a")
        outbox.markGuard("a", "sending", t0)
        outbox.markGuard("a", "sent", t0 + 1)
        outbox.markGuard("a", "delivered", t0 + 2)
        val c = db.rawQuery("SELECT guard_attempts, guard_status FROM sms_outbox WHERE id='a'", null)
        c.moveToFirst()
        assertEquals(1, c.getInt(0))
        assertEquals("delivered", c.getString(1))
        c.close()
    }

    @Test
    fun `marking an unknown id changes nothing`() {
        outbox.markGuard("nope", "sent", t0)
        assertEquals(0, db.rawQuery("SELECT 1 FROM sms_outbox", null).use { it.count })
    }

    @Test
    fun `pending count and sos activity are read from the table`() {
        assertEquals(0, outbox.pendingCount())
        assertEquals(false, outbox.sosActive())
        row("a", "queued", "sos")
        row("b", "delivered", "sos")
        row("c", "queued", "cancel")
        assertEquals(2, outbox.pendingCount())
        assertEquals(true, outbox.sosActive())
    }

    @Test
    fun `an SOS with a cancel message is no longer active`() {
        row("sos-1|+91A", "delivered", "sos")
        row("sos-1|+91A|cancel", "queued", "cancel")
        assertEquals(false, outbox.sosActive())
    }

    @Test
    fun `an SOS whose rows are all cancelled is not active`() {
        row("a", "cancelled", "sos")
        assertEquals(false, outbox.sosActive())
        assertNull(outbox.dueForGuard(t0).firstOrNull())
    }
}
