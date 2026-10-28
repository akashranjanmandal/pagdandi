package app.pagdandi.pagdandi_native

/**
 * Tracks one outgoing SMS made of [parts] parts and turns the radio's
 * per-part results into whole-message status changes, each emitted once.
 * Any failure finishes the message as failed (the Dart outbox retries it).
 */
class SmsProgress(val parts: Int) {
    init {
        require(parts >= 1) { "a message has at least one part" }
    }

    private var sent = 0
    private var delivered = 0
    private var failed = false
    private var sentReported = false
    private var deliveredReported = false

    /** True once the message is delivered or failed: nothing more is reported. */
    val isFinished: Boolean
        get() = failed || deliveredReported

    fun onPartSent(ok: Boolean): List<SmsStatusDto> {
        if (isFinished) return emptyList()
        if (!ok) return fail()
        sent++
        if (sent == parts && !sentReported) {
            sentReported = true
            return listOf(SmsStatusDto.SENT)
        }
        return emptyList()
    }

    fun onPartDelivered(ok: Boolean): List<SmsStatusDto> {
        if (isFinished) return emptyList()
        if (!ok) return fail()
        delivered++
        if (delivered == parts) {
            deliveredReported = true
            return listOf(SmsStatusDto.DELIVERED)
        }
        return emptyList()
    }

    private fun fail(): List<SmsStatusDto> {
        failed = true
        return listOf(SmsStatusDto.FAILED)
    }
}
