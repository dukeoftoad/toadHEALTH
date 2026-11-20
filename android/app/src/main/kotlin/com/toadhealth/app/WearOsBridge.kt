package com.toadhealth.app

import android.app.Activity
import android.util.Log
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.CapabilityInfo
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.NodeClient
import com.google.android.gms.wearable.Wearable
import io.flutter.plugin.common.EventChannel

/**
 * Fourth job of the native bridge, alongside the vault ("toadhealth/vault"),
 * the step counter ("toadhealth/steps") and the BLE watch link
 * ("toadhealth/watch"):
 *
 *  4. "toadhealth/wear_os" + "toadhealth/wear_os_events"
 *     A bridge to the Wear OS companion app (the android/wear module) over
 *     the Wear Data Layer:
 *       - phone -> watch  /toad/state    JSON pond snapshots (mirror)
 *       - watch -> phone  /toad/command  quick logs and pings from the wrist
 *
 * Privacy note: the Data Layer uses encrypted Bluetooth when available.
 * If Bluetooth is unavailable, Google Play services can relay the payload
 * through Google-owned cloud servers; Google documents that fallback as
 * end-to-end encrypted. The app does not operate its own backend. When
 * Play Services are absent, the bridge reports isSupported=false.
 */
class WearOsBridge(private val activity: Activity) :
    MessageClient.OnMessageReceivedListener,
    CapabilityClient.OnCapabilityChangedListener {

    companion object {
        const val PATH_STATE = "/toad/state"
        const val PATH_COMMAND = "/toad/command"
        const val WRIST_CAPABILITY = "toadhealth_wrist"
        private const val TAG = "ToadWearOs"
    }

    private var sink: EventChannel.EventSink? = null
    private var started = false

    private val messageClient: MessageClient? get() = tryOrNull { Wearable.getMessageClient(activity) }
    private val nodeClient: NodeClient? get() = tryOrNull { Wearable.getNodeClient(activity) }
    private val capabilityClient: CapabilityClient? get() = tryOrNull { Wearable.getCapabilityClient(activity) }

    private inline fun <T> tryOrNull(block: () -> T): T? {
        return try {
            block()
        } catch (e: Throwable) {
            Log.w(TAG, "Data Layer unavailable: ${e.message}")
            null
        }
    }

    // ---------- event plumbing ----------

    fun setSink(newSink: EventChannel.EventSink?) {
        sink = newSink
    }

    private fun emit(payload: Map<String, Any?>) {
        val s = sink ?: return
        activity.runOnUiThread {
            try {
                s.success(payload)
            } catch (e: Exception) {
                Log.w(TAG, "emit failed", e)
            }
        }
    }

    // ---------- capabilities ----------

    /** True when Google Play Services carry the Data Layer on this phone. */
    fun isSupported(): Boolean {
        return try {
            GoogleApiAvailability.getInstance()
                .isGooglePlayServicesAvailable(activity) == ConnectionResult.SUCCESS
        } catch (e: Throwable) {
            false
        }
    }

    fun start() {
        if (started) return
        started = true
        tryOrNull { messageClient?.addListener(this) }
        tryOrNull { capabilityClient?.addListener(this, WRIST_CAPABILITY) }
        // Initial snapshot: connected nodes + wrists wearing the companion.
        pollNodes()
        pollWristCapability()
    }

    fun stop() {
        if (!started) return
        started = false
        tryOrNull { messageClient?.removeListener(this) }
        tryOrNull { capabilityClient?.removeListener(this) }
    }

    private fun pollNodes() {
        tryOrNull {
            nodeClient?.getConnectedNodes()?.addOnSuccessListener { nodes ->
                emit(mapOf("ev" to "nodes", "count" to nodes.size))
            }
        }
    }

    private fun pollWristCapability() {
        tryOrNull {
            capabilityClient
                ?.getCapability(WRIST_CAPABILITY, CapabilityClient.FILTER_ALL)
                ?.addOnSuccessListener { info ->
                    emit(mapOf("ev" to "wrist", "count" to info.nodes.size))
                }
        }
    }

    // ---------- phone -> wrist ----------

    /** Mirrors a pond snapshot JSON to every connected wrist node. */
    fun sendState(json: String): Boolean {
        if (!isSupported()) return false
        val bytes = json.toByteArray(Charsets.UTF_8)
        val client = messageClient ?: return false
        return try {
            nodeClient?.getConnectedNodes()?.addOnSuccessListener { nodes ->
                for (node in nodes) {
                    try {
                        client.sendMessage(node.id, PATH_STATE, bytes)
                    } catch (e: Exception) {
                        Log.w(TAG, "sendState to ${node.id} failed", e)
                    }
                }
            }
            true
        } catch (e: Throwable) {
            Log.w(TAG, "sendState failed", e)
            false
        }
    }

    // ---------- wrist -> phone ----------

    override fun onMessageReceived(event: MessageEvent) {
        if (event.path == PATH_COMMAND) {
            val json = String(event.data, Charsets.UTF_8)
            emit(mapOf("ev" to "command", "json" to json))
        }
    }

    override fun onCapabilityChanged(info: CapabilityInfo) {
        emit(mapOf("ev" to "wrist", "count" to info.nodes.size))
    }
}
