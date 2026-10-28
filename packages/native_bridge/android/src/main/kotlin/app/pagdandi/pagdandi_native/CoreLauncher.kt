package app.pagdandi.pagdandi_native

import android.content.Context
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

/** Starts and stops the headless Dart "trek core". */
interface CoreLauncher {
    fun start()

    fun stop()

    fun restart() {
        stop()
        start()
    }
}

/**
 * Runs the Dart `trekCoreMain` entrypoint in its own headless FlutterEngine,
 * so the trek keeps running when the UI is closed. Never throws: a failing
 * engine is the guard's job to notice and restart.
 */
class HeadlessCoreLauncher(private val context: Context) : CoreLauncher {
    private var engine: FlutterEngine? = null

    override fun start() {
        if (engine != null) return
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(context.applicationContext)
            loader.ensureInitializationComplete(context.applicationContext, null)
            val e = FlutterEngine(context.applicationContext)
            e.dartExecutor.executeDartEntrypoint(
                // The library must be named: a bare function name is only
                // resolved in the main script, where trekCoreMain is not.
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), LIBRARY, ENTRYPOINT),
            )
            engine = e
        } catch (t: Throwable) {
            engine = null
        }
    }

    override fun stop() {
        engine?.destroy()
        engine = null
    }

    companion object {
        const val LIBRARY = "package:pagdandi_app/core/trek_core_main.dart"
        const val ENTRYPOINT = "trekCoreMain"
    }
}
