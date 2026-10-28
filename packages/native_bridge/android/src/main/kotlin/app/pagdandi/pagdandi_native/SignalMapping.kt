package app.pagdandi.pagdandi_native

import android.telephony.ServiceState

/** Maps Android's service state to ours; anything unexpected counts as no service. */
fun signalStateOf(serviceState: Int): SignalStateDto =
    when (serviceState) {
        ServiceState.STATE_IN_SERVICE -> SignalStateDto.IN_SERVICE
        ServiceState.STATE_EMERGENCY_ONLY -> SignalStateDto.EMERGENCY_ONLY
        else -> SignalStateDto.NO_SERVICE
    }
