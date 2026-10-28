package app.pagdandi.pagdandi_native

import android.telephony.ServiceState
import org.junit.Assert.assertEquals
import org.junit.Test

class SignalMappingTest {
    @Test
    fun `in service maps to in service`() {
        assertEquals(SignalStateDto.IN_SERVICE, signalStateOf(ServiceState.STATE_IN_SERVICE))
    }

    @Test
    fun `emergency only maps to emergency only`() {
        assertEquals(SignalStateDto.EMERGENCY_ONLY, signalStateOf(ServiceState.STATE_EMERGENCY_ONLY))
    }

    @Test
    fun `out of service and power off map to no service`() {
        assertEquals(SignalStateDto.NO_SERVICE, signalStateOf(ServiceState.STATE_OUT_OF_SERVICE))
        assertEquals(SignalStateDto.NO_SERVICE, signalStateOf(ServiceState.STATE_POWER_OFF))
    }

    @Test
    fun `an unknown value is treated as no service`() {
        assertEquals(SignalStateDto.NO_SERVICE, signalStateOf(99))
    }
}
