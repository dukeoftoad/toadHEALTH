package com.toadhealth.wear

import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.wear.ambient.AmbientModeSupport
import com.google.android.gms.wearable.Wearable
import org.json.JSONObject
import java.util.Locale

/**
 * The wrist side of toadHEALTH: a compact pond view that mirrors the phone.
 *
 * Data flow (all device-to-device over the Wear Data Layer):
 *   phone  --/toad/state-->  wrist    snapshots of steps / water / sleep / hr
 *   wrist  --/toad/command--> phone    quick logs (+1 glass) and pings
 *
 * The activity itself is a thin shell: state arrives through the background
 * [ToadListenerService], which hands fresh payloads straight here while the
 * activity is on screen. Everything stays on the two paired devices.
 */
class WearActivity : AppCompatActivity(), AmbientModeSupport.AmbientCallbackProvider {

    private lateinit var toad: ToadView
    private lateinit var stepsValue: TextView
    private lateinit var waterValue: TextView
    private lateinit var sleepValue: TextView
    private lateinit var hrValue: TextView
    private lateinit var statusLine: TextView
    private lateinit var waterButton: Button

    private var lastHrOn = false
    private var lastStateTs = 0L
    private var localWater = 0

    private val freshState = { json: String -> runOnUiThread { render(json) } }

    // ---------- ambient (dim-on-idle, burn-in protection) ----------

    private val ambientCallback = object : AmbientModeSupport.AmbientCallback() {
        override fun onEnterAmbient(ambientDetails: AmbientModeSupport.AmbientDetails) {
            super.onEnterAmbient(ambientDetails)
            toad.ambient = true
            waterButton.visibility = View.INVISIBLE
            statusLine.setTextColor(0xFF8A8770.toInt())
            stepsValue.setTextColor(0xFFB9B5A0.toInt())
        }

        override fun onExitAmbient() {
            super.onExitAmbient()
            toad.ambient = false
            waterButton.visibility = View.VISIBLE
            statusLine.setTextColor(0xFFA8A48E.toInt())
            stepsValue.setTextColor(0xFFF6F1E0.toInt())
        }
    }

    override fun getAmbientCallback(): AmbientModeSupport.AmbientCallback = ambientCallback

    // ---------- lifecycle ----------

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_wear)
        AmbientModeSupport.attach(this)

        // Announce the wrist capability from the foreground path too, so the
        // phone sees the toad even if the background service was never started.
        try {
            Wearable.getCapabilityClient(this).addLocalCapability(
                ToadListenerService.WRIST_CAPABILITY,
            )
        } catch (_: Exception) {
        }

        toad = findViewById(R.id.toad)
        stepsValue = findViewById(R.id.steps_value)
        waterValue = findViewById(R.id.water_value)
        sleepValue = findViewById(R.id.sleep_value)
        hrValue = findViewById(R.id.hr_value)
        statusLine = findViewById(R.id.status_line)
        waterButton = findViewById(R.id.water_button)

        waterButton.setOnClickListener {
            sendCommand(JSONObject().put("action", "log_water").put("glasses", 1))
            // Optimistic bump; the next snapshot from the phone is truth.
            localWater++
            val base = lastWater
            waterValue.text = ((if (base > 0) base else 0) + localWater).toString()
            toad.celebrate()
            statusLine.setText(R.string.status_listening)
        }
    }

    override fun onResume() {
        super.onResume()
        ToadStateStore.activityListening = true
        ToadStateStore.onFreshState = freshState
        ToadStateStore.load(this)
        ToadStateStore.lastJson?.let { render(it) }
        // Ask the phone pond for a fresh snapshot (it replies with /toad/state).
        sendCommand(JSONObject().put("action", "ping"))
    }

    override fun onPause() {
        ToadStateStore.activityListening = false
        ToadStateStore.onFreshState = null
        super.onPause()
    }

    // ---------- messaging ----------

    private fun sendCommand(payload: JSONObject) {
        val bytes = payload.toString().toByteArray(Charsets.UTF_8)
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            val client = Wearable.getMessageClient(this)
            for (node in nodes) {
                client.sendMessage(node.id, "/toad/command", bytes)
            }
        }
    }

    // ---------- rendering ----------

    private var lastWater = 0

    private fun render(json: String) {
        val state = ToadStateStore.parse(json)
        lastStateTs = (state["ts"] as? Long) ?: ((state["ts"] as? Int)?.toLong() ?: lastStateTs)
        lastWater = (state["water"] as? Int) ?: 0
        localWater = 0

        val steps = (state["steps"] as? Int) ?: 0
        val stepsGoal = (state["stepsGoal"] as? Int) ?: 8000
        stepsValue.text = compact(steps)

        waterValue.text = lastWater.toString()
        val sleepMin = (state["sleepMin"] as? Int) ?: 0
        val hours = sleepMin / 60
        val mins = sleepMin % 60
        sleepValue.text = if (mins == 0) "${hours}h" else "$hours:${mins.toString().padStart(2, '0')}h"

        lastHrOn = (state["hrOn"] as? Boolean) ?: false
        val hr = (state["hr"] as? Int) ?: 0
        hrValue.text = if (lastHrOn && hr > 0) hr.toString() else "—"

        // The toad hops when you cross a quarter of your hop goal.
        val quarters = steps * 4 / stepsGoal.coerceAtLeast(1)
        if (quarters > lastQuarters) toad.celebrate()
        lastQuarters = quarters

        refreshStatusLine(state)
        markStateFreshness()
    }

    private var lastQuarters = 0

    private fun refreshStatusLine(state: Map<String, Any>) {
        val fresh = SystemClock.elapsedRealtime() - lastArrivalElapsed < 35_000
        statusLine.text = if (state.isEmpty()) {
            getString(R.string.status_waiting)
        } else if (fresh) {
            getString(R.string.status_listening)
        } else {
            getString(R.string.status_asleep)
        }
    }

    private var lastArrivalElapsed = 0L

    /** Small pulse so the wrist feels alive even without new messages. */
    private fun markStateFreshness() {
        lastArrivalElapsed = SystemClock.elapsedRealtime()
    }

    private fun compact(value: Int): String {
        return if (value >= 10000) {
            String.format(Locale.US, "%.1fk", value / 1000f)
        } else {
            value.toString()
        }
    }
}
