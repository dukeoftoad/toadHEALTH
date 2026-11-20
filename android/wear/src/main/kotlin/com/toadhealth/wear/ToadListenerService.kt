package com.toadhealth.wear

import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

/**
 * Wear-side background listener: receives /toad/state pushes from the
 * phone while the wrist app is closed and stores them via
 * [ToadStateStore], so the next cold start of [WearActivity] shows the
 * mirrored pond immediately. No notification, no vibration, no data
 * leaves the watch - the toad quietly keeps the snapshot warm.
 */
class ToadListenerService : WearableListenerService() {

    override fun onMessageReceived(event: MessageEvent) {
        when (event.path) {
            "/toad/state" -> {
                val json = String(event.data, Charsets.UTF_8)
                ToadStateStore.save(this, json)
            }
            "/toad/clear" -> ToadStateStore.clear(this)
        }
    }

    companion object {
        const val WRIST_CAPABILITY = "toadhealth_wrist"
    }
}
