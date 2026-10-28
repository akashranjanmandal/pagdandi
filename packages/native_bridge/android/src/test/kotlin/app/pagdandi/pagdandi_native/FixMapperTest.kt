package app.pagdandi.pagdandi_native

import android.location.Location
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class FixMapperTest {
    private fun loc(block: Location.() -> Unit): Location =
        Location("gps").apply {
            latitude = 27.041
            longitude = 88.2663
            accuracy = 6f
            time = 1_761_573_600_000L
            block()
        }

    @Test
    fun `position, accuracy and GPS time are carried over`() {
        val f = toFixDto(loc {})
        assertEquals(27.041, f.latitude, 1e-9)
        assertEquals(88.2663, f.longitude, 1e-9)
        assertEquals(6.0, f.accuracyM, 1e-6)
        assertEquals(1_761_573_600_000L, f.timeMs)
    }

    @Test
    fun `optional values are null when the phone did not measure them`() {
        val f = toFixDto(loc {})
        assertNull(f.altitudeM)
        assertNull(f.speedMps)
        assertNull(f.bearingDeg)
    }

    @Test
    fun `altitude, speed and bearing are carried over when present`() {
        val f = toFixDto(loc { altitude = 3102.0; speed = 1.5f; bearing = 90f })
        assertEquals(3102.0, f.altitudeM!!, 1e-9)
        assertEquals(1.5, f.speedMps!!, 1e-6)
        assertEquals(90.0, f.bearingDeg!!, 1e-6)
    }

    @Test
    fun `a location without an accuracy is reported as very inaccurate, not perfect`() {
        val l = Location("gps").apply { latitude = 1.0; longitude = 2.0; time = 5L }
        assertEquals(Double.MAX_VALUE, toFixDto(l).accuracyM, 0.0)
    }
}
