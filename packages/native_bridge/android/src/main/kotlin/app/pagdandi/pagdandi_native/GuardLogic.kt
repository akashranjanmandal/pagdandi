package app.pagdandi.pagdandi_native

/** What the guard knows at one moment. */
data class GuardInput(
    val nowMs: Long,
    val lastHeartbeatMs: Long?,
    val pendingSms: Int,
    val sosActive: Boolean,
    val lastRestartMs: Long?,
)

/** What the guard should do about it. */
data class GuardDecision(
    val coreAlive: Boolean,
    val flushSms: Boolean,
    val keepAlarms: Boolean,
    val warn: Boolean,
    val restartCore: Boolean,
)

/**
 * The safety guard's rules. If the Dart core's heartbeat is missing for more
 * than 30 s, the guard keeps the SOS SMS outbox flushing, keeps beacon/siren
 * on if an SOS is active, warns the user, and restarts the core (at most once
 * per cooldown so a crashing core cannot be restarted in a tight loop).
 */
object GuardLogic {
    const val HEARTBEAT_TIMEOUT_MS = 30_000L
    const val RESTART_COOLDOWN_MS = 60_000L

    fun decide(i: GuardInput): GuardDecision {
        val last = i.lastHeartbeatMs
        val alive = last != null && i.nowMs - last <= HEARTBEAT_TIMEOUT_MS
        if (alive) return GuardDecision(true, false, false, false, false)
        val restart = i.lastRestartMs == null || i.nowMs - i.lastRestartMs >= RESTART_COOLDOWN_MS
        return GuardDecision(
            coreAlive = false,
            flushSms = i.pendingSms > 0,
            keepAlarms = i.sosActive,
            warn = true,
            restartCore = restart,
        )
    }
}
