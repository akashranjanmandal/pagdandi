package app.pagdandi.pagdandi_native

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Registers the Pigeon host API and forwards battery changes to Dart. */
class PagdandiNativePlugin : FlutterPlugin {
    private var context: Context? = null
    private var receiver: BroadcastReceiver? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val ctx = binding.applicationContext
        context = ctx
        PagdandiHostApi.setUp(binding.binaryMessenger, HostApiImpl(ctx))
        val flutterApi = PagdandiFlutterApi(binding.binaryMessenger)
        receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context, intent: Intent) {
                val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
                if (level >= 0 && scale > 0) {
                    flutterApi.onBatteryLevel((level * 100L) / scale) {}
                }
            }
        }
        ctx.registerReceiver(receiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        PagdandiHostApi.setUp(binding.binaryMessenger, null)
        receiver?.let { context?.unregisterReceiver(it) }
        receiver = null
        context = null
    }
}
