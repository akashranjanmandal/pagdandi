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
