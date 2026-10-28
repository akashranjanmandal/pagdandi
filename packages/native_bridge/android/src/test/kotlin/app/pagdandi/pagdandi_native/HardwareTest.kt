package app.pagdandi.pagdandi_native

import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class DialerLauncherTest {
    private val context: Context = ApplicationProvider.getApplicationContext()

    private fun started(): Intent? = shadowOf(context as android.app.Application).nextStartedActivity

    @Test
    fun opens_the_dialer_with_the_number_filled_in_but_does_not_call() {
        assertTrue(DialerLauncher(context).open("+919876543210"))
        val i = started()!!
        assertEquals(Intent.ACTION_DIAL, i.action)
        assertEquals("tel:+919876543210", i.data.toString())
    }

    @Test
    fun the_emergency_number_works() {
        assertTrue(DialerLauncher(context).open("112"))
        assertEquals("tel:112", started()!!.data.toString())
    }

    @Test
    fun anything_that_is_not_a_phone_number_is_refused() {
        for (bad in listOf("", "abc", "112;rm", "tel:112", "+", "12 34", "*#06#", "1".repeat(20))) {
            assertFalse(bad, DialerLauncher(context).open(bad))
        }
        assertNull(started())
    }
}

class FakeScheduler : Scheduler {
    class Task(val delayMs: Long, val run: Runnable, var cancelled: Boolean = false) : Cancelable {
        override fun cancel() {
            cancelled = true
        }
    }

    val tasks = mutableListOf<Task>()

    override fun postDelayed(delayMs: Long, task: Runnable): Cancelable = Task(delayMs, task).also { tasks.add(it) }

    /** Runs the oldest pending task. */
    fun runNext() {
        val t = tasks.first { !it.cancelled }
        t.cancelled = true
        t.run.run()
    }

    val pending get() = tasks.count { !it.cancelled }
}

class FakeTorch(var failing: Boolean = false) : TorchHardware {
    val log = mutableListOf<Boolean>()
    override fun set(on: Boolean) {
        if (failing) throw IllegalStateException("camera in use")
        log.add(on)
    }
}

class TorchControllerTest {
    @Test
    fun steady_on_and_off() {
        val hw = FakeTorch()
        val c = TorchController(hw, FakeScheduler())
        assertTrue(c.steady(true))
        assertTrue(c.steady(false))
        assertEquals(listOf(true, false), hw.log)
    }

    @Test
    fun the_strobe_sends_sos_in_morse_then_repeats() {
        val hw = FakeTorch()
        val s = FakeScheduler()
        val c = TorchController(hw, s)
        assertTrue(c.strobe(true))
        // One whole cycle, then the start of the next: the delays are the pattern.
        val delays = mutableListOf<Long>()
        repeat(SOS_TORCH_PATTERN.size + 1) {
            delays.add(s.tasks.last { !it.cancelled }.delayMs)
            s.runNext()
        }
        assertEquals(SOS_TORCH_PATTERN + SOS_TORCH_PATTERN.first(), delays)
        assertEquals("on and off alternate", List(hw.log.size) { it % 2 == 0 }, hw.log)
        val ons = SOS_TORCH_PATTERN.filterIndexed { i, _ -> i % 2 == 0 }
        assertEquals(listOf(200L, 200L, 200L, 600L, 600L, 600L, 200L, 200L, 200L), ons)
        assertTrue("it keeps going", s.pending == 1)
        c.strobe(false)
        assertEquals("light is left off", false, hw.log.last())
        assertEquals("nothing left scheduled", 0, s.pending)
    }

    @Test
    fun a_steady_light_stops_the_strobe() {
        val hw = FakeTorch()
        val s = FakeScheduler()
        val c = TorchController(hw, s)
        c.strobe(true)
        c.steady(true)
        assertEquals(0, s.pending)
        assertEquals(true, hw.log.last())
    }

    @Test
    fun starting_the_strobe_twice_does_not_double_it() {
        val s = FakeScheduler()
        val c = TorchController(FakeTorch(), s)
        c.strobe(true)
        c.strobe(true)
        assertEquals(1, s.pending)
    }

    @Test
    fun a_camera_that_cannot_open_is_reported_not_thrown() {
        val c = TorchController(FakeTorch(failing = true), FakeScheduler())
        assertFalse(c.steady(true))
        assertFalse(c.strobe(true))
    }

    @Test
    fun the_pattern_alternates_on_and_off_and_ends_with_a_long_pause() {
        assertEquals(0, SOS_TORCH_PATTERN.size % 2)
        assertTrue(SOS_TORCH_PATTERN.all { it > 0 })
        assertTrue(SOS_TORCH_PATTERN.last() >= 1000)
    }
}

class FakeAudio(var failing: Boolean = false) : SirenAudio {
    var starts = 0
    var stops = 0
    override fun start() {
        if (failing) throw IllegalStateException("no audio")
        starts++
    }

    override fun stop() {
        stops++
    }
}

class SirenControllerTest {
    @Test
    fun on_then_off() {
        val a = FakeAudio()
        val c = SirenController(a)
        assertTrue(c.set(true))
        assertTrue(c.set(false))
        assertEquals(1, a.starts)
        assertEquals(1, a.stops)
    }

    @Test
    fun repeating_the_same_request_does_nothing() {
        val a = FakeAudio()
        val c = SirenController(a)
        c.set(true)
        c.set(true)
        c.set(false)
        c.set(false)
        assertEquals(1, a.starts)
        assertEquals(1, a.stops)
    }

    @Test
    fun a_failing_speaker_is_reported_and_leaves_the_siren_off() {
        val a = FakeAudio(failing = true)
        val c = SirenController(a)
        assertFalse(c.set(true))
        assertFalse(c.isOn)
    }

    @Test
    fun the_wail_sweeps_up_and_down_without_clipping_or_a_click_at_the_loop() {
        val rate = 8000
        val s = wailSamples(sampleRate = rate, seconds = 2.0)
        assertEquals(16000, s.size)
        assertTrue(s.all { it in -32767..32767 })
        assertTrue("it is loud", s.maxOf { it.toInt() } > 20000)
        // Looping from the last sample to the first must not jump.
        assertTrue(Math.abs(s.last().toInt() - s.first().toInt()) < 4000)
    }
}
