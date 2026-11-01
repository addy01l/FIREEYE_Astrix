import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_client.dart';import '../sos_service.dart';
import 'ble_mesh_adapter.dart';
import 'mesh_packet_model.dart';
import 'mesh_storage_service.dart';

class MeshManager {
  static const String _deviceIdKey = 'fireeye_ble_device_id';

  final BleMeshAdapter _adapter = BleMeshAdapter.instance;
  final MeshStorageService _storage = MeshStorageService.instance;
  final ApiClient _apiClient = ApiClient.instance;

  String _deviceId = 'DEV-UNKNOWN';
  bool _isMeshRunning = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  final Map<String, DiscoveredBlePeer> _nearbyPeers = {};
  final List<VoidCallback> _listeners = [];
  final StreamController<MeshPacketModel> _sosAlertController = StreamController<MeshPacketModel>.broadcast();
  Stream<MeshPacketModel> get onSosAlertReceived => _sosAlertController.stream;
  Timer? _syncTimer;
  StreamSubscription? _bleEventSub;

  static final MeshManager instance = MeshManager._internal();
  MeshManager._internal();

  String get deviceId => _deviceId;
  bool get isMeshRunning => _isMeshRunning;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  List<DiscoveredBlePeer> get nearbyPeers => _nearbyPeers.values.toList();
  MeshStorageService get storage => _storage;

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notifyListeners() {
    for (final l in List<VoidCallback>.from(_listeners)) {
      try {
        l();
      } catch (_) {}
    }
  }

  Future<void> init() async {
    // 1. Initialize persistent storage
    await _storage.init();

    // 2. Load or generate stable persistent Device ID
    final sp = await SharedPreferences.getInstance();
    var devId = sp.getString(_deviceIdKey);
    if (devId == null || devId.isEmpty) {
      final shortUuid = const Uuid().v4().substring(0, 6).toUpperCase();
      devId = 'FE-NODE-$shortUuid';
      await sp.setString(_deviceIdKey, devId);
    }
    _deviceId = devId;

    // 3. Listen to BLE adapter events
    _bleEventSub?.cancel();
    _bleEventSub = _adapter.events.listen(_onBleEvent);

    _notifyListeners();
  }

