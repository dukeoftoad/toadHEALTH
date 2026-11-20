package com.toadhealth.wear

import android.content.Context
import org.json.JSONObject

/** One typed pond snapshot mirrored from the phone. */
data class PondState(
    val steps: Int = 0,
    val stepsGoal: Int = 8000,
    val water: Int = 0,
    val waterGoal: Int = 8,
    val sleepMin: Int = 0,
    val hr: Int = 0,
    val hrOn: Boolean = false,
    val ts: Int = 0,
) {
    val isEmpty: Boolean get() = ts == 0
}

/**
 * Holds the newest pond snapshot received from the phone.
 *
 * Both the background [ToadListenerService] and the foreground
 * [WearActivity] write through this tiny store, so a wrist app started
 * from cold shows the last mirrored pond instantly instead of a blank
 * "waiting for the pond" screen.
 */
object ToadStateStore {

    private const val PREFS = "toad_pond"
    private const val KEY_STATE = "last_state"

    /** Raw JSON of the last /toad/state message, or null before the first hop. */
    var lastJson: String? = null
        private set

    /** Set to true by [WearActivity] while resumed, cleared on pause. */
    var activityListening = false

    /** Fresh state callback - wired by [WearActivity], drained by the service. */
    var onFreshState: ((String) -> Unit)? = null

    fun save(context: Context, json: String) {
        lastJson = json
        try {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putString(KEY_STATE, json).apply()
        } catch (_: Exception) {
        }
        // Wake the activity only when it is the foreground owner; otherwise
        // the service just warms the store for the next cold start.
        if (activityListening) {
            onFreshState?.invoke(json)
        }
    }

    fun load(context: Context) {
        try {
            lastJson = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_STATE, null)
        } catch (_: Exception) {
        }
    }

    /** Parses the stored snapshot; defaults cover a blank first boot. */
    fun parseState(json: String?): PondState {
        if (json.isNullOrBlank()) return PondState()
        return try {
            val obj = JSONObject(json)
            PondState(
                steps = obj.optInt("steps", 0),
                stepsGoal = obj.optInt("stepsGoal", 8000),
                water = obj.optInt("water", 0),
                waterGoal = obj.optInt("waterGoal", 8),
                sleepMin = obj.optInt("sleepMin", 0),
                hr = obj.optInt("hr", 0),
                hrOn = obj.optBoolean("hrOn", false),
                ts = obj.optInt("ts", 0),
            )
        } catch (_: Exception) {
            PondState()
        }
    }
}
