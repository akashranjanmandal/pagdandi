package app.pagdandi.pagdandi_native

import android.content.Context
import java.io.File

/** The one SQLite file shared by the Dart core and the native guard. */
object GuardPaths {
    fun databaseFile(context: Context): File = File(context.applicationContext.filesDir, "pagdandi.sqlite")
}
