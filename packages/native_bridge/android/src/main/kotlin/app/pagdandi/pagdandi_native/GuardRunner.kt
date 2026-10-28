package app.pagdandi.pagdandi_native

/** What the guard can do in the world. */
interface GuardActions {
    fun sendSms(m: GuardMessage)

    fun showWarning(show: Boolean)

    fun keepAlarms(on: Boolean)

    fun restartCore()
}

/** One pass of the safety guard: look, decide, act. Called every few seconds. */
class GuardRunner(
    private val outbox: GuardOutbox,
    private val heartbeat: HeartbeatStore,
    private val actions: GuardActions,
    private val clock: () -> Long,
) {
    fun runOnce() {
        val now = clock()
        val d = GuardLogic.decide(
            GuardInput(
                nowMs = now,
                lastHeartbeatMs = heartbeat.last(),
                pendingSms = outbox.pendingCount(),
                sosActive = outbox.sosActive(),
                lastRestartMs = heartbeat.lastRestart(),
            ),
        )
        actions.showWarning(d.warn)
        actions.keepAlarms(d.keepAlarms)
        if (d.flushSms) {
            for (m in outbox.dueForGuard(now)) {
                outbox.markGuard(m.id, "sending", now)
                actions.sendSms(m)
            }
        }
        if (d.restartCore) {
            heartbeat.recordRestart(now)
            actions.restartCore()
        }
    }
}
