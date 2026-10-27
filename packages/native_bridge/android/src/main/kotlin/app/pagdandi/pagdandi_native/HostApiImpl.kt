package app.pagdandi.pagdandi_native

import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.os.BatteryManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator

/** Android implementation of the Pigeon host API. Failures degrade to "not supported". */
class HostApiImpl(private val context: Context) : PagdandiHostApi {
    private val vibrator: Vibrator? =
        context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator

    override fun deviceCapabilities(): DeviceCapabilities {
        val sensors = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        val adapter = (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
        val hasBle = context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)
        return DeviceCapabilities(
            sdkInt = Build.VERSION.SDK_INT.toLong(),
            leCodedPhySupported = hasBle && safeBool { adapter?.isLeCodedPhySupported == true },
            leExtendedAdvertisingSupported =
                hasBle && safeBool { adapter?.isLeExtendedAdvertisingSupported == true },
            hasBarometer = sensors?.getDefaultSensor(Sensor.TYPE_PRESSURE) != null,
            hasSignificantMotion = sensors?.getDefaultSensor(Sensor.TYPE_SIGNIFICANT_MOTION) != null,
        )
    }

    override fun batteryLevel(): Long {
        val bm = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        val level = bm?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: 0
        return level.coerceIn(0, 100).toLong()
    }

    override fun playHaptic(request: HapticRequest) {
        val v = vibrator ?: return
        val spec = buildWaveform(request.timings, request.repeat, request.strong)
        v.vibrate(VibrationEffect.createWaveform(spec.timings, spec.amplitudes, spec.repeatIndex))
    }

    override fun cancelHaptic() {
        vibrator?.cancel()
    }

    // Some phones throw (permissions, missing radio): report "not supported" instead.
    private fun safeBool(block: () -> Boolean): Boolean =
        try {
            block()
        } catch (e: Exception) {
            false
        }
}
