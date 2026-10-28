package app.pagdandi.pagdandi_native

import android.database.sqlite.SQLiteDatabase
import java.io.File

/**
 * The only way native code opens the shared database. The Dart core keeps it
 * in WAL mode; a plain [SQLiteDatabase.openDatabase] would switch the file
 * back to a rollback journal underneath the Dart connections and corrupt
 * their view of it. This opens it in WAL mode and waits for a busy database
 * instead of failing at once. The file must already exist.
 */
object GuardDatabase {
    fun open(file: File): SQLiteDatabase {
        val db = SQLiteDatabase.openDatabase(
            file.path,
            null,
            SQLiteDatabase.OPEN_READWRITE or SQLiteDatabase.ENABLE_WRITE_AHEAD_LOGGING,
        )
        try {
            db.rawQuery("PRAGMA busy_timeout = 5000", null).use { it.moveToFirst() }
        } catch (e: Exception) {
            // The default wait still applies.
        }
        return db
    }
}
