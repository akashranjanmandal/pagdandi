package app.pagdandi.pagdandi_native

import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.os.BatteryManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.telephony.SmsManager

/** Android implementation of the Pigeon host API. Failures degrade to "not supported". */
class HostApiImpl(
    private val context: Context,
    private val sms: SmsSender = SmsSender(context, defaultSmsManager(context)) { _, _ -> },
    private val signal: SignalWatcher = SignalWatcher(context),
    location: LocationController? = null,
    private val relay: Relay = RelayHolder.relay,
    private val onRole: (String) -> Unit = {},
) : PagdandiHostApi {
    private val locationController: LocationController by lazy {
        location ?: LocationController(createLocationBackend(context)) { }
    }

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

    override fun sendSms(id: String, to: String, body: String) = sms.send(id, to, body)

    override fun signalState(): SignalStateDto = signal.current()

    override fun startLocation(request: LocationRequestDto) = locationController.start(request)

    override fun stopLocation() = locationController.stop()

    override fun healthSnapshot(): HealthSnapshotDto {
        fun granted(p: String) = context.checkSelfPermission(p) == android.content.pm.PackageManager.PERMISSION_GRANTED
        val pm = context.getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
        val freeMb = try {
            val stat = android.os.StatFs(context.filesDir.path)
            stat.availableBytes / (1024 * 1024)
        } catch (e: Exception) {
            // Unreadable storage is reported as 0 MB: the watchdog then warns instead of staying silent.
            0L
        }
        return HealthSnapshotDto(
            locationPermission = granted(android.Manifest.permission.ACCESS_FINE_LOCATION),
            backgroundLocationPermission = granted(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION),
            smsPermission = granted(android.Manifest.permission.SEND_SMS),
            notificationPermission = granted(android.Manifest.permission.POST_NOTIFICATIONS),
            batteryOptimizationExempt = pm?.isIgnoringBatteryOptimizations(context.packageName) ?: false,
            storageFreeMb = freeMb,
        )
    }

    override fun setRole(role: String) = onRole(role)

    override fun sendCommand(json: String) = relay.command(json)

    override fun publishState(json: String) = relay.state(json)

    override fun setTorch(on: Boolean, strobe: Boolean) {
        val torch = HardwareHolder.torch(context)
        if (strobe) torch.strobe(on) else torch.steady(on)
    }

    override fun setSiren(on: Boolean) {
        HardwareHolder.siren(context).set(on)
    }

    override fun openDialer(number: String) {
        DialerLauncher(context).open(number)
    }

    override fun scheduleAlarm(id: Long, atMs: Long) = ExactAlarms(context).schedule(id.toInt(), atMs)

    override fun cancelAlarm(id: Long) = ExactAlarms(context).cancel(id.toInt())

    override fun takeFiredAlarms(): List<Long> = FiredAlarmStore(context).take().map { it.toLong() }

    override fun speak(text: String, urgent: Boolean) {
        VoiceHolder.voice(context).speak(text, urgent)
    }

    override fun stopSpeaking() {
        VoiceHolder.voice(context).stop()
    }

    override fun startAccelerometer(periodMs: Long): Boolean {
        // The sink is the core engine's FlutterApi, wired by the plugin.
        val c = AccelHolder.controller ?: return false
        return c.start(periodMs.toInt())
    }

    override fun stopAccelerometer() {
        AccelHolder.controller?.stop()
    }

    override fun databasePath(): String = GuardPaths.databaseFile(context).path

    override fun heartbeat(atMs: Long) = HeartbeatStore(context).beat(atMs)

    override fun startTrekService() {
        context.startForegroundService(
            Intent(context, TrekForegroundService::class.java).putExtra(TrekForegroundService.EXTRA_AT_BOOT, false),
        )
    }

    override fun stopTrekService() {
        context.startService(Intent(context, TrekForegroundService::class.java).setAction(TrekForegroundService.ACTION_STOP))
    }

    // Some phones throw (permissions, missing radio): report "not supported" instead.
    private fun safeBool(block: () -> Boolean): Boolean =
        try {
            block()
        } catch (e: Exception) {
            false
        }
}

/** The default SMS manager, or null if the device has none. */
fun defaultSmsManager(context: Context): SmsManager? =
    try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(SmsManager::class.java)
        } else {
            @Suppress("DEPRECATION")
            SmsManager.getDefault()
        }
    } catch (e: Exception) {
        null
    }
