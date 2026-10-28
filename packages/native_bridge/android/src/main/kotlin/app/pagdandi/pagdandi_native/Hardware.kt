package app.pagdandi.pagdandi_native

import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.net.Uri
import android.os.Handler
import android.os.Looper
import kotlin.math.PI
import kotlin.math.sin

/**
 * Opens the phone dialer with a number filled in. It never places the call:
 * the person presses the call key. Anything that is not a plain phone number
 * (digits with an optional leading +) is refused.
 */
class DialerLauncher(private val context: Context) {
    fun open(number: String): Boolean {
        if (!VALID.matches(number)) return false
        return try {
            context.startActivity(
                Intent(Intent.ACTION_DIAL, Uri.parse("tel:$number")).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            true
        } catch (e: Exception) {
            false
        }
    }

    private companion object {
        val VALID = Regex("^\\+?[0-9]{3,15}$")
    }
}

/** Something that can run a task later and be cancelled. */
interface Cancelable {
    fun cancel()
}

/** Posts work for later; the real one uses a main-thread Handler. */
interface Scheduler {
    fun postDelayed(delayMs: Long, task: Runnable): Cancelable
}

class HandlerScheduler(private val handler: Handler = Handler(Looper.getMainLooper())) : Scheduler {
    override fun postDelayed(delayMs: Long, task: Runnable): Cancelable {
        handler.postDelayed(task, delayMs)
        return object : Cancelable {
            override fun cancel() = handler.removeCallbacks(task)
        }
    }
}

/** The camera flash. [set] throws when the camera cannot be used. */
interface TorchHardware {
    fun set(on: Boolean)
}

class CameraTorch(private val context: Context) : TorchHardware {
    override fun set(on: Boolean) {
        val cm = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val id = cm.cameraIdList.firstOrNull {
            cm.getCameraCharacteristics(it).get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
        } ?: throw IllegalStateException("no flash")
        cm.setTorchMode(id, on)
    }
}

/** S O S in Morse as [on, off, on, off, ...] milliseconds, ending with a long pause. */
val SOS_TORCH_PATTERN: List<Long> = run {
    val dot = 200L
    val dash = 600L
    val gap = 200L
    val letterGap = 600L
    fun letter(on: Long) = listOf(on, gap, on, gap, on, letterGap)
    val s = letter(dot)
    val o = letter(dash)
    // The last gap of the word is a long rest before it repeats.
    (s + o + s).dropLast(1) + 1400L
}

/** Torch steady light and SOS strobe. Failures are returned, never thrown. */
class TorchController(private val hw: TorchHardware, private val scheduler: Scheduler) {
    private var pending: Cancelable? = null
    private var strobing = false
    private var index = 0
    private var lit = false

    val isStrobing get() = strobing

    fun steady(on: Boolean): Boolean {
        stopStrobe()
        return write(on)
    }

    fun strobe(on: Boolean): Boolean {
        if (!on) {
            stopStrobe()
            return write(false)
        }
        if (strobing) return true
        strobing = true
        index = 0
        if (!write(true)) {
            strobing = false
            return false
        }
        scheduleNext()
        return true
    }

    private fun stopStrobe() {
        strobing = false
        pending?.cancel()
        pending = null
    }

    private fun scheduleNext() {
        pending = scheduler.postDelayed(SOS_TORCH_PATTERN[index]) {
            index = (index + 1) % SOS_TORCH_PATTERN.size
            if (!strobing) return@postDelayed
            if (!write(!lit)) {
                strobing = false
                return@postDelayed
            }
            scheduleNext()
        }
    }

    private fun write(on: Boolean): Boolean =
        try {
            hw.set(on)
            lit = on
            true
        } catch (e: Exception) {
            false
        }
}

/** The loudspeaker side of the siren. [start] throws when audio is unavailable. */
interface SirenAudio {
    fun start()

    fun stop()
}

/** Siren on or off. Repeating a request does nothing; failures are returned. */
class SirenController(private val audio: SirenAudio) {
    var isOn = false
        private set

    fun set(on: Boolean): Boolean {
        if (on == isOn) return true
        return try {
            if (on) audio.start() else audio.stop()
            isOn = on
            true
        } catch (e: Exception) {
            if (on) {
                // A half-started siren must not stay half on.
                try { audio.stop() } catch (_: Exception) {}
            }
            false
        }
    }
}

/**
 * One loop of a rising and falling wail (low to high and back) as 16-bit
 * samples. It starts and ends at zero so the loop point does not click.
 */
fun wailSamples(sampleRate: Int = 22050, seconds: Double = 2.0, lowHz: Double = 600.0, highHz: Double = 1400.0): ShortArray {
    val n = (sampleRate * seconds).toInt()
    val out = ShortArray(n)
    var phase = 0.0
    for (i in 0 until n) {
        val t = i.toDouble() / n
        // 0 -> 1 -> 0 over the loop.
        val sweep = (1 - kotlin.math.cos(2 * PI * t)) / 2
        val f = lowHz + (highHz - lowHz) * sweep
        phase += 2 * PI * f / sampleRate
        out[i] = (sin(phase) * 30000).toInt().toShort()
    }
    // Fade the first and last few milliseconds so the loop joins quietly.
    val fade = sampleRate / 100
    for (i in 0 until fade) {
        val k = i.toDouble() / fade
        out[i] = (out[i] * k).toInt().toShort()
        out[n - 1 - i] = (out[n - 1 - i] * k).toInt().toShort()
    }
    return out
}

/** Plays [wailSamples] on the alarm stream at full volume, so silent mode does not mute it. */
class AudioTrackSiren(private val context: Context) : SirenAudio {
    private var track: AudioTrack? = null
    private var savedVolume: Int? = null

    override fun start() {
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        savedVolume = audio.getStreamVolume(AudioManager.STREAM_ALARM)
        audio.setStreamVolume(AudioManager.STREAM_ALARM, audio.getStreamMaxVolume(AudioManager.STREAM_ALARM), 0)
        val samples = wailSamples()
        val t = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(22050)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build(),
            )
            .setTransferMode(AudioTrack.MODE_STATIC)
            .setBufferSizeInBytes(samples.size * 2)
            .build()
        t.write(samples, 0, samples.size)
        t.setLoopPoints(0, samples.size, -1)
        t.play()
        track = t
    }

    override fun stop() {
        try {
            track?.stop()
            track?.release()
        } finally {
            track = null
            val saved = savedVolume
            savedVolume = null
            if (saved != null) {
                val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                audio.setStreamVolume(AudioManager.STREAM_ALARM, saved, 0)
            }
        }
    }
}

/** One torch and one siren for the whole process, shared by every Flutter engine. */
object HardwareHolder {
    @Volatile private var torch: TorchController? = null

    @Volatile private var siren: SirenController? = null

    fun torch(context: Context): TorchController =
        torch ?: synchronized(this) {
            torch ?: TorchController(CameraTorch(context.applicationContext), HandlerScheduler()).also { torch = it }
        }

    fun siren(context: Context): SirenController =
        siren ?: synchronized(this) {
            siren ?: SirenController(AudioTrackSiren(context.applicationContext)).also { siren = it }
        }
}
