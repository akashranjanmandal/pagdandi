package app.pagdandi.pagdandi_native

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FakeTts : TtsBackend {
    var onReady: ((Boolean) -> Unit)? = null
    val spoken = mutableListOf<Pair<String, Boolean>>()
    var stops = 0
    var inits = 0
    var failSpeak = false

    override fun init(onReady: (Boolean) -> Unit) {
        inits++
        this.onReady = onReady
    }

    override fun speak(text: String, urgent: Boolean) {
        if (failSpeak) throw IllegalStateException("engine died")
        spoken.add(text to urgent)
    }

    override fun stop() {
        stops++
    }
}

class VoiceControllerTest {
    @Test
    fun the_engine_is_started_on_first_use_and_only_once() {
        val t = FakeTts()
        val v = VoiceController(t)
        v.speak("one", false)
        v.speak("two", false)
        assertEquals(1, t.inits)
    }

    @Test
    fun lines_said_before_the_engine_is_ready_are_spoken_when_it_is() {
        val t = FakeTts()
        val v = VoiceController(t)
        v.speak("Back on the trail.", false)
        assertTrue(t.spoken.isEmpty())
        t.onReady!!(true)
        assertEquals(listOf("Back on the trail." to false), t.spoken)
    }

    @Test
    fun once_ready_lines_are_spoken_at_once() {
        val t = FakeTts()
        val v = VoiceController(t)
        v.speak("first", false)
        t.onReady!!(true)
        v.speak("second", true)
        assertEquals(listOf("first" to false, "second" to true), t.spoken)
    }

    @Test
    fun an_urgent_line_drops_older_waiting_lines() {
        val t = FakeTts()
        val v = VoiceController(t)
        v.speak("old news", false)
        v.speak("Did you fall?", true)
        t.onReady!!(true)
        assertEquals(listOf("Did you fall?" to true), t.spoken)
    }

    @Test
    fun only_the_newest_few_waiting_lines_are_kept() {
        val t = FakeTts()
        val v = VoiceController(t)
        for (i in 1..9) v.speak("line $i", false)
        t.onReady!!(true)
        assertEquals(5, t.spoken.size)
        assertEquals("line 9", t.spoken.last().first)
    }

    @Test
    fun a_phone_with_no_speech_engine_just_stays_quiet() {
        val t = FakeTts()
        val v = VoiceController(t)
        v.speak("hello", false)
        t.onReady!!(false)
        assertTrue(t.spoken.isEmpty())
        assertFalse(v.speak("again", false))
        assertEquals("it does not retry on every line", 1, t.inits)
    }

    @Test
    fun blank_text_is_not_spoken() {
        val t = FakeTts()
        val v = VoiceController(t)
        t.let { v.speak("x", false); it.onReady!!(true) }
        assertFalse(v.speak("   ", false))
        assertEquals(1, t.spoken.size)
    }

    @Test
    fun a_failing_engine_is_reported_not_thrown() {
        val t = FakeTts()
        val v = VoiceController(t)
        v.speak("x", false)
        t.onReady!!(true)
        t.failSpeak = true
        assertFalse(v.speak("y", false))
    }

    @Test
    fun stop_silences_and_clears_what_was_waiting() {
        val t = FakeTts()
        val v = VoiceController(t)
        v.speak("waiting", false)
        v.stop()
        t.onReady!!(true)
        assertTrue(t.spoken.isEmpty())
        assertEquals(1, t.stops)
    }

    @Test
    fun the_text_is_cut_to_a_sane_length() {
        val t = FakeTts()
        val v = VoiceController(t)
        v.speak("a".repeat(5000), false)
        t.onReady!!(true)
        assertTrue(t.spoken.single().first.length <= 400)
    }
}
