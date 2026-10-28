package app.pagdandi.pagdandi_native

import android.location.Location
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

class FakeBackend : LocationBackend {
    var started: LocationParams? = null
    var stops = 0
    var deliver: ((List<Location>) -> Unit)? = null
    var error: Exception? = null

    override fun start(params: LocationParams, onLocations: (List<Location>) -> Unit) {
        error?.let { throw it }
        started = params
        deliver = onLocations
    }

    override fun stop() {
        stops++
        deliver = null
    }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class LocationControllerTest {
    private val batches = mutableListOf<List<LocationFixDto>>()
    private val backend = FakeBackend()
    private val controller = LocationController(backend) { batches.add(it) }

    private fun loc(lat: Double, t: Long) = Location("gps").apply {
        latitude = lat; longitude = 88.0; accuracy = 5f; time = t
    }

    @Test
    fun `start maps the request and passes it to the backend`() {
        controller.start(LocationRequestDto(5000, 0, 8.0))
        assertEquals(LocationParams(5000, 0, 8.0), backend.started)
    }

    @Test
    fun `locations from the backend are reported as one batch of dtos`() {
        controller.start(LocationRequestDto(5000, 60000, 0.0))
        backend.deliver!!(listOf(loc(1.0, 10), loc(2.0, 20)))
        assertEquals(1, batches.size)
        assertEquals(listOf(1.0, 2.0), batches[0].map { it.latitude })
    }

    @Test
    fun `an empty batch is not reported`() {
        controller.start(LocationRequestDto(5000, 0, 0.0))
        backend.deliver!!(emptyList())
        assertTrue(batches.isEmpty())
    }

    @Test
    fun `starting again stops the previous request first`() {
        controller.start(LocationRequestDto(5000, 0, 0.0))
        controller.start(LocationRequestDto(1000, 0, 0.0))
        assertEquals(1, backend.stops)
        assertEquals(1000L, backend.started!!.intervalMs)
    }

    @Test
    fun `stop stops the backend and no more locations are reported`() {
        controller.start(LocationRequestDto(5000, 0, 0.0))
        val deliver = backend.deliver!!
        controller.stop()
        assertEquals(1, backend.stops)
        deliver(listOf(loc(1.0, 10)))
        assertTrue("a stopped controller must not report", batches.isEmpty())
    }

    @Test
    fun `stop without start is harmless`() {
        controller.stop()
        assertEquals(0, batches.size)
    }

    @Test(expected = SecurityException::class)
    fun `a missing permission is not swallowed so Dart learns about it`() {
        backend.error = SecurityException("no location permission")
        controller.start(LocationRequestDto(5000, 0, 0.0))
    }
}
