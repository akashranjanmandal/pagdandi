package app.pagdandi.pagdandi_native

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File

/**
 * The Dart core keeps the shared database in WAL mode. Android's plain
 * openDatabase switches a file back to a rollback journal, which breaks the
 * Dart connections ("database disk image is malformed"). Every native open
 * must go through [GuardDatabase].
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class GuardDatabaseTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private lateinit var file: File
    private lateinit var dart: SQLiteDatabase

    private fun mode(db: SQLiteDatabase): String =
        db.rawQuery("PRAGMA journal_mode", null).use { it.moveToFirst(); it.getString(0) }

    @Before
    fun setUp() {
        file = File(context.cacheDir, "guard-db-test.sqlite")
        file.delete()
        // Stands in for the Dart core's connection: WAL, and kept open.
        dart = SQLiteDatabase.openOrCreateDatabase(file, null)
        dart.enableWriteAheadLogging()
        dart.execSQL("CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)")
    }

    @After
    fun tearDown() {
        dart.close()
        file.delete()
    }

    @Test
    fun opens_the_file_in_wal_mode_and_keeps_it_that_way() {
        val db = GuardDatabase.open(file)
        assertTrue(db.isWriteAheadLoggingEnabled)
        assertEquals("wal", mode(db).lowercase())
        assertEquals("wal", mode(dart).lowercase())
        db.close()
        assertEquals("the other connection is undisturbed", "wal", mode(dart).lowercase())
    }

    @Test
    fun a_write_from_native_is_seen_by_the_other_connection() {
        val db = GuardDatabase.open(file)
        db.execSQL("INSERT INTO t (v) VALUES ('from the guard')")
        db.close()
        dart.rawQuery("SELECT v FROM t", null).use {
            assertTrue(it.moveToFirst())
            assertEquals("from the guard", it.getString(0))
        }
    }

    @Test
    fun waits_for_a_busy_database_instead_of_failing_at_once() {
        val db = GuardDatabase.open(file)
        val timeout = db.rawQuery("PRAGMA busy_timeout", null).use { it.moveToFirst(); it.getInt(0) }
        assertTrue("busy_timeout is $timeout ms", timeout >= 2000)
        db.close()
    }

    @Test
    fun a_missing_file_is_an_error_never_a_new_empty_database() {
        val missing = File(context.cacheDir, "no-such.sqlite")
        missing.delete()
        try {
            GuardDatabase.open(missing)
            throw AssertionError("should have failed")
        } catch (e: android.database.sqlite.SQLiteException) {
            // expected
        }
        assertTrue(!missing.exists())
    }
}
