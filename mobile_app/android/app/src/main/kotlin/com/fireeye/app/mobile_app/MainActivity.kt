package com.fireeye.app.mobile_app

import android.Manifest
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets
import java.util.*

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.fireeye.app/ble_mesh"
    private val EVENT_CHANNEL = "com.fireeye.app/ble_mesh_events"

    // FIRE-EYE BLE Mesh 128-bit Service and Characteristic UUIDs
    private val SERVICE_UUID: UUID = UUID.fromString("0000FE50-0000-1000-8000-00805F9B34FB")
    private val CHAR_PACKET_UUID: UUID = UUID.fromString("0000FE51-0000-1000-8000-00805F9B34FB")

    private var bluetoothManager: BluetoothManager? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bleAdvertiser: BluetoothLeAdvertiser? = null
    private var bleScanner: BluetoothLeScanner? = null
    private var gattServer: BluetoothGattServer? = null

    private var isMeshActive = false
    private var isAdvertising = false
    private var isScanning = false
    private var currentDeviceId: String = "FIRE-EYE-NODE"
    private var currentPayloadJson: String? = null

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val connectedClients = Collections.synchronizedSet(HashSet<BluetoothDevice>())
    private val discoveredPeers = Collections.synchronizedMap(HashMap<String, Long>())
    private val peerLastConnected = Collections.synchronizedMap(HashMap<String, Long>())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                sendEvent(mapOf("type" to "STATUS", "isMeshActive" to isMeshActive))
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> {
                val hasBle = packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)
                val hasAdapter = bluetoothAdapter != null
                result.success(hasBle && hasAdapter)
            }
            "isBluetoothEnabled" -> {
                result.success(bluetoothAdapter?.isEnabled == true)
            }
            "hasPermissions" -> {
                result.success(hasRequiredPermissions())
            }
            "requestPermissions" -> {
                requestRequiredPermissions()
                result.success(true)
            }
            "startMesh" -> {
                val deviceId = call.argument<String>("deviceId") ?: "FIRE-EYE-DEVICE"
                val initialPayload = call.argument<String>("payload")
                currentDeviceId = deviceId
                currentPayloadJson = initialPayload

                if (!hasRequiredPermissions()) {
                    result.error("PERMISSION_DENIED", "Required BLE permissions are missing", null)
                    return
                }

                if (bluetoothAdapter?.isEnabled != true) {
                    result.error("BLUETOOTH_DISABLED", "Bluetooth adapter is turned off", null)
                    return
                }

                val success = startMeshOperations()
                result.success(success)
            }
            "stopMesh" -> {
                stopMeshOperations()
                result.success(true)
            }
            "setMeshPayload" -> {
                val payload = call.argument<String>("payload")
                currentPayloadJson = payload
                // If advertising, restart advertising with updated header
                if (isAdvertising) {
                    restartAdvertising()
                }
                // Actively notify all connected peer centrals
                try {
                    gattServer?.let { server ->
                        val service = server.getService(SERVICE_UUID)
                        val char = service?.getCharacteristic(CHAR_PACKET_UUID)
                        if (char != null && payload != null) {
                            char.value = payload.toByteArray(StandardCharsets.UTF_8)
                            for (client in connectedClients) {
                                server.notifyCharacteristicChanged(client, char, false)
                            }
                        }
                    }
                } catch (_: Exception) {}
                result.success(true)
            }
            "getMeshStats" -> {
                result.success(mapOf(
                    "isMeshActive" to isMeshActive,
                    "isAdvertising" to isAdvertising,
                    "isScanning" to isScanning,
                    "discoveredPeersCount" to discoveredPeers.size,
                    "connectedClientsCount" to connectedClients.size,
                    "deviceId" to currentDeviceId
                ))
            }
            else -> result.notImplemented()
        }
    }

    // ==========================================
    // PERMISSIONS MANAGEMENT
    // ==========================================
    private fun hasRequiredPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val scan = ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
            val advertise = ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_ADVERTISE) == PackageManager.PERMISSION_GRANTED
            val connect = ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
            return scan && advertise && connect
        } else {
            val fineLoc = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
            val bluetooth = ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED
            val admin = ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_ADMIN) == PackageManager.PERMISSION_GRANTED
            return fineLoc && bluetooth && admin
        }
    }

    private fun requestRequiredPermissions() {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
        } else {
            arrayOf(
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN,
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            )
        }
        ActivityCompat.requestPermissions(this, permissions, 101)
    }

    // ==========================================
    // BLE MESH LIFECYCLE (Central + Peripheral)
    // ==========================================
    private fun startMeshOperations(): Boolean {
        try {
            stopMeshOperations()

            // 1. Initialize GATT Server (Peripheral receiver & sender)
            setupGattServer()

            // 2. Initialize BLE Advertising (Beacon broadcast)
            startAdvertising()

            // 3. Initialize BLE Scanning (Peer discovery)
            startScanning()

            isMeshActive = true
            sendEvent(mapOf("type" to "MESH_STARTED", "deviceId" to currentDeviceId))
            return true
        } catch (e: Exception) {
            sendEvent(mapOf("type" to "ERROR", "message" to (e.message ?: "Failed to start BLE mesh")))
            return false
        }
    }

    private fun stopMeshOperations() {
        try {
            stopAdvertising()
            stopScanning()

            gattServer?.clearServices()
            gattServer?.close()
            gattServer = null

            connectedClients.clear()
            isMeshActive = false
            sendEvent(mapOf("type" to "MESH_STOPPED"))
        } catch (_: Exception) {}
    }

    // ==========================================
    // GATT SERVER (PERIPHERAL MODE)
    // ==========================================
    private fun setupGattServer() {
        if (!hasRequiredPermissions()) return

        try {
            gattServer = bluetoothManager?.openGattServer(this, object : BluetoothGattServerCallback() {
                override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
                    super.onConnectionStateChange(device, status, newState)
                    if (newState == BluetoothProfile.STATE_CONNECTED) {
                        connectedClients.add(device)
                        sendEvent(mapOf(
                            "type" to "CLIENT_CONNECTED",
                            "address" to device.address,
                            "activeClients" to connectedClients.size
                        ))
                    } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                        connectedClients.remove(device)
                        sendEvent(mapOf(
                            "type" to "CLIENT_DISCONNECTED",
                            "address" to device.address,
                            "activeClients" to connectedClients.size
                        ))
                    }
                }

                override fun onCharacteristicReadRequest(
                    device: BluetoothDevice,
                    requestId: Int,
                    offset: Int,
                    characteristic: BluetoothGattCharacteristic
                ) {
                    super.onCharacteristicReadRequest(device, requestId, offset, characteristic)
                    if (characteristic.uuid == CHAR_PACKET_UUID) {
                        val payload = currentPayloadJson ?: "{}"
                        val bytes = payload.toByteArray(StandardCharsets.UTF_8)

                        if (offset >= bytes.size) {
                            gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, ByteArray(0))
                            return
                        }

                        val chunkSize = Math.min(bytes.size - offset, 512)
                        val responseBytes = ByteArray(chunkSize)
                        System.arraycopy(bytes, offset, responseBytes, 0, chunkSize)

                        gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, responseBytes)
                    } else {
                        gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, 0, null)
                    }
                }

                override fun onCharacteristicWriteRequest(
                    device: BluetoothDevice,
                    requestId: Int,
                    characteristic: BluetoothGattCharacteristic,
                    preparedWrite: Boolean,
                    responseNeeded: Boolean,
                    offset: Int,
                    value: ByteArray?
                ) {
                    super.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite, responseNeeded, offset, value)
                    if (characteristic.uuid == CHAR_PACKET_UUID && value != null) {
                        val incomingJson = String(value, StandardCharsets.UTF_8)
                        mainHandler.post {
                            sendEvent(mapOf(
                                "type" to "PACKET_RECEIVED",
                                "sourceAddress" to device.address,
                                "rawJson" to incomingJson
                            ))
                        }

                        if (responseNeeded) {
                            gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
                        }
                    } else if (responseNeeded) {
                        gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
                    }
                }
            })

            val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
            val packetChar = BluetoothGattCharacteristic(
                CHAR_PACKET_UUID,
                BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_WRITE or BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                BluetoothGattCharacteristic.PERMISSION_READ or BluetoothGattCharacteristic.PERMISSION_WRITE
            )
            service.addCharacteristic(packetChar)
            gattServer?.addService(service)
        } catch (_: Exception) {}
    }

    // ==========================================
    // BLE ADVERTISER (PERIPHERAL MODE)
    // ==========================================
    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            super.onStartSuccess(settingsInEffect)
            isAdvertising = true
            sendEvent(mapOf("type" to "ADVERTISING_STARTED"))
        }

        override fun onStartFailure(errorCode: Int) {
            super.onStartFailure(errorCode)
            isAdvertising = false
            sendEvent(mapOf("type" to "ADVERTISING_FAILED", "errorCode" to errorCode))
        }
    }

    private fun startAdvertising() {
        if (!hasRequiredPermissions()) return
        bleAdvertiser = bluetoothAdapter?.bluetoothLeAdvertiser ?: return

        try {
            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
                .setConnectable(true)
                .setTimeout(0)
                .build()

            val data = AdvertiseData.Builder()
                .setIncludeDeviceName(true)
                .addServiceUuid(ParcelUuid(SERVICE_UUID))
                .build()

            bleAdvertiser?.startAdvertising(settings, data, advertiseCallback)
        } catch (_: Exception) {}
    }

    private fun stopAdvertising() {
        if (!hasRequiredPermissions()) return
        try {
            bleAdvertiser?.stopAdvertising(advertiseCallback)
            isAdvertising = false
        } catch (_: Exception) {}
    }

    private fun restartAdvertising() {
        stopAdvertising()
        startAdvertising()
    }

    // ==========================================
    // BLE SCANNER & GATT CLIENT (CENTRAL MODE)
    // ==========================================
    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            super.onScanResult(callbackType, result)
            val device = result?.device ?: return
            val address = device.address ?: return
            val rssi = result.rssi

            val now = System.currentTimeMillis()
            val lastSeen = discoveredPeers[address] ?: 0L
            discoveredPeers[address] = now

            if (now - lastSeen > 2500) {
                sendEvent(mapOf(
                    "type" to "PEER_DISCOVERED",
                    "address" to address,
                    "name" to (device.name ?: "FIRE-EYE-RELAY"),
                    "rssi" to rssi
                ))
            }

            // Throttle connection attempts to once every 3.5 seconds per peer
            val lastConn = peerLastConnected[address] ?: 0L
            if (now - lastConn > 3500) {
                peerLastConnected[address] = now
                connectAndFetchPacket(device)
            }
        }

        override fun onScanFailed(errorCode: Int) {
            super.onScanFailed(errorCode)
            isScanning = false
            sendEvent(mapOf("type" to "SCAN_FAILED", "errorCode" to errorCode))
        }
    }

    private fun startScanning() {
        if (!hasRequiredPermissions()) return
        bleScanner = bluetoothAdapter?.bluetoothLeScanner ?: return

        try {
            val filter = ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(SERVICE_UUID))
                .build()

            val settings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                .build()

            bleScanner?.startScan(listOf(filter), settings, scanCallback)
            isScanning = true
            sendEvent(mapOf("type" to "SCANNING_STARTED"))
        } catch (_: Exception) {}
    }

    private fun stopScanning() {
        if (!hasRequiredPermissions()) return
        try {
            bleScanner?.stopScan(scanCallback)
            isScanning = false
        } catch (_: Exception) {}
    }

    private fun connectAndFetchPacket(device: BluetoothDevice) {
        if (!hasRequiredPermissions()) return

        try {
            val callback = object : BluetoothGattCallback() {
                override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
                    if (status != BluetoothGatt.GATT_SUCCESS) {
                        try { gatt.close() } catch (_: Exception) {}
                        return
                    }
                    if (newState == BluetoothProfile.STATE_CONNECTED) {
                        // Request MTU 512 so complete 400-byte JSON is read without truncation
                        val mtuOk = gatt.requestMtu(512)
                        if (!mtuOk) {
                            gatt.discoverServices()
                        }
                    } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                        try { gatt.close() } catch (_: Exception) {}
                    }
                }

                override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
                    super.onMtuChanged(gatt, mtu, status)
                    gatt.discoverServices()
                }

                override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
                    if (status == BluetoothGatt.GATT_SUCCESS) {
                        val service = gatt.getService(SERVICE_UUID)
                        val characteristic = service?.getCharacteristic(CHAR_PACKET_UUID)
                        if (characteristic != null) {
                            // If local device has an active SOS payload, push it directly to peer
                            val localPayload = currentPayloadJson
                            if (localPayload != null && localPayload.contains(""message_type":"SOS"")) {
                                try {
                                    val bytes = localPayload.toByteArray(StandardCharsets.UTF_8)
                                    characteristic.value = bytes
                                    gatt.writeCharacteristic(characteristic)
                                } catch (_: Exception) {}
                            }
                            gatt.readCharacteristic(characteristic)
                        } else {
                            gatt.disconnect()
                        }
                    } else {
                        gatt.disconnect()
                    }
                }

                override fun onCharacteristicRead(
                    gatt: BluetoothGatt,
                    characteristic: BluetoothGattCharacteristic,
                    status: Int
                ) {
                    if (status == BluetoothGatt.GATT_SUCCESS && characteristic.uuid == CHAR_PACKET_UUID) {
                        val value = characteristic.value
                        if (value != null && value.isNotEmpty()) {
                            val json = String(value, StandardCharsets.UTF_8)
                            if (json.startsWith("{") && json.endsWith("}")) {
                                mainHandler.post {
                                    sendEvent(mapOf(
                                        "type" to "PACKET_RECEIVED",
                                        "sourceAddress" to gatt.device.address,
                                        "rawJson" to json
                                    ))
                                }
                            }
                        }
                    }
                    mainHandler.postDelayed({
                        try { gatt.disconnect() } catch (_: Exception) {}
                    }, 500)
                }

                override fun onCharacteristicChanged(
                    gatt: BluetoothGatt,
                    characteristic: BluetoothGattCharacteristic
                ) {
                    super.onCharacteristicChanged(gatt, characteristic)
                    if (characteristic.uuid == CHAR_PACKET_UUID) {
                        val value = characteristic.value
                        if (value != null && value.isNotEmpty()) {
                            val json = String(value, StandardCharsets.UTF_8)
                            if (json.startsWith("{") && json.endsWith("}")) {
                                mainHandler.post {
                                    sendEvent(mapOf(
                                        "type" to "PACKET_RECEIVED",
                                        "sourceAddress" to gatt.device.address,
                                        "rawJson" to json
                                    ))
                                }
                            }
                        }
                    }
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                device.connectGatt(this, false, callback, BluetoothDevice.TRANSPORT_LE)
            } else {
                device.connectGatt(this, false, callback)
            }
        } catch (_: Exception) {}
    }

    // ==========================================
    // EVENT STREAM HELPER
    // ==========================================
    private fun sendEvent(event: Map<String, Any>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }
}