  /// Start BLE Mesh (Advertising + Scanning + GATT Server)
  Future<bool> startMesh() async {
    await init();
    if (_adapter.isAndroid) {
      try {
        final hasPerm = await _adapter.hasPermissions();
        if (!hasPerm) {
          await _adapter.requestPermissions();
        }
      } catch (e) {
        debugPrint('[BLE MESH] Permission check error: $e');
      }
    }
    final ok = await _adapter.startMesh(deviceId: _deviceId);
    if (ok) {
      _isMeshRunning = true;

      // Start periodic internet synchronization timer (every 15 seconds)
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {        unawaited(syncPendingPackets());        unawaited(SosService().syncOfflineQueue());      });

      // If we have an active pending packet, immediately set it as GATT payload
      final pending = _storage.getPendingUploads();
      if (pending.isNotEmpty) {
        await _adapter.setMeshPayload(jsonEncode(pending.first.packet.toJson()));
      }

      _notifyListeners();
    }
    return ok;
  }

  /// Stop BLE Mesh operations
  Future<void> stopMesh() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    await _adapter.stopMesh();
    _isMeshRunning = false;
    _nearbyPeers.clear();
    _notifyListeners();
  }

  /// Create and broadcast an original SOS packet from this device (works 100% offline)
  Future<MeshPacketModel> broadcastLocalSos({
    required double latitude,
    required double longitude,
    required String emergencyType,
    required String notes,
    String severity = 'CRITICAL',
    int peopleCount = 1,
    List<String> vulnerabilities = const [],
    String? householdId,    String? idempotencyKey,
  }) async {
    await init();

    final packet = MeshPacketModel.createSOS(
      originDeviceId: _deviceId,
      latitude: latitude,
      longitude: longitude,
      severity: severity,
      peopleCount: peopleCount,
      vulnerabilities: vulnerabilities,
      householdId: householdId,
      notes: '$emergencyType | $notes',      customPacketId: idempotencyKey,
    );

    // 1. Persist locally in state PENDING
    await _storage.savePacket(packet, MeshPacketState.pending);

    // 2. Set as active BLE GATT Server payload and start advertising
    await _adapter.setMeshPayload(jsonEncode(packet.toJson()));
    if (!_isMeshRunning) {
      await startMesh();
    }

    _notifyListeners();

    // 3. Opportunistically attempt direct cloud sync if device currently has internet
    unawaited(_tryUploadPacket(packet));

    return packet;
  }

  /// Handle incoming packet received from a nearby BLE peer
  Future<void> _handleIncomingPacket(String rawJson, String sourceAddress) async {
    try {
      final jsonMap = jsonDecode(rawJson) as Map<String, dynamic>;
      final packet = MeshPacketModel.fromJson(jsonMap);

      // 1. Deduplication check: drop if already seen or processed
      if (_storage.hasSeenPacket(packet.packetId)) {
        debugPrint('[BLE MESH] Duplicate packet ${packet.packetId} dropped.');
        return;
      }

      // 2. Integrity and signature verification: drop if corrupted or tampered
      if (!packet.verifyIntegrity()) {
        debugPrint('[BLE MESH] Tampered packet ${packet.packetId} failed signature check. Dropped.');
        return;
      }

      // 3. Multi-hop relay validation (TTL > 1, no routing loop, not expired)
      if (!packet.canRelay(_deviceId)) {
        debugPrint('[BLE MESH] Packet ${packet.packetId} cannot be relayed (TTL=${packet.ttl}, Hops=${packet.hops}). Dropped.');
        return;
      }

      // 4. Accept & Persist in local store-and-forward queue
      await _storage.savePacket(packet, MeshPacketState.received);

      // 5. Create relayed copy with decremented TTL and appended hop trail
      final relayedPacket = packet.createRelayedCopy(_deviceId);
      await _storage.savePacket(relayedPacket, MeshPacketState.relayed);

      // 6. Advertise relayed packet to subsequent neighboring devices
      await _adapter.setMeshPayload(jsonEncode(relayedPacket.toJson()));

      debugPrint('[BLE MESH] Relayed packet ${relayedPacket.packetId}: TTL=${relayedPacket.ttl}, HopCount=${relayedPacket.hopCount}, Trail=${relayedPacket.hops.join(" -> ")}');

      if (packet.messageType == 'SOS') {
        _sosAlertController.add(packet);
      }

      _notifyListeners();

      // 7. If this relay node has an active Internet connection, upload immediately to cloud gateway!
      unawaited(_tryUploadPacket(relayedPacket));
    } catch (e) {
      debugPrint('[BLE MESH] Error parsing incoming packet: $e');
    }
  }

  /// Upload a single packet to FastAPI backend `POST /api/v1/mesh/packet`
  Future<bool> _tryUploadPacket(MeshPacketModel packet) async {
    try {
      final backendPayload = packet.toBackendJson();
      final res = await _apiClient.post(
        '/api/v1/mesh/packet',
        data: backendPayload,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        String? associatedSosCode;
        if (res.data is Map) {
          associatedSosCode = res.data['associated_sos_code'] as String?;
        }

        await _storage.updatePacketState(
          packet.packetId,
          MeshPacketState.uploaded,
          associatedSosCode: associatedSosCode,
        );

        _lastSyncTime = DateTime.now();
        _notifyListeners();
        debugPrint('[BLE MESH] Packet ${packet.packetId} successfully uploaded to cloud gateway. SOS Code: $associatedSosCode');
        return true;
      }
    } catch (e) {
      await _storage.incrementRetry(packet.packetId);
      debugPrint('[BLE MESH] Cloud upload deferred for ${packet.packetId}: Offline/Unreachable ($e)');
    }
    return false;
  }

  /// Sync all pending/received/relayed packets when internet is available
  Future<int> syncPendingPackets() async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    _notifyListeners();

    int successCount = 0;
    try {
      final pendingList = _storage.getPendingUploads();
      for (final record in pendingList) {
        final ok = await _tryUploadPacket(record.packet);
        if (ok) successCount++;
      }
    } finally {
      _isSyncing = false;
      _notifyListeners();
    }
    return successCount;
  }

  void _onBleEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    switch (type) {
      case 'PEER_DISCOVERED':
        final addr = event['address'] as String? ?? 'UNKNOWN';
        final name = event['name'] as String? ?? 'FIRE-EYE-PEER';
        final rssi = (event['rssi'] as num?)?.toInt() ?? -70;
        _nearbyPeers[addr] = DiscoveredBlePeer(
          address: addr,
          name: name,
          rssi: rssi,
          lastSeen: DateTime.now(),
        );
        _notifyListeners();
        break;

      case 'PACKET_RECEIVED':
        final rawJson = event['rawJson'] as String? ?? '';
        final src = event['sourceAddress'] as String? ?? 'UNKNOWN';
        if (rawJson.isNotEmpty) {
          _handleIncomingPacket(rawJson, src);
        }
        break;

      case 'MESH_STARTED':
        _isMeshRunning = true;
        _notifyListeners();
        break;

      case 'MESH_STOPPED':
        _isMeshRunning = false;
        _notifyListeners();
        break;
    }
  }

  /// Inject test packet for unit testing multi-hop logic without physical BLE hardware
  Future<void> testSimulateMultiHopRelay({
    required String testOriginId,
    required String emergencyType,
  }) async {
    final testPacket = MeshPacketModel.createSOS(
      originDeviceId: testOriginId,
      latitude: 30.3165,
      longitude: 78.0322,
      severity: 'CRITICAL',
      peopleCount: 2,
      vulnerabilities: ['🧓 Elderly / Disabled', '👶 Infants / Children'],
      notes: '$emergencyType | Multi-hop simulated relay test packet',
    );

    await _handleIncomingPacket(jsonEncode(testPacket.toJson()), 'SIMULATED-RADIO-MAC');
  }

  void dispose() {
    _syncTimer?.cancel();
    _bleEventSub?.cancel();
    _listeners.clear();
  }
}
