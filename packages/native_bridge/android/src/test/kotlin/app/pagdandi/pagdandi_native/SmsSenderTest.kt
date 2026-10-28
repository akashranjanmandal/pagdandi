package app.pagdandi.pagdandi_native

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.telephony.SmsManager
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Records what the radio was asked to do. Robolectric cannot emulate SmsManager itself. */
class RecordingRadio(private val partSize: Int = 160, private val error: Exception? = null) : SmsManagerFacade {
    var to: String? = null
    var parts: List<String> = emptyList()
    var sentIntents: List<PendingIntent?> = emptyList()
    var deliveryIntents: List<PendingIntent?> = emptyList()

    override fun divide(text: String): ArrayList<String> = ArrayList(text.chunked(partSize))

    override fun send(
        to: String,
        parts: ArrayList<String>,
        sent: ArrayList<PendingIntent?>,
        delivered: ArrayList<PendingIntent?>,
    ) {
        error?.let { throw it }
        this.to = to
        this.parts = parts
        this.sentIntents = sent
        this.deliveryIntents = delivered
    }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class SmsSenderTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private val reports = mutableListOf<Pair<String, SmsStatusDto>>()

    private fun sender(radio: SmsManagerFacade?) =
        SmsSender(context, radio) { id, s -> reports.add(id to s) }

    @Test
    fun `sending hands the text to the radio and reports sending`() {
        val radio = RecordingRadio()
        sender(radio).send("sos-1|+91A", "+91A", "SOS Akash needs help")
        assertEquals("+91A", radio.to)
        assertEquals("SOS Akash needs help", radio.parts.joinToString(""))
        assertEquals(listOf("sos-1|+91A" to SmsStatusDto.SENDING), reports)
    }

    @Test
    fun `a long message is split into parts and each gets its own intents`() {
        val radio = RecordingRadio(partSize = 153)
        val body = "x".repeat(400)
        sender(radio).send("id", "+91A", body)
        assertTrue(radio.parts.size > 1)
        assertEquals(radio.parts.size, radio.sentIntents.size)
        assertEquals(radio.parts.size, radio.deliveryIntents.size)
        assertTrue(radio.sentIntents.all { it != null })
        assertEquals(body, radio.parts.joinToString(""))
    }

    @Test
    fun `every result intent says how many parts the message has`() {
        val radio = RecordingRadio(partSize = 5)
        sender(radio).send("id", "+91A", "0123456789ABCDE") // 3 parts
        val intents = (radio.sentIntents + radio.deliveryIntents).filterNotNull()
        assertEquals(6, intents.size)
        for (pi in intents) {
            val saved = org.robolectric.Shadows.shadowOf(pi).savedIntent
            assertEquals(3, saved.getIntExtra(SmsSender.EXTRA_PARTS, -1))
        }
    }

    @Test
    fun `sent and delivered results flow through to reports`() {
        val s = sender(RecordingRadio())
        s.send("id", "+91A", "hi")
        s.onSent("id", Activity.RESULT_OK)
        s.onDelivered("id", Activity.RESULT_OK)
        assertEquals(
            listOf(SmsStatusDto.SENDING, SmsStatusDto.SENT, SmsStatusDto.DELIVERED),
            reports.map { it.second },
        )
    }

    @Test
    fun `every part must be sent before the message counts as sent`() {
        val s = sender(RecordingRadio(partSize = 5))
        s.send("id", "+91A", "0123456789ABCDE") // 3 parts
        s.onSent("id", Activity.RESULT_OK)
        s.onSent("id", Activity.RESULT_OK)
        assertEquals(listOf(SmsStatusDto.SENDING), reports.map { it.second })
        s.onSent("id", Activity.RESULT_OK)
        assertEquals(SmsStatusDto.SENT, reports.last().second)
    }

    @Test
    fun `a radio error reports failed`() {
        val s = sender(RecordingRadio())
        s.send("id", "+91A", "hi")
        s.onSent("id", SmsManager.RESULT_ERROR_NO_SERVICE)
        assertEquals(SmsStatusDto.FAILED, reports.last().second)
    }

    @Test
    fun `a failed delivery report reports failed`() {
        val s = sender(RecordingRadio())
        s.send("id", "+91A", "hi")
        s.onSent("id", Activity.RESULT_OK)
        s.onDelivered("id", Activity.RESULT_CANCELED)
        assertEquals(SmsStatusDto.FAILED, reports.last().second)
    }

    @Test
    fun `results for unknown ids are ignored`() {
        val s = sender(RecordingRadio())
        s.onSent("nope", Activity.RESULT_OK)
        s.onDelivered("nope", Activity.RESULT_OK)
        assertTrue(reports.isEmpty())
    }

    @Test
    fun `a finished message is forgotten so late results are ignored`() {
        val s = sender(RecordingRadio())
        s.send("id", "+91A", "hi")
        s.onSent("id", Activity.RESULT_OK)
        s.onDelivered("id", Activity.RESULT_OK)
        val before = reports.size
        s.onDelivered("id", Activity.RESULT_OK)
        assertEquals(before, reports.size)
    }

    @Test
    fun `no radio reports failed instead of crashing`() {
        sender(null).send("id", "+91A", "hi")
        assertEquals(listOf("id" to SmsStatusDto.FAILED), reports)
    }

    @Test
    fun `a radio that throws reports failed instead of crashing`() {
        sender(RecordingRadio(error = SecurityException("SEND_SMS not granted"))).send("id", "+91A", "hi")
        assertEquals(SmsStatusDto.FAILED, reports.last().second)
        // and a later result for it is ignored
        val n = reports.size
        sender(RecordingRadio()).onSent("id", Activity.RESULT_OK)
        assertEquals(n, reports.size)
    }
}
