package app.pagdandi.pagdandi_native

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File

class RecordingActions : GuardActions {
    val sent = mutableListOf<String>()
    val warnings = mutableListOf<Boolean>()
    val alarms = mutableListOf<Boolean>()
    var restarts = 0
    override fun sendSms(m: GuardMessage) { sent.add(m.id) }
    override fun showWarning(show: Boolean) { warnings.add(show) }
    override fun keepAlarms(on: Boolean) { alarms.add(on) }
    override fun restartCore() { restarts++ }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class GuardRunnerTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private lateinit var file: File
    private lateinit var db: SQLiteDatabase
    private lateinit var outbox: GuardOutbox
    private lateinit var heartbeat: HeartbeatStore
    private val actions = RecordingActions()
    private var now = 1_761_573_600_000L

    @Before
    fun setUp() {
        file = File(context.cacheDir, "runner.sqlite").also { it.delete() }
        db = SQLiteDatabase.openOrCreateDatabase(file, null)
        db.execSQL(
            """CREATE TABLE sms_outbox (id TEXT NOT NULL PRIMARY KEY, recipient TEXT NOT NULL, body TEXT NOT NULL,
              kind TEXT NOT NULL, status TEXT NOT NULL, attempts INTEGER NOT NULL, created_at TEXT NOT NULL,
              next_attempt_at TEXT NOT NULL, last_attempt_at TEXT NULL, guard_status TEXT NULL,
              guard_attempts INTEGER NOT NULL DEFAULT 0, guard_updated_at TEXT NULL)""",
        )
        outbox = GuardOutbox(db)
        heartbeat = HeartbeatStore(context)
        heartbeat.clear()
    }

    @After
    fun tearDown() { db.close(); file.delete() }

    private fun sos(id: String) = db.execSQL(
        "INSERT INTO sms_outbox (id, recipient, body, kind, status, attempts, created_at, next_attempt_at) VALUES (?,?,?,?,?,?,?,?)",
        arrayOf<Any>(id, "+91", "help", "sos", "queued", 0, GuardOutbox.iso(now), GuardOutbox.iso(now)),
    )

    private fun runner() = GuardRunner(outbox, heartbeat, actions) { now }

    @Test
    fun `a live core is left alone and no warning is shown`() {
        sos("a|+91A")
        heartbeat.beat(now - 1_000)
        runner().runOnce()
        assertTrue(actions.sent.isEmpty())
        assertEquals(listOf(false), actions.warnings)
        assertEquals(0, actions.restarts)
    }

    @Test
    fun `a dead core makes the guard send the pending SOS, warn and restart the core`() {
        sos("a|+91A")
        sos("b|+91B")
        heartbeat.beat(now - 40_000)
        runner().runOnce()
        assertEquals(listOf("a|+91A", "b|+91B"), actions.sent)
        assertEquals(listOf(true), actions.warnings)
        assertEquals(1, actions.restarts)
    }

    @Test
    fun `messages the guard sends are marked sending so they are not sent twice`() {
        sos("a|+91A")
        heartbeat.beat(now - 40_000)
        runner().runOnce()
        now += 11_000
        runner().runOnce()
        assertEquals(listOf("a|+91A"), actions.sent)
    }

    @Test
    fun `an active SOS keeps its alarms on while the core is dead, then releases them`() {
        sos("a|+91A")
        heartbeat.beat(now - 40_000)
        runner().runOnce()
        assertEquals(listOf(true), actions.alarms)
        heartbeat.beat(now)
        runner().runOnce()
        assertEquals(listOf(true, false), actions.alarms)
    }

    @Test
    fun `restarts are rate limited to one per minute`() {
        heartbeat.beat(now - 40_000)
        runner().runOnce()
        now += 10_000
        runner().runOnce()
        now += 10_000
        runner().runOnce()
        assertEquals(1, actions.restarts)
        now += 50_000
        runner().runOnce()
        assertEquals(2, actions.restarts)
    }

    @Test
    fun `the warning is withdrawn when the core comes back`() {
        heartbeat.beat(now - 40_000)
        runner().runOnce()
        heartbeat.beat(now)
        runner().runOnce()
        assertEquals(listOf(true, false), actions.warnings)
    }

    @Test
    fun `a core that never beat since boot counts as dead`() {
        runner().runOnce()
        assertEquals(1, actions.restarts)
        assertEquals(listOf(true), actions.warnings)
    }

    @Test
    fun `heartbeat store round trips and can be cleared`() {
        assertEquals(null, heartbeat.last())
        heartbeat.beat(5L)
        assertEquals(5L, heartbeat.last())
        heartbeat.clear()
        assertEquals(null, heartbeat.last())
        assertFalse(heartbeat.trekActive)
        heartbeat.trekActive = true
        assertTrue(heartbeat.trekActive)
    }
}
