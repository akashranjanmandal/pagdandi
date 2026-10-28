package app.pagdandi.pagdandi_native

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FakeAccelBackend(var available: Boolean = true, var failing: Boolean = false) : AccelBackend {
    var listener: ((Float, Float, Float, Long) -> Unit)? = null
    var registered = 0
    var unregistered = 0
    var lastPeriodUs = 0

    override fun register(periodUs: Int, onSample: (Float, Float, Float, Long) -> Unit): Boolean {
        if (failing) throw IllegalStateException("sensor service dead")
        if (!available) return false
        registered++
        lastPeriodUs = periodUs
        listener = onSample
        return true
    }

    override fun unregister() {
        unregistered++
        listener = null
    }

    fun emit(x: Float, y: Float, z: Float, tMs: Long) = listener!!.invoke(x, y, z, tMs)
}

class AccelerometerControllerTest {
    private val batches = mutableListOf<List<Double>>()

    private fun controller(b: AccelBackend) = AccelerometerController(b) { batches.add(it) }

    @Test
    fun starts_the_sensor_and_reports_whether_there_is_one() {
        assertTrue(controller(FakeAccelBackend()).start(40))
        assertFalse(controller(FakeAccelBackend(available = false)).start(40))
    }

    @Test
    fun a_dead_sensor_service_is_reported_not_thrown() {
        assertFalse(controller(FakeAccelBackend(failing = true)).start(40))
    }

    @Test
    fun samples_are_sent_in_batches_of_flat_xyz_time() {
        val b = FakeAccelBackend()
        val c = controller(b)
        c.start(40)
        // 200 ms batches at a 40 ms period is 5 samples.
        for (i in 0 until 5) b.emit(0f, 0f, 9.8f + i, 1000L + i * 40)
        assertEquals(1, batches.size)
        assertEquals(20, batches[0].size)
        assertEquals(listOf(0.0, 0.0, 9.800000190734863, 1000.0), batches[0].take(4))
        assertEquals(1160.0, batches[0][19], 0.0)
    }

    @Test
    fun a_partial_batch_waits_and_stop_flushes_it() {
        val b = FakeAccelBackend()
        val c = controller(b)
        c.start(40)
        b.emit(1f, 2f, 3f, 5L)
        assertEquals(0, batches.size)
        c.stop()
        assertEquals(1, batches.size)
        assertEquals(listOf(1.0, 2.0, 3.0, 5.0), batches[0])
    }

    @Test
    fun starting_twice_registers_once() {
        val b = FakeAccelBackend()
        val c = controller(b)
        c.start(40)
        c.start(40)
        assertEquals(1, b.registered)
    }

    @Test
    fun stop_unregisters_and_is_safe_when_never_started() {
        val b = FakeAccelBackend()
        val c = controller(b)
        c.stop()
        assertEquals(0, b.unregistered)
        c.start(40)
        c.stop()
        assertEquals(1, b.unregistered)
    }

    @Test
    fun the_sensor_period_is_in_microseconds() {
        val b = FakeAccelBackend()
        controller(b).start(40)
        assertEquals(40_000, b.lastPeriodUs)
    }

    @Test
    fun a_failing_receiver_does_not_crash_the_sensor_thread() {
        val b = FakeAccelBackend()
        val c = AccelerometerController(b) { throw IllegalStateException("dart gone") }
        c.start(40)
        for (i in 0 until 5) b.emit(0f, 0f, 9.8f, i * 40L)
    }
}
