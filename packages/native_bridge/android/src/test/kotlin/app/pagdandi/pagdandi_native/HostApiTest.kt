package app.pagdandi.pagdandi_native

import android.content.Context
import android.os.BatteryManager
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class HostApiTest {
    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test
    fun `battery level comes from the battery manager and is clamped`() {
        val bm = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        shadowOf(bm).setIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY, 41)
        assertEquals(41L, HostApiImpl(context).batteryLevel())
        shadowOf(bm).setIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY, 250)
        assertEquals(100L, HostApiImpl(context).batteryLevel())
    }

    @Test
    fun `device capabilities report the sdk and never throw on missing hardware`() {
        val caps = HostApiImpl(context).deviceCapabilities()
        assertEquals(34L, caps.sdkInt)
        // Robolectric has no sensors or BLE: everything must degrade to false.
        assertTrue(!caps.hasBarometer)
        assertTrue(!caps.leCodedPhySupported)
        assertTrue(!caps.leExtendedAdvertisingSupported)
    }

    @Test
    fun `playing and cancelling a haptic does not crash`() {
        val api = HostApiImpl(context)
        api.playHaptic(HapticRequest(listOf(0L, 80L), repeat = false, strong = false))
        api.playHaptic(HapticRequest(listOf(0L, 400L, 150L, 400L), repeat = true, strong = true))
        api.cancelHaptic()
    }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class HostApiSmsSignalTest {
    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test
    fun `sendSms goes to the sender`() {
        val seen = mutableListOf<Pair<String, SmsStatusDto>>()
        val radio = RecordingRadio()
        val api = HostApiImpl(
            context,
            sms = SmsSender(context, radio) { id, s -> seen.add(id to s) },
        )
        api.sendSms("id", "+91A", "hello")
        assertEquals("+91A", radio.to)
        assertEquals(listOf("id" to SmsStatusDto.SENDING), seen)
    }

    @Test
    fun `signal state is read from the telephony service`() {
        val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as android.telephony.TelephonyManager
        val ss = android.telephony.ServiceState()
        ss.state = android.telephony.ServiceState.STATE_OUT_OF_SERVICE
        shadowOf(tm).setServiceState(ss)
        assertEquals(SignalStateDto.NO_SERVICE, HostApiImpl(context).signalState())
        ss.state = android.telephony.ServiceState.STATE_EMERGENCY_ONLY
        shadowOf(tm).setServiceState(ss)
        assertEquals(SignalStateDto.EMERGENCY_ONLY, HostApiImpl(context).signalState())
    }

    @Test
    fun `an unreadable signal state counts as in service so an SOS still tries to send`() {
        val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as android.telephony.TelephonyManager
        shadowOf(tm).setServiceState(null)
        assertEquals(SignalStateDto.IN_SERVICE, HostApiImpl(context).signalState())
    }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class HostApiServiceTest {
    private val app: android.app.Application = ApplicationProvider.getApplicationContext()

    @Test
    fun `the database path is the shared guard file`() {
        assertTrue(HostApiImpl(app).databasePath().endsWith("pagdandi.sqlite"))
        assertEquals(GuardPaths.databaseFile(app).path, HostApiImpl(app).databasePath())
    }

    @Test
    fun `a heartbeat from Dart is stored for the guard`() {
        HeartbeatStore(app).clear()
        HostApiImpl(app).heartbeat(12345L)
        assertEquals(12345L, HeartbeatStore(app).last())
    }

    @Test
    fun `starting the trek service starts the foreground service`() {
        HostApiImpl(app).startTrekService()
        val i = shadowOf(app).nextStartedService
        assertEquals(TrekForegroundService::class.java.name, i.component!!.className)
        assertEquals(false, i.getBooleanExtra(TrekForegroundService.EXTRA_AT_BOOT, true))
    }

    @Test
    fun `stopping the trek service sends the stop action`() {
        HostApiImpl(app).stopTrekService()
        val i = shadowOf(app).nextStartedService
        assertEquals(TrekForegroundService.ACTION_STOP, i.action)
    }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class HostApiRelayTest {
    private val app: android.app.Application = ApplicationProvider.getApplicationContext()

    @Test
    fun `sendCommand and publishState go through the relay`() {
        val relay = Relay()
        val cmds = mutableListOf<String>()
        val states = mutableListOf<String>()
        relay.registerCore { cmds.add(it) }
        relay.registerUi { states.add(it) }
        val api = HostApiImpl(app, relay = relay)
        api.sendCommand("{\"c\":\"sosPressed\"}")
        api.publishState("{\"s\":1}")
        assertEquals(listOf("{\"c\":\"sosPressed\"}"), cmds)
        assertEquals(listOf("{\"s\":1}"), states)
    }

    @Test
    fun `setRole tells the plugin which engine this is`() {
        val roles = mutableListOf<String>()
        HostApiImpl(app, onRole = { roles.add(it) }).setRole("core")
        assertEquals(listOf("core"), roles)
    }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class HealthSnapshotTest {
    private val app: android.app.Application = ApplicationProvider.getApplicationContext()

    @Test
    fun `permissions are read as granted or not`() {
        var h = HostApiImpl(app).healthSnapshot()
        assertEquals(false, h.locationPermission)
        assertEquals(false, h.smsPermission)
        shadowOf(app).grantPermissions(
            android.Manifest.permission.ACCESS_FINE_LOCATION,
            android.Manifest.permission.ACCESS_BACKGROUND_LOCATION,
            android.Manifest.permission.SEND_SMS,
            android.Manifest.permission.POST_NOTIFICATIONS,
        )
        h = HostApiImpl(app).healthSnapshot()
        assertEquals(true, h.locationPermission)
        assertEquals(true, h.backgroundLocationPermission)
        assertEquals(true, h.smsPermission)
        assertEquals(true, h.notificationPermission)
    }

    @Test
    fun `battery optimisation exemption is read from the power manager`() {
        val pm = app.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        assertEquals(false, HostApiImpl(app).healthSnapshot().batteryOptimizationExempt)
        shadowOf(pm).setIgnoringBatteryOptimizations(app.packageName, true)
        assertEquals(true, HostApiImpl(app).healthSnapshot().batteryOptimizationExempt)
    }

    @Test
    fun `free storage is a plausible number of megabytes`() {
        val mb = HostApiImpl(app).healthSnapshot().storageFreeMb
        assertTrue(mb >= 0)
    }
}
