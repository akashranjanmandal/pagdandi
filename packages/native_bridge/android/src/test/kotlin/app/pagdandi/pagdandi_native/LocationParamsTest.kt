package app.pagdandi.pagdandi_native

import org.junit.Assert.assertEquals
import org.junit.Test

class LocationParamsTest {
    private fun dto(interval: Long, batch: Long, dist: Double = 0.0) =
        LocationRequestDto(intervalMs = interval, maxBatchDelayMs = batch, minDistanceM = dist)

    @Test
    fun `live request has no batching delay`() {
        val p = LocationParams.from(dto(5000, 0))
        assertEquals(5000L, p.intervalMs)
        assertEquals(0L, p.maxDelayMs)
    }

    @Test
    fun `batching delay is kept when it is at least the interval`() {
        assertEquals(120_000L, LocationParams.from(dto(30_000, 120_000)).maxDelayMs)
    }

    @Test
    fun `a batching delay shorter than the interval is raised to the interval`() {
        assertEquals(30_000L, LocationParams.from(dto(30_000, 10_000)).maxDelayMs)
    }

    @Test
    fun `a negative batching delay means live delivery`() {
        assertEquals(0L, LocationParams.from(dto(5000, -1)).maxDelayMs)
    }

    @Test
    fun `an interval under one second is raised to one second`() {
        assertEquals(1000L, LocationParams.from(dto(100, 0)).intervalMs)
        assertEquals(1000L, LocationParams.from(dto(-5, 0)).intervalMs)
    }

    @Test
    fun `minimum distance is never negative`() {
        assertEquals(0.0, LocationParams.from(dto(5000, 0, -3.0)).minDistanceM, 0.0)
        assertEquals(10.0, LocationParams.from(dto(5000, 0, 10.0)).minDistanceM, 0.0)
    }
}
