package app.pagdandi.pagdandi_native

import android.annotation.SuppressLint
import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Looper
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

/** What the hardware is asked for, after sanity limits. */
data class LocationParams(val intervalMs: Long, val maxDelayMs: Long, val minDistanceM: Double) {
    companion object {
        private const val MIN_INTERVAL_MS = 1000L

        fun from(dto: LocationRequestDto): LocationParams {
            val interval = maxOf(dto.intervalMs, MIN_INTERVAL_MS)
            // The fused provider ignores a batching delay shorter than the interval.
            val delay = if (dto.maxBatchDelayMs <= 0) 0L else maxOf(dto.maxBatchDelayMs, interval)
            return LocationParams(interval, delay, maxOf(dto.minDistanceM, 0.0))
        }
    }
}

/**
 * An Android Location as a fix. A location without a measured accuracy is
 * reported as hopelessly inaccurate, never as perfect, so the Dart filter
 * rejects it.
 */
fun toFixDto(l: Location): LocationFixDto =
    LocationFixDto(
        latitude = l.latitude,
        longitude = l.longitude,
        accuracyM = if (l.hasAccuracy()) l.accuracy.toDouble() else Double.MAX_VALUE,
        timeMs = l.time,
        altitudeM = if (l.hasAltitude()) l.altitude else null,
        speedMps = if (l.hasSpeed()) l.speed.toDouble() else null,
        bearingDeg = if (l.hasBearing()) l.bearing.toDouble() else null,
    )

/** Fails loudly (and clearly) when location permission is missing, so Dart can warn. */
fun requireLocationPermission(context: Context) {
    if (context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
        throw SecurityException("ACCESS_FINE_LOCATION is not granted")
    }
}

/** A source of locations: the fused provider or plain GPS. */
interface LocationBackend {
    fun start(params: LocationParams, onLocations: (List<Location>) -> Unit)

    fun stop()
}

/** Owns the single active location request and reports fixes to Dart. */
class LocationController(
    private val backend: LocationBackend,
    private val report: (List<LocationFixDto>) -> Unit,
) {
    private var generation = 0
    private var active = false

    fun start(request: LocationRequestDto) {
        if (active) backend.stop()
        active = false
        val mine = ++generation
        backend.start(LocationParams.from(request)) { locations ->
            if (active && generation == mine && locations.isNotEmpty()) {
                report(locations.map(::toFixDto))
            }
        }
        active = true
    }

    fun stop() {
        if (!active) return
        active = false
        generation++
        backend.stop()
    }
}

/** Plain GPS for phones without Google Play services: no batching, fixes arrive live. */
class GpsOnlyBackend(private val context: Context) : LocationBackend {
    private val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private var listener: LocationListener? = null

    @SuppressLint("MissingPermission")
    override fun start(params: LocationParams, onLocations: (List<Location>) -> Unit) {
        requireLocationPermission(context)
        stop()
        val l = LocationListener { location -> onLocations(listOf(location)) }
        // Throws SecurityException without the permission: Dart must learn about it.
        manager.requestLocationUpdates(
            LocationManager.GPS_PROVIDER,
            params.intervalMs,
            params.minDistanceM.toFloat(),
            l,
            Looper.getMainLooper(),
        )
        listener = l
    }

    override fun stop() {
        listener?.let { manager.removeUpdates(it) }
        listener = null
    }
}

/** The fused location provider, with hardware batching. */
class FusedBackend(private val context: Context) : LocationBackend {
    private val client = LocationServices.getFusedLocationProviderClient(context)
    private var callback: LocationCallback? = null

    @SuppressLint("MissingPermission")
    override fun start(params: LocationParams, onLocations: (List<Location>) -> Unit) {
        requireLocationPermission(context)
        stop()
        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, params.intervalMs)
            .setMaxUpdateDelayMillis(params.maxDelayMs)
            .setMinUpdateDistanceMeters(params.minDistanceM.toFloat())
            .build()
        val cb = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) = onLocations(result.locations)
        }
        client.requestLocationUpdates(request, cb, Looper.getMainLooper())
        callback = cb
    }

    override fun stop() {
        callback?.let { client.removeLocationUpdates(it) }
        callback = null
    }
}

/** Fused when Google Play services are usable, plain GPS otherwise. */
fun createLocationBackend(context: Context): LocationBackend {
    val gms = try {
        GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context) == ConnectionResult.SUCCESS
    } catch (e: Exception) {
        false
    }
    return if (gms) FusedBackend(context) else GpsOnlyBackend(context)
}
