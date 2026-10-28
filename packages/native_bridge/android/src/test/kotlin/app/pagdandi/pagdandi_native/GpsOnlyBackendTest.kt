package app.pagdandi.pagdandi_native

import android.Manifest
import android.app.Application
import android.content.Context
import android.location.Location
import android.location.LocationManager
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class GpsOnlyBackendTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private val got = mutableListOf<List<Location>>()

    @Before
    fun setUp() {
        shadowOf(context as Application).grantPermissions(Manifest.permission.ACCESS_FINE_LOCATION)
        shadowOf(manager).setProviderEnabled(LocationManager.GPS_PROVIDER, true)
    }

    private var clock = 1_000L

    private fun fix(lat: Double) = Location(LocationManager.GPS_PROVIDER).apply {
        latitude = lat; longitude = 88.0; accuracy = 5f
        clock += 5_000
        time = clock
        elapsedRealtimeNanos = clock * 1_000_000
    }

    @Test
    fun `fixes from the GPS provider are delivered immediately, one by one`() {
        val b = GpsOnlyBackend(context)
        b.start(LocationParams(1, 0, 0.0)) { got.add(it) }
        shadowOf(manager).simulateLocation(fix(27.0))
        shadowOf(manager).simulateLocation(fix(27.1))
        ShadowLooper.idleMainLooper()
        assertEquals(2, got.size)
        assertEquals(27.1, got.last().single().latitude, 1e-9)
    }

    @Test
    fun `after stop no more fixes are delivered`() {
        val b = GpsOnlyBackend(context)
        b.start(LocationParams(1, 0, 0.0)) { got.add(it) }
        b.stop()
        shadowOf(manager).simulateLocation(fix(27.0))
        ShadowLooper.idleMainLooper()
        assertTrue(got.isEmpty())
    }

    @Test
    fun `starting again replaces the earlier listener`() {
        val b = GpsOnlyBackend(context)
        b.start(LocationParams(1, 0, 0.0)) { got.add(it) }
        b.start(LocationParams(1, 0, 0.0)) { got.add(it) }
        shadowOf(manager).simulateLocation(fix(27.0))
        ShadowLooper.idleMainLooper()
        assertEquals("one fix, one delivery", 1, got.size)
    }

    @Test(expected = SecurityException::class)
    fun `without the location permission starting fails loudly`() {
        shadowOf(context as Application).denyPermissions(Manifest.permission.ACCESS_FINE_LOCATION)
        GpsOnlyBackend(context).start(LocationParams(1, 0, 0.0)) { }
    }

    @Test
    fun `stop without start is harmless`() {
        GpsOnlyBackend(context).stop()
    }
}
