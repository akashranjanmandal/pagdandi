package app.pagdandi.pagdandi_native

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ExactAlarmsTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private val manager get() = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    @Test
    fun an_exact_alarm_is_scheduled_that_also_fires_in_doze() {
        org.robolectric.shadows.ShadowAlarmManager.setCanScheduleExactAlarms(true)
        ExactAlarms(context).schedule(7, 1_000_000L)
        val a = shadowOf(manager).nextScheduledAlarm!!
        assertEquals(1_000_000L, a.triggerAtMs)
        assertEquals(AlarmManager.RTC_WAKEUP, a.type)
        assertTrue(a.isAllowWhileIdle)
    }

    @Test
    fun without_the_exact_alarm_permission_it_still_fires_in_doze_just_less_exactly() {
        org.robolectric.shadows.ShadowAlarmManager.setCanScheduleExactAlarms(false)
        ExactAlarms(context).schedule(7, 1_000_000L)
        val a = shadowOf(manager).nextScheduledAlarm
        assertNotNull("an alarm must never be silently dropped", a)
        assertTrue(a!!.isAllowWhileIdle)
    }

    @Test
    fun scheduling_the_same_id_again_replaces_it() {
        org.robolectric.shadows.ShadowAlarmManager.setCanScheduleExactAlarms(true)
        val alarms = ExactAlarms(context)
        alarms.schedule(7, 1_000_000L)
        alarms.schedule(7, 2_000_000L)
        assertEquals(1, shadowOf(manager).scheduledAlarms.size)
        assertEquals(2_000_000L, shadowOf(manager).nextScheduledAlarm!!.triggerAtMs)
    }

    @Test
    fun different_ids_are_different_alarms() {
        org.robolectric.shadows.ShadowAlarmManager.setCanScheduleExactAlarms(true)
        val alarms = ExactAlarms(context)
        alarms.schedule(1, 1_000_000L)
        alarms.schedule(2, 2_000_000L)
        assertEquals(2, shadowOf(manager).scheduledAlarms.size)
    }

    @Test
    fun cancel_removes_only_that_alarm() {
        org.robolectric.shadows.ShadowAlarmManager.setCanScheduleExactAlarms(true)
        val alarms = ExactAlarms(context)
        alarms.schedule(1, 1_000_000L)
        alarms.schedule(2, 2_000_000L)
        alarms.cancel(1)
        assertEquals(1, shadowOf(manager).scheduledAlarms.size)
        assertEquals(2_000_000L, shadowOf(manager).nextScheduledAlarm!!.triggerAtMs)
    }

    @Test
    fun an_alarm_in_the_past_fires_at_once() {
        org.robolectric.shadows.ShadowAlarmManager.setCanScheduleExactAlarms(true)
        ExactAlarms(context).schedule(3, 1L)
        assertNotNull(shadowOf(manager).nextScheduledAlarm)
    }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class FiredAlarmStoreTest {
    private val context: Context = ApplicationProvider.getApplicationContext()

    @Before
    fun clean() {
        FiredAlarmStore(context).take()
    }

    @Test
    fun each_fired_alarm_is_taken_once() {
        val s = FiredAlarmStore(context)
        s.add(4)
        s.add(9)
        assertEquals(listOf(4, 9), s.take().sorted())
        assertEquals(emptyList<Int>(), s.take())
    }

    @Test
    fun the_same_alarm_firing_twice_is_one_event() {
        val s = FiredAlarmStore(context)
        s.add(4)
        s.add(4)
        assertEquals(listOf(4), s.take())
    }

    @Test
    fun survives_a_new_store_object_like_a_new_process() {
        FiredAlarmStore(context).add(5)
        assertEquals(listOf(5), FiredAlarmStore(context).take())
    }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class AlarmDispatcherTest {
    private val context: Context = ApplicationProvider.getApplicationContext()

    @Before
    fun clean() {
        FiredAlarmStore(context).take()
        AlarmBus.coreSink = null
    }

    @After
    fun after() {
        AlarmBus.coreSink = null
    }

    @Test
    fun a_running_core_gets_the_alarm_straight_away() {
        val got = mutableListOf<Int>()
        AlarmBus.coreSink = { got.add(it) }
        AlarmDispatcher.dispatch(context, 7)
        assertEquals(listOf(7), got)
        assertEquals("delivered, so not kept", emptyList<Int>(), FiredAlarmStore(context).take())
    }

    @Test
    fun without_a_core_the_alarm_is_kept_and_the_trek_service_is_started() {
        HeartbeatStore(context).trekActive = true
        AlarmDispatcher.dispatch(context, 7)
        assertEquals(listOf(7), FiredAlarmStore(context).take())
        val svc = shadowOf(context as android.app.Application).nextStartedService
        assertNotNull(svc)
        assertEquals(TrekForegroundService::class.java.name, svc.component!!.className)
    }

    @Test
    fun without_a_core_and_without_a_trek_the_alarm_is_kept_but_nothing_starts() {
        HeartbeatStore(context).trekActive = false
        AlarmDispatcher.dispatch(context, 7)
        assertEquals(listOf(7), FiredAlarmStore(context).take())
        assertNull(shadowOf(context as android.app.Application).nextStartedService)
    }

    @Test
    fun a_failing_core_sink_keeps_the_alarm_for_the_next_core() {
        AlarmBus.coreSink = { throw IllegalStateException("engine gone") }
        AlarmDispatcher.dispatch(context, 7)
        assertEquals(listOf(7), FiredAlarmStore(context).take())
    }

    @Test
    fun the_receiver_ignores_an_intent_without_an_id() {
        AlarmReceiver().onReceive(context, Intent(ExactAlarms.ACTION))
        assertEquals(emptyList<Int>(), FiredAlarmStore(context).take())
    }

    @Test
    fun the_receiver_passes_the_id_on() {
        HeartbeatStore(context).trekActive = false
        AlarmReceiver().onReceive(context, Intent(ExactAlarms.ACTION).putExtra(ExactAlarms.EXTRA_ID, 11))
        assertEquals(listOf(11), FiredAlarmStore(context).take())
    }
}
