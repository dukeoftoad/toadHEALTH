package com.toadhealth.app

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.util.UUID

/**
 * toadHEALTH's smart-watch link, implemented in-house on the plain Android
 * BLE stack. Third job of the native bridge, alongside the Keystore vault
 * ("toadhealth/vault") and the step counter ("toadhealth/steps"):
 *
 *  3. "toadhealth/watch" + "toadhealth/watch_events"
 *     A GATT client for smart watches and heart-rate straps speaking the
 *     standard Bluetooth Heart Rate Profile:
 *       - Heart Rate Service        0x180D
 *       - Heart Rate Measurement    0x2A37  (notify)
 *       - Battery Service           0x180F
 *       - Battery Level             0x2A19  (read)
 *
 * Deliberately NOT Google's Wear Data Layer: no Play Services dependency,
 * no companion app requirement on the phone side, no network. Any watch
 * that exposes the standard heart-rate service (Wear OS watches expose it
 * while their sensor is shared; many bands/straps always do) can be wired
 * straight into the pond. All readings stay on-device, like everything
 * else in toadHEALTH.
 */
class WatchLink(private val activity: Activity) {

    companion object {
        val HEART_RATE_SERVICE: UUID = UUID.fromString("0000180d-0000-1000-8000-00805f9b34fb")
        val HEART_RATE_MEASUREMENT: UUID = UUID.fromString("00002a37-0000-1000-8000-00805f9b34fb")
        val BATTERY_SERVICE: UUID = UUID.fromString("0000180f-0000-1000-8000-00805f9b34fb")
        val BATTERY_LEVEL: UUID = UUID.fromString("00002a19-0000-1000-8000-00805f9b34fb")
        val CCC_DESCRIPTOR: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

        const val PERMISSION_REQUEST = 4701
        private const val TAG = "ToadWatch"
    }

    private val manager: BluetoothManager?
        get() = activity.getSystemService(Activity.BLUETOOTH_SERVICE) as? BluetoothManager

    private val adapter: BluetoothAdapter?
        get() = manager?.adapter

    private var scannerCallback: ScanCallback? = null
    private var gatt: BluetoothGatt? = null
    private var sink: EventChannel.EventSink? = null
    private var permissionCallback: ((Boolean) -> Unit)? = null
    private var hrSubscribed = false

    // ---------- event plumbing ----------

    fun setSink(sink: EventChannel.EventSink?) {
        this.sink = sink
    }

    private fun emit(payload: Map<String, Any?>) {
        val s = sink ?: return
        activity.runOnUiThread { try { s.success(payload) } catch (e: Exception) { Log.w(TAG, "emit failed", e) } }
    }

    // ---------- permissions ----------

    private fun granted(permission: String): Boolean {
        return if (Build.VERSION.SDK_INT >= 23) {
            activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    fun hasPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= 31) {
            granted(android.Manifest.permission.BLUETOOTH_CONNECT) &&
                granted(android.Manifest.permission.BLUETOOTH_SCAN)
        } else {
            granted(android.Manifest.permission.ACCESS_FINE_LOCATION)
        }
    }

    /**
     * Asks the user for the BLE permissions. Returns true when the dialog
     * was shown (answer arrives through [onPermissionResult]); calls
     * [callback] synchronously with true when already granted; returns
     * false (and calls callback with false) when no dialog could be shown.
     */
    fun requestPermissions(callback: (Boolean) -> Unit): Boolean {
        if (hasPermissions()) {
            callback(true)
            return true
        }
        if (Build.VERSION.SDK_INT < 23) {
            callback(false)
            return false
        }
        val perms = if (Build.VERSION.SDK_INT >= 31) {
            arrayOf(
                android.Manifest.permission.BLUETOOTH_CONNECT,
                android.Manifest.permission.BLUETOOTH_SCAN,
            )
        } else {
            arrayOf(android.Manifest.permission.ACCESS_FINE_LOCATION)
        }
        permissionCallback = callback
        return try {
            activity.requestPermissions(perms, PERMISSION_REQUEST)
            true
        } catch (e: Exception) {
            permissionCallback = null
            callback(false)
            false
        }
    }

