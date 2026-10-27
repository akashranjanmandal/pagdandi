package app.pagdandi.pagdandi_native

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test

class WaveformTest {
    @Test
    fun `one-shot pattern keeps its timings and does not repeat`() {
        val spec = buildWaveform(listOf(0L, 80L, 150L, 80L), repeat = false, strong = false)
        assertArrayEquals(longArrayOf(0, 80, 150, 80), spec.timings)
        assertEquals(NO_REPEAT, spec.repeatIndex)
    }

    @Test
    fun `off slots have zero amplitude and on slots use the default amplitude`() {
        val spec = buildWaveform(listOf(0L, 80L, 150L, 80L), repeat = false, strong = false)
        assertArrayEquals(intArrayOf(0, DEFAULT_AMPLITUDE, 0, DEFAULT_AMPLITUDE), spec.amplitudes)
    }

    @Test
    fun `strong patterns use full amplitude`() {
        val spec = buildWaveform(listOf(0L, 200L), repeat = false, strong = true)
        assertArrayEquals(intArrayOf(0, 255), spec.amplitudes)
    }

    @Test
    fun `repeating patterns loop from the start and end with a pause`() {
        val spec = buildWaveform(listOf(0L, 400L, 150L, 400L), repeat = true, strong = false)
        assertEquals(0, spec.repeatIndex)
        assertEquals(5, spec.timings.size)
        assertEquals(REPEAT_PAUSE_MS, spec.timings.last())
        assertEquals(0, spec.amplitudes.last())
        assertEquals(spec.timings.size, spec.amplitudes.size)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `an empty waveform is rejected`() {
        buildWaveform(emptyList(), repeat = false, strong = false)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `a negative duration is rejected`() {
        buildWaveform(listOf(0L, -5L), repeat = false, strong = false)
    }
}
