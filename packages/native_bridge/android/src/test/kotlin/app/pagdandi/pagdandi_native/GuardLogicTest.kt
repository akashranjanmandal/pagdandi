package app.pagdandi.pagdandi_native

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class GuardLogicTest {
    private val now = 1_000_000L

    private fun input(
        heartbeat: Long? = now - 5_000,
        pending: Int = 0,
        sos: Boolean = false,
        lastRestart: Long? = null,
    ) = GuardInput(nowMs = now, lastHeartbeatMs = heartbeat, pendingSms = pending, sosActive = sos, lastRestartMs = lastRestart)

    @Test
    fun `a core with a fresh heartbeat is left alone`() {
        val d = GuardLogic.decide(input(pending = 3, sos = true))
        assertTrue(d.coreAlive)
        assertFalse(d.flushSms)
        assertFalse(d.keepAlarms)
        assertFalse(d.warn)
        assertFalse(d.restartCore)
    }

    @Test
    fun `a heartbeat exactly 30 seconds old is still alive`() {
        assertTrue(GuardLogic.decide(input(heartbeat = now - 30_000)).coreAlive)
    }

    @Test
    fun `a missing heartbeat for over 30 seconds means the core is dead`() {
        val d = GuardLogic.decide(input(heartbeat = now - 30_001))
        assertFalse(d.coreAlive)
        assertTrue(d.warn)
        assertTrue(d.restartCore)
    }

    @Test
    fun `no heartbeat ever means dead`() {
        assertFalse(GuardLogic.decide(input(heartbeat = null)).coreAlive)
    }

    @Test
    fun `when the core is dead the guard flushes the SMS outbox if anything is pending`() {
        assertTrue(GuardLogic.decide(input(heartbeat = null, pending = 2)).flushSms)
        assertFalse(GuardLogic.decide(input(heartbeat = null, pending = 0)).flushSms)
    }

    @Test
    fun `when the core is dead an active SOS keeps its beacon and siren on`() {
        assertTrue(GuardLogic.decide(input(heartbeat = null, sos = true)).keepAlarms)
        assertFalse(GuardLogic.decide(input(heartbeat = null, sos = false)).keepAlarms)
    }

    @Test
    fun `the core is restarted at once the first time, then only after the cooldown`() {
        assertTrue(GuardLogic.decide(input(heartbeat = null, lastRestart = null)).restartCore)
        assertFalse(GuardLogic.decide(input(heartbeat = null, lastRestart = now - 59_000)).restartCore)
        assertTrue(GuardLogic.decide(input(heartbeat = null, lastRestart = now - 60_000)).restartCore)
    }

    @Test
    fun `the warning stays up for as long as the core is dead, even during the cooldown`() {
        assertTrue(GuardLogic.decide(input(heartbeat = null, lastRestart = now - 1_000)).warn)
    }

    @Test
    fun `constants match the spec`() {
        assertEquals(30_000L, GuardLogic.HEARTBEAT_TIMEOUT_MS)
        assertEquals(60_000L, GuardLogic.RESTART_COOLDOWN_MS)
    }
}
