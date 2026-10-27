package app.pagdandi.pagdandi_native

/** `VibrationEffect.DEFAULT_AMPLITUDE`. */
const val DEFAULT_AMPLITUDE = -1

/** `VibrationEffect.createWaveform` repeat index meaning "play once". */
const val NO_REPEAT = -1

/** Silence added at the end of a repeating pattern so cycles do not run together. */
const val REPEAT_PAUSE_MS = 1000L

private const val FULL_AMPLITUDE = 255

/** A waveform ready for `VibrationEffect.createWaveform`. */
class WaveformSpec(
    val timings: LongArray,
    val amplitudes: IntArray,
    val repeatIndex: Int,
)

/**
 * Turns the Dart haptic vocabulary ([delay, on, off, on, ...] in ms) into a waveform.
 * Even slots are silent, odd slots vibrate. Repeating patterns loop from the start and
 * end with a pause.
 */
fun buildWaveform(timings: List<Long>, repeat: Boolean, strong: Boolean): WaveformSpec {
    require(timings.isNotEmpty()) { "waveform must not be empty" }
    require(timings.all { it >= 0 }) { "durations must not be negative" }
    val all = if (repeat) timings + REPEAT_PAUSE_MS else timings
    val on = if (strong) FULL_AMPLITUDE else DEFAULT_AMPLITUDE
    return WaveformSpec(
        timings = all.toLongArray(),
        amplitudes = IntArray(all.size) { i -> if (i % 2 == 1) on else 0 },
        repeatIndex = if (repeat) 0 else NO_REPEAT,
    )
}
