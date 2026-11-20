package com.toadhealth.wear

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.json.JSONObject
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** One typed pond snapshot mirrored from the phone. */
data class PondState(
    val steps: Int = 0,
    val stepsGoal: Int = 8000,
    val water: Int = 0,
    val waterGoal: Int = 8,
    val sleepMin: Int = 0,
    val hr: Int = 0,
    val hrOn: Boolean = false,
    val ts: Long = 0L,
) {
    val isEmpty: Boolean get() = ts <= 0L
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
    private const val KEY_ALIAS = "toadhealth_watch_snapshot_v1"
    private const val FORMAT_VERSION: Byte = 1
    private const val IV_LENGTH = 12

    /** Raw JSON exists only in process memory; disk always stores AES-GCM ciphertext. */
    var lastJson: String? = null
        private set

    /** Set while WearActivity is resumed so service messages update its UI. */
    var activityListening = false
    var onFreshState: ((String) -> Unit)? = null
    var onCleared: (() -> Unit)? = null

    private fun secretKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        (keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }

        val generator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            "AndroidKeyStore",
        )
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .setRandomizedEncryptionRequired(true)
                .build(),
        )
        return generator.generateKey()
    }

    private const val KEY_CLEAR_BEFORE = "clear_before_ts"

    private fun decryptStored(context: Context): String? {
        val encoded = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_STATE, null) ?: return null
        val record = Base64.decode(encoded, Base64.NO_WRAP)
        require(record.size > 1 + IV_LENGTH && record[0] == FORMAT_VERSION) {
            "Unsupported or truncated watch snapshot"
        }
        val iv = record.copyOfRange(1, 1 + IV_LENGTH)
        val ciphertext = record.copyOfRange(1 + IV_LENGTH, record.size)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.DECRYPT_MODE,
            secretKey(),
            GCMParameterSpec(128, iv),
        )
        return String(cipher.doFinal(ciphertext), Charsets.UTF_8)
    }

    fun save(context: Context, json: String) {
        val incoming = parseState(json)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val clearBefore = prefs.getLong(KEY_CLEAR_BEFORE, 0L)
        if (incoming.isEmpty || incoming.ts <= clearBefore) return

        val current = lastJson?.let { parseState(it) }
        if (current != null && current.ts > incoming.ts) return

        try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, secretKey())
            val ciphertext = cipher.doFinal(json.toByteArray(Charsets.UTF_8))
            val iv = cipher.iv
            val record = ByteArray(1 + iv.size + ciphertext.size)
            record[0] = FORMAT_VERSION
            iv.copyInto(record, 1)
            ciphertext.copyInto(record, 1 + iv.size)
            prefs.edit()
                .putString(KEY_STATE, Base64.encodeToString(record, Base64.NO_WRAP))
                .apply()
            lastJson = json
            if (activityListening) onFreshState?.invoke(json)
        } catch (_: Exception) {
            // Never leave an older snapshot on disk if encryption/persistence fails.
            prefs.edit().remove(KEY_STATE).apply()
            lastJson = null
        }
    }

    fun load(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val json = try {
            decryptStored(context)
        } catch (_: Exception) {
            null
        }
        if (json == null) {
            lastJson = null
            if (prefs.contains(KEY_STATE)) {
                prefs.edit().remove(KEY_STATE).commit()
            }
            return
        }

        val state = parseState(json)
        val clearBefore = prefs.getLong(KEY_CLEAR_BEFORE, 0L)
        if (state.isEmpty || state.ts <= clearBefore) {
            prefs.edit().remove(KEY_STATE).commit()
            lastJson = null
            return
        }
        lastJson = json
    }

    /**
     * Stores a timestamp watermark as well as clearing the current snapshot.
     * Any delayed pre-clear message arriving later is ignored, preventing an
     * in-flight queued state message from repopulating the cache after opt-out.
     * A newer snapshot is retained if Data Layer delivery reordered messages.
     */
    fun clear(context: Context, clearedAt: Long = System.currentTimeMillis()) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val currentJson = lastJson ?: try {
            decryptStored(context)
        } catch (_: Exception) {
            null
        }
        val currentTs = currentJson?.let { parseState(it).ts } ?: 0L
        val watermark = maxOf(prefs.getLong(KEY_CLEAR_BEFORE, 0L), clearedAt)
        val editor = prefs.edit().putLong(KEY_CLEAR_BEFORE, watermark)
        val didClear = currentTs <= watermark
        if (didClear) {
            editor.remove(KEY_STATE)
            lastJson = null
        } else {
            lastJson = currentJson
        }
        editor.commit()
        if (didClear && activityListening) onCleared?.invoke()
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
                ts = obj.optLong("ts", 0L),
            )
        } catch (_: Exception) {
            PondState()
        }
    }
}
