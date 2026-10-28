package app.pagdandi.pagdandi_native

/**
 * Carries commands from the UI engine to the headless core engine, and the
 * core's state back to the UI. The two live in separate Flutter engines of one
 * process. Commands sent while the core is still starting are queued (bounded)
 * and delivered in order; a UI that appears later immediately gets the latest
 * state. A failing sink never breaks the relay.
 */
class Relay(private val maxQueued: Int = 50) {
    private var core: ((String) -> Unit)? = null
    private var ui: ((String) -> Unit)? = null
    private val pending = ArrayDeque<String>()
    private var lastState: String? = null

    @Synchronized
    fun registerCore(sink: (String) -> Unit) {
        core = sink
        while (pending.isNotEmpty()) {
            val next = pending.first()
            if (!safe(sink, next)) break
            pending.removeFirst()
        }
    }

    @Synchronized
    fun unregisterCore() {
        core = null
    }

    @Synchronized
    fun registerUi(sink: (String) -> Unit) {
        ui = sink
        lastState?.let { safe(sink, it) }
    }

    @Synchronized
    fun unregisterUi() {
        ui = null
    }

    @Synchronized
    fun command(json: String) {
        val sink = core
        if (sink != null && safe(sink, json)) return
        pending.addLast(json)
        while (pending.size > maxQueued) pending.removeFirst()
    }

    @Synchronized
    fun state(json: String) {
        lastState = json
        ui?.let { safe(it, json) }
    }

    private fun safe(sink: (String) -> Unit, value: String): Boolean =
        try {
            sink(value)
            true
        } catch (e: Exception) {
            false
        }
}

/** The one relay of this process, shared by the UI and core engines. */
object RelayHolder {
    val relay = Relay()
}
