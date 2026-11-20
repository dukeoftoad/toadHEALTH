package com.toadhealth.wear

import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

/**
 * Wear-side background listener: receives /toad/state pushes from the
 * phone while the wrist app is closed and stores them via
 * [ToadStateStore], so the next cold start of [WearActivity] shows the
 * mirrored pond immediately. It creates no notifications or vibrations.
 * Health snapshots flow phone-to-watch; the wrist sends only explicit
 * quick-log/ping commands back to the phone through the Wear Data Layer.
 * Play Services may relay those commands using its documented encrypted
 * cloud fallback.
 */
class ToadListenerService : WearableListenerService() {

    override fun onMessageReceived(event: MessageEvent) {
        if (event.path == "/toad/state") {
            val json = String(event.data, Charsets.UTF_8)
            ToadStateStore.save(this, json)
        }
    }

    /** A durable timestamp-only clear marker is synced even if this watch was offline. */
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type == DataEvent.TYPE_CHANGED &&
                event.dataItem.uri.path == "/toad/clear"
            ) {
                val clearedAt = DataMapItem.fromDataItem(event.dataItem)
                    .dataMap.getLong("clearedAt")
                ToadStateStore.clear(this, clearedAt)
            }
        }
    }

}
