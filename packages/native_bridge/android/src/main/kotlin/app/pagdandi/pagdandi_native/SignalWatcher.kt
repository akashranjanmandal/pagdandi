package app.pagdandi.pagdandi_native

import android.content.Context
import android.os.Build
import android.telephony.PhoneStateListener
import android.telephony.ServiceState
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager

/**
 * Reads and watches the mobile service state. Fail safe: if the state cannot
 * be read (no permission, no radio) it reports IN_SERVICE, so an SOS still
 * tries to send and the retry logic takes over, instead of waiting forever.
 */
class SignalWatcher(
    context: Context,
    private val onChange: (SignalStateDto) -> Unit = {},
) {
    private val appContext = context.applicationContext
    private val telephony = appContext.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
    private var callback: Any? = null

    fun current(): SignalStateDto =
        try {
            telephony?.serviceState?.let { signalStateOf(it.state) } ?: SignalStateDto.IN_SERVICE
        } catch (e: SecurityException) {
            SignalStateDto.IN_SERVICE
        }

    fun start() {
        val tm = telephony ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val cb = object : TelephonyCallback(), TelephonyCallback.ServiceStateListener {
                    override fun onServiceStateChanged(serviceState: ServiceState) =
                        onChange(signalStateOf(serviceState.state))
                }
                callback = cb
                tm.registerTelephonyCallback(appContext.mainExecutor, cb)
            } else {
                @Suppress("DEPRECATION")
                val l = object : PhoneStateListener() {
                    @Deprecated("Deprecated in Java")
                    override fun onServiceStateChanged(serviceState: ServiceState?) {
                        if (serviceState != null) onChange(signalStateOf(serviceState.state))
                    }
                }
                callback = l
                @Suppress("DEPRECATION")
                tm.listen(l, PhoneStateListener.LISTEN_SERVICE_STATE)
            }
        } catch (e: SecurityException) {
            // No permission: current() stays fail-safe, no live updates.
        }
    }

    fun stop() {
        val tm = telephony ?: return
        val cb = callback ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            tm.unregisterTelephonyCallback(cb as TelephonyCallback)
        } else {
            @Suppress("DEPRECATION")
            tm.listen(cb as PhoneStateListener, PhoneStateListener.LISTEN_NONE)
        }
        callback = null
    }
}
