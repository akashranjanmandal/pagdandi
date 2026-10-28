package app.pagdandi.pagdandi_native

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager

/** The accelerometer hardware. [register] returns false when there is none. */
interface AccelBackend {
    fun register(periodUs: Int, onSample: (x: Float, y: Float, z: Float, tMs: Long) -> Unit): Boolean

    fun unregister()
}

class SensorAccelBackend(private val context: Context) : AccelBackend {
    private var listener: SensorEventListener? = null

    override fun register(periodUs: Int, onSample: (Float, Float, Float, Long) -> Unit): Boolean {
        val sm = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager ?: return false
        val sensor = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) ?: return false
        val l = object : SensorEventListener {
            override fun onSensorChanged(e: SensorEvent) {
                // Event time is monotonic nanoseconds since boot.
                onSample(e.values[0], e.values[1], e.values[2], e.timestamp / 1_000_000L)
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }
        listener = l
        // The sensor hub may batch for up to 200 ms: fewer wake-ups, same data.
        return sm.registerListener(l, sensor, periodUs, 200_000)
    }

    override fun unregister() {
        val sm = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        listener?.let { sm?.unregisterListener(it) }
        listener = null
    }
}

/**
 * Collects accelerometer samples and hands them to Dart in batches of about
 * 200 ms, as flat [x, y, z, timeMs] groups. Never throws.
 */
class AccelerometerController(
    private val backend: AccelBackend,
    private val emit: (List<Double>) -> Unit,
) {
    private var running = false
    private val batch = ArrayList<Double>()
    private var perBatch = 5

    @Synchronized
    fun start(periodMs: Int): Boolean {
        if (running) return true
        return try {
            perBatch = (200 / periodMs.coerceAtLeast(1)).coerceAtLeast(1)
            val ok = backend.register(periodMs * 1000) { x, y, z, t -> add(x, y, z, t) }
            running = ok
            ok
        } catch (e: Exception) {
            running = false
            false
        }
    }

    @Synchronized
    fun stop() {
        if (!running) return
        running = false
        try {
            backend.unregister()
        } catch (e: Exception) {
            // Nothing more can be done.
        }
        flush()
    }

    @Synchronized
    private fun add(x: Float, y: Float, z: Float, tMs: Long) {
        batch.add(x.toDouble())
        batch.add(y.toDouble())
        batch.add(z.toDouble())
        batch.add(tMs.toDouble())
        if (batch.size >= perBatch * 4) flush()
    }

    private fun flush() {
        if (batch.isEmpty()) return
        val out = ArrayList(batch)
        batch.clear()
        try {
            emit(out)
        } catch (e: Exception) {
            // A gone Dart engine must not crash the sensor thread.
        }
    }
}

/** One accelerometer for the whole process, shared by every Flutter engine. */
object AccelHolder {
    @Volatile var controller: AccelerometerController? = null
}
