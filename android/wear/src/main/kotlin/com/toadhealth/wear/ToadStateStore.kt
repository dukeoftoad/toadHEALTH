package com.toadhealth.wear

import android.content.Context
import org.json.JSONObject

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

    /** Parses the stored snapshot into a map; empty map when nothing stored. */
    fun parse(json: String?): Map<String, Any> {
        val out = HashMap<String, Any>()
        if (json.isNullOrBlank()) return out
        try {
            val obj = JSONObject(json)
            for (key in listOf(
                "steps", "stepsGoal", "water", "waterGoal",
                "sleepMin", "hr", "hrOn", "ts"
            )) {
                if (obj.has(key)) out[key] = obj.get(key)
            }
        } catch (_: Exception) {
        }
        return out
    }
}
