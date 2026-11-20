package com.toadhealth.app

import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * toadHEALTH native bridge.
 *
 * Three privacy-critical jobs, all implemented in-house with zero
 * third-party plugins and zero Google Play Services:
 *
 *  1. "toadhealth/vault"  - hardware-backed AES-256-GCM key vault
 *     (Android Keystore generates and guards the key; the key material
 *     never leaves the secure hardware). Exposes storageDir / encrypt /
 *     decrypt for envelope encryption of the on-device database.
 *
 *  2. "toadhealth/steps"  - raw hardware step counter sensor
 *     (Sensor.TYPE_STEP_COUNTER from the AOSP sensor stack - not
 *     Google Fit, not Health Connect, no network involved).
 *
 *  3. "toadhealth/watch" + "toadhealth/watch_events" - smart-watch link
 *     over plain BLE GATT (standard Heart Rate Profile + Battery),
 *     implemented in WatchLink.kt. No Wear Data Layer, no Play Services,
 *     no network - the watch hops straight onto the pond.
 *
 *  4. "toadhealth/wear_os" + "toadhealth/wear_os_events" - the Wear OS
 *     companion bridge (see WearOsBridge.kt): mirrors pond snapshots to the
 *     android/wear wrist app over the Wear Data Layer and receives quick
 *     logs back. When Play Services are missing (de-Googled ROMs) the
 *     bridge quietly reports unsupported and everything else stands.
 */
class MainActivity : FlutterActivity() {

    private var stepListener: SensorEventListener? = null
    private var watchLink: WatchLink? = null
    private var wearOsBridge: WearOsBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "toadhealth/vault").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "storageDir" -> result.success(filesDir.absolutePath)
                    "encrypt" -> {
                        val plain = call.argument<ByteArray>("plain")
                        if (plain == null) {
                            result.error("BAD_ARGS", "missing 'plain'", null)
                        } else {
                            result.success(seal(plain))
                        }
                    }
                    "decrypt" -> {
                        val sealed = call.argument<ByteArray>("sealed")
                        if (sealed == null) {
                            result.error("BAD_ARGS", "missing 'sealed'", null)
                        } else {
                            result.success(unseal(sealed))
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("VAULT_ERROR", e.message, null)
            }
        }

        EventChannel(messenger, "toadhealth/steps").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, events: EventChannel.EventSink) {
                startStepCounter(events)
            }

            override fun onCancel(args: Any?) {
                stopStepCounter()
            }
        })

        // ---------- Smart-watch link (plain BLE GATT - see WatchLink.kt) ----------

        val link = WatchLink(this)
        watchLink = link

        MethodChannel(messenger, "toadhealth/watch").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "isAvailable" -> result.success(link.isAvailable())
                    "requestPermissions" -> {
                        if (link.hasPermissions()) {
                            result.success(true)
                        } else {
                            // Dialog shown: the answer completes the result
                            // later from onRequestPermissionsResult.
                            val asked = link.requestPermissions { ok -> result.success(ok) }
                            if (!asked) result.success(false)
                        }
                    }
                    "startScan" -> result.success(link.startScan())
                    "stopScan" -> {
                        link.stopScan()
                        result.success(null)
                    }
                    "connect" -> {
                        val address = call.argument<String>("address")
                        if (address == null) {
                            result.error("BAD_ARGS", "missing 'address'", null)
                        } else {
                            result.success(link.connect(address))
                        }
                    }
                    "disconnect" -> {
                        link.disconnect()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("WATCH_ERROR", e.message, null)
            }
        }

        EventChannel(messenger, "toadhealth/watch_events").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, events: EventChannel.EventSink) {
                link.setSink(events)
            }

            override fun onCancel(args: Any?) {
                link.stopScan()
                link.setSink(null)
            }
        })

        // ---------- Wear OS companion (Data Layer - see WearOsBridge.kt) ----------

        val wearOs = WearOsBridge(this)
        wearOsBridge = wearOs

        MethodChannel(messenger, "toadhealth/wear_os").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "isSupported" -> result.success(wearOs.isSupported())
                    "sendState" -> {
                        val json = call.argument<String>("json")
                        if (json == null) {
                            result.error("BAD_ARGS", "missing 'json'", null)
                        } else {
                            result.success(wearOs.sendState(json))
                        }
                    }
                    "clearState" -> result.success(wearOs.clearState())
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("WEAROS_ERROR", e.message, null)
            }
        }

        EventChannel(messenger, "toadhealth/wear_os_events").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, events: EventChannel.EventSink) {
                wearOs.setSink(events)
                wearOs.start()
            }

            override fun onCancel(args: Any?) {
                wearOs.setSink(null)
                wearOs.stop()
            }
        })
    }

    override fun onDestroy() {
        stopStepCounter()
        wearOsBridge?.setSink(null)
        wearOsBridge?.stop()
        wearOsBridge = null
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == WatchLink.PERMISSION_REQUEST) {
            watchLink?.onPermissionResult(
                grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            )
        }
    }

    // ---------- Hardware-backed key vault (Android Keystore, AES-256-GCM) ----------

    private fun keyAlias(): String = "toadhealth_master"

    private fun ensureKey() {
        val ks = KeyStore.getInstance("AndroidKeyStore")
        ks.load(null)
        if (ks.containsAlias(keyAlias())) return
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                keyAlias(),
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
        )
        generator.generateKey()
    }

    private fun loadKey(): SecretKey {
        ensureKey()
        val ks = KeyStore.getInstance("AndroidKeyStore")
        ks.load(null)
        return ks.getKey(keyAlias(), null) as SecretKey
    }

    /** Sealed format: [version:1][iv:12][ciphertext+tag]. */
    private fun seal(plain: ByteArray): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, loadKey())
        val iv = cipher.iv
        val sealed = cipher.doFinal(plain)
        val out = ByteArray(1 + iv.size + sealed.size)
        out[0] = 1
        iv.copyInto(out, 1)
        sealed.copyInto(out, 1 + iv.size)
        return out
    }

    private fun unseal(sealedBytes: ByteArray): ByteArray {
        if (sealedBytes.isEmpty() || sealedBytes[0] != 1.toByte()) {
            throw IllegalArgumentException("unsupported sealed format")
        }
        val iv = sealedBytes.copyOfRange(1, 13)
        val body = sealedBytes.copyOfRange(13, sealedBytes.size)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, loadKey(), GCMParameterSpec(128, iv))
        return cipher.doFinal(body)
    }

    // ---------- Hardware step counter (AOSP sensors, no Play Services) ----------

    private fun startStepCounter(events: EventChannel.EventSink) {
        val manager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = manager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        if (sensor == null) {
            events.error("UNAVAILABLE", "No step counter sensor on this device", null)
            return
        }
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                // Emit the raw total; Dart derives per-event deltas and
                // buckets them by hour, so reboot baselines are safe.
                val total = event.values[0].toInt()
                events.success(total)
            }

            override fun onAccuracyChanged(s: Sensor?, accuracy: Int) {}
        }
        stepListener = listener
        manager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_UI)
    }

    private fun stopStepCounter() {
        stepListener?.let {
            (getSystemService(Context.SENSOR_SERVICE) as SensorManager).unregisterListener(it)
        }
        stepListener = null
    }
}
