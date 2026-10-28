package app.pagdandi.pagdandi_native

import android.Manifest
import android.app.Application
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class TrekServiceTest {
    private val app: Application = ApplicationProvider.getApplicationContext()
    private val context: Context = app

    private fun grant(vararg p: String) = shadowOf(app).grantPermissions(*p)

    @Test
    fun `service types always include location`() {
        val t = foregroundServiceTypes(context, atBoot = false)
        assertTrue(t and ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION != 0)
        assertEquals(0, t and ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        assertEquals(0, t and ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
    }

    @Test
    fun `microphone is added only with the microphone permission`() {
        grant(Manifest.permission.RECORD_AUDIO)
        assertTrue(foregroundServiceTypes(context, atBoot = false) and ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE != 0)
    }

    @Test
    fun `at boot the microphone type is never requested (Android 15 forbids it)`() {
        grant(Manifest.permission.RECORD_AUDIO)
        assertEquals(0, foregroundServiceTypes(context, atBoot = true) and ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
    }

    @Test
    fun `connected device is added only with a bluetooth permission`() {
        grant(Manifest.permission.BLUETOOTH_CONNECT)
        assertTrue(foregroundServiceTypes(context, atBoot = false) and ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE != 0)
    }

    @Test
    fun `starting the service goes foreground with a notification and marks the trek active`() {
        HeartbeatStore(context).clear()
        val s = Robolectric.buildService(TrekForegroundService::class.java, Intent(context, TrekForegroundService::class.java)).create().startCommand(0, 1).get()
        val shadow = shadowOf(s)
        assertNotNull(shadow.lastForegroundNotification)
        assertEquals(TrekForegroundService.NOTIFICATION_ID, shadow.lastForegroundNotificationId)
        assertTrue(HeartbeatStore(context).trekActive)
    }

    @Test
    fun `the notification channel exists and is low priority so it is quiet`() {
        Robolectric.buildService(TrekForegroundService::class.java, Intent(context, TrekForegroundService::class.java)).create().startCommand(0, 1)
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val ch = nm.getNotificationChannel(TrekForegroundService.CHANNEL_TREK)
        assertNotNull(ch)
        assertEquals(NotificationManager.IMPORTANCE_LOW, ch.importance)
    }

    @Test
    fun `the stop action ends the trek and the service`() {
        val intent = Intent(context, TrekForegroundService::class.java)
        val c = Robolectric.buildService(TrekForegroundService::class.java, intent).create().startCommand(0, 1)
        val stop = Intent(context, TrekForegroundService::class.java).setAction(TrekForegroundService.ACTION_STOP)
        val result = c.get().onStartCommand(stop, 0, 2)
        assertEquals(android.app.Service.START_NOT_STICKY, result)
        assertFalse(HeartbeatStore(context).trekActive)
        assertTrue(shadowOf(c.get()).isStoppedBySelf)
    }

    @Test
    fun `a restart by the system with no intent keeps the service running`() {
        val c = Robolectric.buildService(TrekForegroundService::class.java).create()
        val result = c.get().onStartCommand(null, 0, 1)
        assertEquals(android.app.Service.START_STICKY, result)
    }
}
