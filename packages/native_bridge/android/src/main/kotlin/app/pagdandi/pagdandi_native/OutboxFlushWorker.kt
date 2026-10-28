package app.pagdandi.pagdandi_native

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters

/**
 * Backstop that sends the pending SOS SMS even when the app process is dead
 * (after a reboot, or if the service was killed): the same guard pass the
 * service runs, minus anything that needs a running service.
 */
class OutboxFlushWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val file = GuardPaths.databaseFile(applicationContext)
        if (!file.exists()) return Result.success()
        var db: SQLiteDatabase? = null
        return try {
            db = GuardDatabase.open(file)
            val outbox = GuardOutbox(db)
            val actions = object : GuardActions {
                private val sms = SmsSender(applicationContext, defaultSmsManager(applicationContext)) { id, status ->
                    outbox.markGuard(id, status.name.lowercase(), System.currentTimeMillis())
                }

                override fun sendSms(m: GuardMessage) = sms.send(m.id, m.to, m.body)

                override fun showWarning(show: Boolean) {}

                override fun keepAlarms(on: Boolean) {}

                override fun restartCore() {}
            }
            GuardRunner(outbox, HeartbeatStore(applicationContext), actions, System::currentTimeMillis).runOnce()
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        } finally {
            db?.close()
        }
    }

    companion object {
        private const val NAME = "pagdandi_outbox_flush"

        fun enqueue(context: Context) {
            try {
                WorkManager.getInstance(context).enqueueUniqueWork(
                    NAME,
                    ExistingWorkPolicy.REPLACE,
                    OneTimeWorkRequestBuilder<OutboxFlushWorker>().build(),
                )
            } catch (e: IllegalStateException) {
                // WorkManager not initialised in this process: the service guard still covers the outbox.
            }
        }
    }
}
