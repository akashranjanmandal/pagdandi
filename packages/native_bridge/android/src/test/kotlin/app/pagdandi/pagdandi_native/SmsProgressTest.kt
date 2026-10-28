package app.pagdandi.pagdandi_native

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SmsProgressTest {
    @Test
    fun `a single part goes sent then delivered`() {
        val p = SmsProgress(parts = 1)
        assertEquals(listOf(SmsStatusDto.SENT), p.onPartSent(ok = true))
        assertEquals(listOf(SmsStatusDto.DELIVERED), p.onPartDelivered(ok = true))
    }

    @Test
    fun `sent is reported only when every part has left the phone`() {
        val p = SmsProgress(parts = 3)
        assertTrue(p.onPartSent(ok = true).isEmpty())
        assertTrue(p.onPartSent(ok = true).isEmpty())
        assertEquals(listOf(SmsStatusDto.SENT), p.onPartSent(ok = true))
    }

    @Test
    fun `delivered is reported only when every part is delivered`() {
        val p = SmsProgress(parts = 2)
        p.onPartSent(ok = true)
        p.onPartSent(ok = true)
        assertTrue(p.onPartDelivered(ok = true).isEmpty())
        assertEquals(listOf(SmsStatusDto.DELIVERED), p.onPartDelivered(ok = true))
    }

    @Test
    fun `one part failing to send fails the whole message once`() {
        val p = SmsProgress(parts = 3)
        p.onPartSent(ok = true)
        assertEquals(listOf(SmsStatusDto.FAILED), p.onPartSent(ok = false))
        assertTrue(p.onPartSent(ok = false).isEmpty())
        assertTrue(p.onPartSent(ok = true).isEmpty())
    }

    @Test
    fun `a failed delivery report fails the message`() {
        val p = SmsProgress(parts = 1)
        p.onPartSent(ok = true)
        assertEquals(listOf(SmsStatusDto.FAILED), p.onPartDelivered(ok = false))
    }

    @Test
    fun `nothing is reported after the message is finished`() {
        val p = SmsProgress(parts = 1)
        p.onPartSent(ok = true)
        p.onPartDelivered(ok = true)
        assertTrue(p.onPartSent(ok = true).isEmpty())
        assertTrue(p.onPartDelivered(ok = true).isEmpty())
        assertTrue(p.isFinished)
    }

    @Test
    fun `a delivery report that arrives first still completes the message`() {
        val p = SmsProgress(parts = 1)
        assertEquals(listOf(SmsStatusDto.DELIVERED), p.onPartDelivered(ok = true))
        assertTrue(p.isFinished)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `a message has at least one part`() {
        SmsProgress(parts = 0)
    }
}
