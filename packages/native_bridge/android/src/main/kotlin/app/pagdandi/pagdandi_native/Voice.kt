package app.pagdandi.pagdandi_native

import android.content.Context
import android.media.AudioAttributes
import android.speech.tts.TextToSpeech
import java.util.Locale

/** The speech engine. [init] reports once whether it is usable. */
interface TtsBackend {
    fun init(onReady: (Boolean) -> Unit)

    fun speak(text: String, urgent: Boolean)

    fun stop()
}

class AndroidTts(private val context: Context) : TtsBackend {
    private var tts: TextToSpeech? = null

    override fun init(onReady: (Boolean) -> Unit) {
        tts = TextToSpeech(context) { status ->
            val t = tts
            if (status != TextToSpeech.SUCCESS || t == null) {
                onReady(false)
                return@TextToSpeech
            }
            // English only (a project decision); Indian English first.
            val r = t.setLanguage(Locale("en", "IN"))
            val ok = if (r == TextToSpeech.LANG_MISSING_DATA || r == TextToSpeech.LANG_NOT_SUPPORTED) {
                val r2 = t.setLanguage(Locale.ENGLISH)
                r2 != TextToSpeech.LANG_MISSING_DATA && r2 != TextToSpeech.LANG_NOT_SUPPORTED
            } else {
                true
            }
            onReady(ok)
        }
    }

    override fun speak(text: String, urgent: Boolean) {
        val t = tts ?: throw IllegalStateException("speech engine not started")
        t.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(
                    if (urgent) AudioAttributes.USAGE_ALARM else AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE,
                )
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build(),
        )
        val mode = if (urgent) TextToSpeech.QUEUE_FLUSH else TextToSpeech.QUEUE_ADD
        if (t.speak(text, mode, null, "pagdandi-${System.nanoTime()}") != TextToSpeech.SUCCESS) {
            throw IllegalStateException("speech refused")
        }
    }

    override fun stop() {
        tts?.stop()
    }
}

/**
 * Speaks short alerts. Starts the engine on first use; lines said before it is
 * ready wait (only the newest few, and an urgent line drops the older ones);
 * a phone with no speech engine stays quiet and is never retried line by line.
 * Never throws.
 */
class VoiceController(private val backend: TtsBackend) {
    private enum class State { NEW, STARTING, READY, UNAVAILABLE }

    private var state = State.NEW
    private val waiting = ArrayList<Pair<String, Boolean>>()

    @Synchronized
    fun speak(text: String, urgent: Boolean): Boolean {
        val line = text.trim().take(MAX_CHARS)
        if (line.isEmpty()) return false
        when (state) {
            State.UNAVAILABLE -> return false
            State.READY -> return say(line, urgent)
            State.NEW -> {
                state = State.STARTING
                queue(line, urgent)
                try {
                    backend.init { ok -> onReady(ok) }
                } catch (e: Exception) {
                    state = State.UNAVAILABLE
                    waiting.clear()
                    return false
                }
            }
            State.STARTING -> queue(line, urgent)
        }
        return true
    }

    @Synchronized
    fun stop() {
        waiting.clear()
        try {
            backend.stop()
        } catch (e: Exception) {
            // Nothing more can be done.
        }
    }

    @Synchronized
    private fun onReady(ok: Boolean) {
        if (!ok) {
            state = State.UNAVAILABLE
            waiting.clear()
            return
        }
        state = State.READY
        val lines = ArrayList(waiting)
        waiting.clear()
        for ((t, u) in lines) say(t, u)
    }

    private fun queue(line: String, urgent: Boolean) {
        if (urgent) waiting.clear()
        waiting.add(line to urgent)
        while (waiting.size > MAX_WAITING) waiting.removeAt(0)
    }

    private fun say(line: String, urgent: Boolean): Boolean =
        try {
            backend.speak(line, urgent)
            true
        } catch (e: Exception) {
            false
        }

    private companion object {
        const val MAX_WAITING = 5
        const val MAX_CHARS = 400
    }
}

/** One voice for the whole process, shared by every Flutter engine. */
object VoiceHolder {
    @Volatile private var voice: VoiceController? = null

    fun voice(context: Context): VoiceController =
        voice ?: synchronized(this) {
            voice ?: VoiceController(AndroidTts(context.applicationContext)).also { voice = it }
        }
}