    fun onPermissionResult(granted: Boolean) {
        val cb = permissionCallback
        permissionCallback = null
        cb?.invoke(granted)
        if (!granted) emit(mapOf("ev" to "error", "code" to "perm"))
    }

    // ---------- availability ----------

    fun isAvailable(): Boolean {
        val a = adapter ?: return false
        return a.isEnabled
    }

    // ---------- scanning ----------

    @SuppressLint("MissingPermission")
    fun startScan(): Boolean {
        val a = adapter
        if (a == null || !a.isEnabled) {
            emit(mapOf("ev" to "error", "code" to "bt_off"))
            return false
        }
        if (!hasPermissions()) {
            emit(mapOf("ev" to "error", "code" to "perm"))
            return false
        }
        stopScan()
        val scanner = a.bluetoothLeScanner ?: return false
        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                val device = result.device ?: return
                val name = try {
                    device.name ?: result.scanRecord?.deviceName ?: "Unnamed buddy"
                } catch (e: SecurityException) {
                    "Unnamed buddy"
                }
                emit(
                    mapOf(
                        "ev" to "device",
                        "name" to name,
                        "address" to device.address,
                        "rssi" to result.rssi,
                    )
                )
            }

            override fun onScanFailed(errorCode: Int) {
                emit(mapOf("ev" to "error", "code" to "scan", "detail" to errorCode))
            }
        }
        scannerCallback = callback
        hrSubscribed = false
        // No scan filter on purpose: some watches advertise their HR service
        // only intermittently, and seeing every nearby buddy lets the user
        // recognise theirs by name. Filtering happens in Dart.
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()
        return try {
            scanner.startScan(null, settings, callback)
            emit(mapOf("ev" to "state", "value" to "scanning"))
            true
        } catch (e: Exception) {
            scannerCallback = null
            Log.w(TAG, "startScan failed", e)
            emit(mapOf("ev" to "error", "code" to "scan"))
            false
        }
    }

    @SuppressLint("MissingPermission")
    fun stopScan() {
        scannerCallback?.let { cb ->
            try {
                adapter?.bluetoothLeScanner?.stopScan(cb)
            } catch (e: Exception) {
                Log.w(TAG, "stopScan failed", e)
            }
        }
        scannerCallback = null
    }

    // ---------- GATT connection ----------

    @SuppressLint("MissingPermission")
    fun connect(address: String): Boolean {
        val a = adapter
        if (a == null || !a.isEnabled) {
            emit(mapOf("ev" to "error", "code" to "bt_off"))
            return false
        }
        if (!hasPermissions()) {
            emit(mapOf("ev" to "error", "code" to "perm"))
            return false
        }
        disconnectInternal()
        val device = try {
            a.getRemoteDevice(address)
        } catch (e: IllegalArgumentException) {
            emit(mapOf("ev" to "error", "code" to "connect"))
            return false
        }
        emit(mapOf("ev" to "state", "value" to "connecting"))
        hrSubscribed = false
        return try {
            gatt = device.connectGatt(activity, false, gattCallback)
            true
        } catch (e: Exception) {
            Log.w(TAG, "connect failed", e)
            gatt = null
            emit(mapOf("ev" to "error", "code" to "connect"))
            false
        }
    }

    fun disconnect() {
        disconnectInternal()
        emit(mapOf("ev" to "state", "value" to "off"))
    }

    @SuppressLint("MissingPermission")
    private fun disconnectInternal() {
        gatt?.let { g ->
            try { g.disconnect() } catch (e: Exception) { Log.w(TAG, "disconnect failed", e) }
            try { g.close() } catch (e: Exception) { /* already closed */ }
        }
        gatt = null
    }

    private val gattCallback = object : BluetoothGattCallback() {

        override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    gatt = g
                    try { g.discoverServices() } catch (e: Exception) { Log.w(TAG, "discover failed", e) }
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    try { g.close() } catch (e: Exception) { /* already closed */ }
                    if (gatt === g) gatt = null
                    hrSubscribed = false
                    emit(mapOf("ev" to "state", "value" to "off"))
                }
            }
        }

        override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                emit(mapOf("ev" to "error", "code" to "connect"))
                g.disconnect()
                return
            }
            val service = g.getService(HEART_RATE_SERVICE)
            val characteristic = service?.getCharacteristic(HEART_RATE_MEASUREMENT)
            if (service == null || characteristic == null) {
                // Not a heart-rate device: tell Dart instead of pretending.
                emit(mapOf("ev" to "error", "code" to "no_hr"))
                g.disconnect()
                return
            }
            try {
                g.setCharacteristicNotification(characteristic, true)
                val descriptor = characteristic.getDescriptor(CCC_DESCRIPTOR)
                if (descriptor != null) {
                    if (Build.VERSION.SDK_INT >= 33) {
                        g.writeDescriptor(descriptor, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
                    } else {
                        @Suppress("DEPRECATION")
                        g.writeDescriptor(descriptor)
                    }
                } else {
                    // Rare devices skip the CCC descriptor; still emit state so
                    // the UI can proceed and rely on read polling if needed.
                    emit(mapOf("ev" to "state", "value" to "connected"))
                }
            } catch (e: SecurityException) {
                emit(mapOf("ev" to "error", "code" to "perm"))
                g.disconnect()
            }
        }

        override fun onDescriptorWrite(g: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
            super.onDescriptorWrite(g, descriptor, status)
            if (descriptor.uuid == CCC_DESCRIPTOR && status == BluetoothGatt.GATT_SUCCESS) {
                hrSubscribed = true
                emit(mapOf("ev" to "state", "value" to "connected"))
                // One battery read once the heart-rate pipe is live.
                val battery = g.getService(BATTERY_SERVICE)?.getCharacteristic(BATTERY_LEVEL)
                if (battery != null) {
                    try {
                        if (Build.VERSION.SDK_INT >= 33) {
                            g.readCharacteristic(battery)
                        } else {
                            @Suppress("DEPRECATION")
                            g.readCharacteristic(battery)
                        }
                    } catch (e: SecurityException) {
                        Log.w(TAG, "battery read denied", e)
                    }
                }
            }
        }

        // API 33+ signature.
        override fun onCharacteristicChanged(g: BluetoothGatt, characteristic: BluetoothGattCharacteristic, value: ByteArray) {
            handleData(characteristic.uuid, value)
        }

        // Pre-33 signature (data comes from characteristic.value).
        @Suppress("DEPRECATION")
        override fun onCharacteristicChanged(g: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            handleData(characteristic.uuid, characteristic.value ?: return)
        }

        // API 33+ signature.
        override fun onCharacteristicRead(g: BluetoothGatt, characteristic: BluetoothGattCharacteristic, value: ByteArray, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) handleData(characteristic.uuid, value)
        }

        // Pre-33 signature.
        @Suppress("DEPRECATION")
        override fun onCharacteristicRead(g: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                handleData(characteristic.uuid, characteristic.value ?: return)
            }
        }
    }

    private fun handleData(uuid: UUID, value: ByteArray) {
        when (uuid) {
            HEART_RATE_MEASUREMENT -> {
                if (value.isEmpty()) return
                val flags = value[0].toInt() and 0xFF
                val bpm = if (flags and 0x01 != 0 && value.size >= 3) {
                    // 16-bit little-endian BPM.
                    (value[1].toInt() and 0xFF) or ((value[2].toInt() and 0xFF) shl 8)
                } else if (value.size >= 2) {
                    value[1].toInt() and 0xFF
                } else {
                    return
                }
                if (bpm in 20..250) emit(mapOf("ev" to "hr", "bpm" to bpm))
            }
            BATTERY_LEVEL -> {
                if (value.isNotEmpty()) {
                    emit(mapOf("ev" to "battery", "level" to (value[0].toInt() and 0xFF)))
                }
            }
        }
    }
}
