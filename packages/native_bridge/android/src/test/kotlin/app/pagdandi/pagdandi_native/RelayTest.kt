package app.pagdandi.pagdandi_native

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class RelayTest {
    @Test
    fun `commands go straight to the core once it is registered`() {
        val r = Relay()
        val got = mutableListOf<String>()
        r.registerCore { got.add(it) }
        r.command("a")
        r.command("b")
        assertEquals(listOf("a", "b"), got)
    }

    @Test
    fun `commands sent before the core is up are queued and delivered in order`() {
        val r = Relay()
        r.command("a")
        r.command("b")
        val got = mutableListOf<String>()
        r.registerCore { got.add(it) }
        assertEquals(listOf("a", "b"), got)
        r.command("c")
        assertEquals(listOf("a", "b", "c"), got)
    }

    @Test
    fun `the queue is bounded so a core that never starts cannot eat memory`() {
        val r = Relay(maxQueued = 3)
        for (i in 1..10) r.command("c$i")
        val got = mutableListOf<String>()
        r.registerCore { got.add(it) }
        assertEquals(listOf("c8", "c9", "c10"), got)
    }

    @Test
    fun `a core that goes away queues commands again`() {
        val r = Relay()
        val got = mutableListOf<String>()
        r.registerCore { got.add(it) }
        r.unregisterCore()
        r.command("x")
        assertTrue(got.isEmpty())
        r.registerCore { got.add(it) }
        assertEquals(listOf("x"), got)
    }

    @Test
    fun `state goes to the UI and a UI that appears later gets the latest state at once`() {
        val r = Relay()
        r.state("s1")
        r.state("s2")
        val got = mutableListOf<String>()
        r.registerUi { got.add(it) }
        assertEquals(listOf("s2"), got)
        r.state("s3")
        assertEquals(listOf("s2", "s3"), got)
    }

    @Test
    fun `a UI that went away just stops receiving`() {
        val r = Relay()
        val got = mutableListOf<String>()
        r.registerUi { got.add(it) }
        r.unregisterUi()
        r.state("s")
        assertTrue(got.isEmpty())
    }

    @Test
    fun `a command a failing core could not take is kept for the next core`() {
        val r = Relay()
        r.registerCore { throw IllegalStateException("engine gone") }
        r.command("a")
        val got = mutableListOf<String>()
        r.registerCore { got.add(it) }
        r.command("b")
        assertEquals(listOf("a", "b"), got)
    }
}
