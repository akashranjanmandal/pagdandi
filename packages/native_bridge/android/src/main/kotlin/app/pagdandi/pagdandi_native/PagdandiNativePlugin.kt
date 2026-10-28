package app.pagdandi.pagdandi_native

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/** Registers the Pigeon host API and forwards native events (battery, SMS, signal) to Dart. */
class PagdandiNativePlugin : FlutterPlugin {
    private var context: Context? = null
    private val receivers = mutableListOf<BroadcastReceiver>()
    private var signal: SignalWatcher? = null
    private var locationController: LocationController? = null
    private var role: String? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    /** Calls into Dart; a Dart side that is not listening is not an error. */
    private fun toDart(block: suspend () -> Unit) {
        scope.launch {
            try {
                block()
            } catch (e: Exception) {
                // Engine detached or Dart not ready: nothing to do.
            }
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val ctx = binding.applicationContext
        context = ctx
        val flutterApi = PagdandiFlutterApi(binding.binaryMessenger)

        val sms = SmsSender(ctx, defaultSmsManager(ctx)) { id, status ->
            toDart { flutterApi.onSmsReport(id, status) }
        }
        val watcher = SignalWatcher(ctx) { state -> toDart { flutterApi.onSignalState(state) } }
        signal = watcher
        watcher.start()
        val location = LocationController(createLocationBackend(ctx)) { fixes ->
            toDart { flutterApi.onLocations(fixes) }
        }
        locationController = location
        PagdandiHostApi.setUp(
            binding.binaryMessenger,
            HostApiImpl(ctx, sms, watcher, location, RelayHolder.relay) { role ->
                // This engine says what it is: the core receives commands, the UI receives state.
                when (role) {
                    "core" -> {
                        RelayHolder.relay.registerCore { json -> toDart { flutterApi.onCommand(json) } }
                        AlarmBus.coreSink = { id -> toDart { flutterApi.onAlarm(id.toLong()) } }
                        AccelHolder.controller = AccelerometerController(SensorAccelBackend(ctx)) { batch ->
                            toDart { flutterApi.onAccelerometer(batch) }
                        }
                    }
                    "ui" -> RelayHolder.relay.registerUi { json -> toDart { flutterApi.onState(json) } }
                }
                this.role = role
            },
        )

        register(ctx, IntentFilter(Intent.ACTION_BATTERY_CHANGED), exported = true,
            receiver = object : BroadcastReceiver() {
                override fun onReceive(c: Context, intent: Intent) {
                    val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                    val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
                    if (level >= 0 && scale > 0) {
                        toDart { flutterApi.onBatteryLevel((level * 100L) / scale) }
                    }
                }
            })
        register(ctx, IntentFilter(SmsSender.ACTION_SENT), exported = false,
            receiver = object : BroadcastReceiver() {
                override fun onReceive(c: Context, intent: Intent) {
                    val id = intent.getStringExtra(SmsSender.EXTRA_ID) ?: return
                    sms.onSent(id, resultCode)
                }
            })
        register(ctx, IntentFilter(SmsSender.ACTION_DELIVERED), exported = false,
            receiver = object : BroadcastReceiver() {
                override fun onReceive(c: Context, intent: Intent) {
                    val id = intent.getStringExtra(SmsSender.EXTRA_ID) ?: return
                    sms.onDelivered(id, resultCode)
                }
            })
    }

    private fun register(ctx: Context, filter: IntentFilter, exported: Boolean, receiver: BroadcastReceiver) {
        receivers.add(receiver)
        ContextCompat.registerReceiver(
            ctx, receiver, filter,
            if (exported) ContextCompat.RECEIVER_EXPORTED else ContextCompat.RECEIVER_NOT_EXPORTED,
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        PagdandiHostApi.setUp(binding.binaryMessenger, null)
        signal?.stop()
        signal = null
        locationController?.stop()
        locationController = null
        when (role) {
            "core" -> {
                RelayHolder.relay.unregisterCore()
                AlarmBus.coreSink = null
                AccelHolder.controller?.stop()
                AccelHolder.controller = null
            }
            "ui" -> RelayHolder.relay.unregisterUi()
        }
        role = null
        scope.cancel()
        val ctx = context
        receivers.forEach { ctx?.unregisterReceiver(it) }
        receivers.clear()
        context = null
    }
}
