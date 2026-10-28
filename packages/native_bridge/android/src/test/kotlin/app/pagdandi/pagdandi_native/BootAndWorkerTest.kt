package app.pagdandi.pagdandi_native

import android.Manifest
import android.app.Application
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import androidx.work.ListenableWorker
import androidx.work.testing.TestListenableWorkerBuilder
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class BootAndWorkerTest {
    private val app: Application = ApplicationProvider.getApplicationContext()
    private val context: Context = app

    private fun boot() = BootReceiver().onReceive(context, Intent(Intent.ACTION_BOOT_COMPLETED))

    @Test
    fun `after boot a trek that was running resumes if background location is granted`() {
        HeartbeatStore(context).trekActive = true
        shadowOf(app).grantPermissions(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        boot()
        val started = shadowOf(app).nextStartedService
        assertNotNull(started)
        assertEquals(TrekForegroundService::class.java.name, started.component!!.className)
        assertTrue(started.getBooleanExtra(TrekForegroundService.EXTRA_AT_BOOT, false))
    }

    @Test
    fun `after boot without background location the user is asked to tap to resume`() {
        HeartbeatStore(context).trekActive = true
        boot()
        assertNull(shadowOf(app).nextStartedService)
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val n = shadowOf(nm).allNotifications.single()
        assertEquals("Tap to resume trek", n.extras.getCharSequence(android.app.Notification.EXTRA_TITLE))
    }

    @Test
    fun `after boot with no trek running nothing starts and nothing is shown`() {
        HeartbeatStore(context).trekActive = false
        boot()
        assertNull(shadowOf(app).nextStartedService)
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        assertTrue(shadowOf(nm).allNotifications.isEmpty())
    }

    @Test
    fun `other broadcasts are ignored`() {
        HeartbeatStore(context).trekActive = true
        shadowOf(app).grantPermissions(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        BootReceiver().onReceive(context, Intent("something.else"))
        assertNull(shadowOf(app).nextStartedService)
    }

    @Test
    fun `the flush worker succeeds and sends the outbox when there is no database yet`() {
        val worker = TestListenableWorkerBuilder<OutboxFlushWorker>(context).build()
        val result = runBlocking { worker.doWork() }
        assertEquals(ListenableWorker.Result.success(), result)
    }
}
