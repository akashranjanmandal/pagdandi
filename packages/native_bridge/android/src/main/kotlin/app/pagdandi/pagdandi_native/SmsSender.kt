package app.pagdandi.pagdandi_native

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.telephony.SmsManager
import java.util.concurrent.ConcurrentHashMap

/** The bits of SmsManager we use, so a failing radio can be simulated. */
interface SmsManagerFacade {
    fun divide(text: String): ArrayList<String>

    fun send(
        to: String,
        parts: ArrayList<String>,
        sent: ArrayList<PendingIntent?>,
        delivered: ArrayList<PendingIntent?>,
    )
}

private class RealSmsManager(private val m: SmsManager) : SmsManagerFacade {
    override fun divide(text: String): ArrayList<String> = m.divideMessage(text)

    override fun send(
        to: String,
        parts: ArrayList<String>,
        sent: ArrayList<PendingIntent?>,
        delivered: ArrayList<PendingIntent?>,
    ) = m.sendMultipartTextMessage(to, null, parts, sent, delivered)
}

/**
 * Sends SMS through the radio and reports progress per message id. Never
 * throws: a missing permission or radio is reported as failed so the Dart
 * outbox retries it.
 */
class SmsSender(
    private val context: Context,
    private val manager: SmsManagerFacade?,
    private val report: (id: String, status: SmsStatusDto) -> Unit,
) {
    constructor(
        context: Context,
        manager: SmsManager?,
        report: (id: String, status: SmsStatusDto) -> Unit,
    ) : this(context, manager?.let { RealSmsManager(it) }, report)

    private val inFlight = ConcurrentHashMap<String, SmsProgress>()

    fun send(id: String, to: String, body: String) {
        val m = manager
        if (m == null) {
            report(id, SmsStatusDto.FAILED)
            return
        }
        try {
            val parts = m.divide(body)
            inFlight[id] = SmsProgress(parts.size)
            report(id, SmsStatusDto.SENDING)
            val sent = ArrayList<PendingIntent?>()
            val delivered = ArrayList<PendingIntent?>()
            for (i in parts.indices) {
                sent.add(pending(ACTION_SENT, id, i, parts.size))
                delivered.add(pending(ACTION_DELIVERED, id, i, parts.size))
            }
            m.send(to, parts, sent, delivered)
        } catch (e: Exception) {
            inFlight.remove(id)
            report(id, SmsStatusDto.FAILED)
        }
    }

    fun onSent(id: String, resultCode: Int) {
        val p = inFlight[id] ?: return
        p.onPartSent(resultCode == Activity.RESULT_OK).forEach { report(id, it) }
        if (p.isFinished) inFlight.remove(id)
    }

    fun onDelivered(id: String, resultCode: Int) {
        val p = inFlight[id] ?: return
        p.onPartDelivered(resultCode == Activity.RESULT_OK).forEach { report(id, it) }
        if (p.isFinished) inFlight.remove(id)
    }

    private fun pending(action: String, id: String, part: Int, parts: Int): PendingIntent {
        val intent = Intent(action)
            .setPackage(context.packageName)
            .putExtra(EXTRA_ID, id)
            .putExtra(EXTRA_PARTS, parts)
        return PendingIntent.getBroadcast(
            context,
            (action + id + part).hashCode(),
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    companion object {
        const val ACTION_SENT = "app.pagdandi.pagdandi_native.SMS_SENT"
        const val ACTION_DELIVERED = "app.pagdandi.pagdandi_native.SMS_DELIVERED"
        const val EXTRA_ID = "id"
        const val EXTRA_PARTS = "parts"
    }
}
