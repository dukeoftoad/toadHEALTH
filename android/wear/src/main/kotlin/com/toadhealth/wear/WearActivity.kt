package com.toadhealth.wear

import android.app.Activity
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.Wearable
import org.json.JSONObject

/**
 * The wrist side of toadHEALTH: a compact pond view that mirrors the phone.
 *
 * Data flow through the Wear Data Layer:
 *   phone  --/toad/state-->  wrist    snapshots of steps / water / sleep / hr
 *   wrist  --/toad/command--> phone    quick logs (+1 glass) and pings
 *
 * The Data Layer uses encrypted Bluetooth when available. Google Play
 * services can relay end-to-end-encrypted payloads through Google-owned
 * cloud servers when Bluetooth is unavailable. State arrives through the
 * background [ToadListenerService], which hands fresh payloads to this
 * activity while it is on screen.
 *
 * Deliberately plain android.app.Activity: the wrist app links zero AAR
 * resources, so the aapt2 link only ever sees framework + local resources.
 * Ambient dimming is left to the OS screen timeout rather than pulling in
 * androidx libraries just for a burn-in rule.
 */
class WearActivity : Activity() {

    private lateinit var toad: ToadView
    private lateinit var stepsValue: TextView
    private lateinit var waterValue: TextView
    private lateinit var sleepValue: TextView
    private lateinit var hrValue: TextView
    private lateinit var statusLine: TextView
    private lateinit var waterButton: Button

    private var lastWater = 0
    private var lastQuarters = 0
    private var localWater = 0

    private val freshState = { json: String -> runOnUiThread { render(json) } }
    private val clearedState = {
        runOnUiThread {
            lastWater = 0
            localWater = 0
            lastQuarters = 0
            stepsValue.text = "—"
            waterValue.text = "—"
            sleepValue.text = "—"
            hrValue.text = "—"
            statusLine.setText(R.string.status_asleep)
            waterButton.isEnabled = false
        }
    }

    // ---------- lifecycle ----------

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_wear)

        toad = findViewById(R.id.toad)
        stepsValue = findViewById(R.id.steps_value)
        waterValue = findViewById(R.id.water_value)
        sleepValue = findViewById(R.id.sleep_value)
        hrValue = findViewById(R.id.hr_value)
        statusLine = findViewById(R.id.status_line)
        waterButton = findViewById(R.id.water_button)
        // Until a fresh mirror snapshot confirms that mirroring is enabled,
        // don't let the wrist optimistically display a local health change.
        waterButton.isEnabled = false

        waterButton.setOnClickListener {
            sendCommand(JSONObject().put("action", "log_water").put("glasses", 1))
            // Optimistic bump; the next snapshot from the phone is truth.
            localWater++
            waterValue.text = (lastWater + localWater).toString()
            toad.celebrate()
            statusLine.setText(R.string.status_listening)
        }
    }

    override fun onResume() {
        super.onResume()
        ToadStateStore.activityListening = true
        ToadStateStore.onFreshState = freshState
        ToadStateStore.onCleared = clearedState
        ToadStateStore.load(this)
        ToadStateStore.lastJson?.let { render(it) }
        // Ask the phone pond for a fresh snapshot (it replies with /toad/state).
        sendCommand(JSONObject().put("action", "ping"))
    }

    override fun onPause() {
        ToadStateStore.activityListening = false
        ToadStateStore.onFreshState = null
        ToadStateStore.onCleared = null
        super.onPause()
    }

    // ---------- messaging ----------

    private fun sendCommand(payload: JSONObject) {
        val bytes = payload.toString().toByteArray(Charsets.UTF_8)
        try {
            Wearable.getCapabilityClient(this)
                .getCapability(PHONE_CAPABILITY, CapabilityClient.FILTER_REACHABLE)
                .addOnSuccessListener { info ->
                    val client = Wearable.getMessageClient(this)
                    for (node in info.nodes) {
                        client.sendMessage(node.id, "/toad/command", bytes)
                            .addOnFailureListener { }
                    }
                }
        } catch (_: Exception) {
        }
    }

    companion object {
        private const val PHONE_CAPABILITY = "toadhealth_phone"
    }

    // ---------- rendering ----------

    private fun render(json: String) {
        val state = ToadStateStore.parseState(json)
        if (state.isEmpty) return
        lastWater = state.water
        localWater = 0

        val steps = state.steps
        val stepsGoal = state.stepsGoal.coerceAtLeast(1)
        stepsValue.text = compact(steps)

        waterValue.text = lastWater.toString()
        val sleepMin = state.sleepMin
        val hours = sleepMin / 60
        val mins = sleepMin % 60
        sleepValue.text = if (mins == 0) "${hours}h" else "$hours:${mins.toString().padStart(2, '0')}h"

        val hr = state.hr
        hrValue.text = if (state.hrOn && hr > 0) hr.toString() else "—"

        // The toad hops when you cross a quarter of your hop goal.
        val quarters = steps * 4 / stepsGoal
        if (quarters > lastQuarters) toad.celebrate()
        lastQuarters = quarters

        val ageMs = System.currentTimeMillis() - state.ts
        val fresh = state.ts > 0L && ageMs in 0L..35_000L
        statusLine.setText(
            if (fresh) R.string.status_listening else R.string.status_asleep,
        )
        waterButton.isEnabled = fresh
    }

    private fun compact(value: Int): String {
        return if (value >= 10000) {
            String.format(java.util.Locale.US, "%.1fk", value / 1000f)
        } else {
            value.toString()
        }
    }
}
