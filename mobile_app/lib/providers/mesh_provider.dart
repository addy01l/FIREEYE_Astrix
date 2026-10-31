import 'package:flutter/foundation.dart';
import '../services/mesh/ble_mesh_adapter.dart';
import '../services/mesh/mesh_manager.dart';
import '../services/mesh/mesh_packet_model.dart';
import '../services/mesh/mesh_storage_service.dart';

class MeshProvider extends ChangeNotifier {
  final MeshManager _manager = MeshManager.instance;
  bool _initialized = false;

  MeshProvider() {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _manager.addListener(_onManagerUpdated);
    await _manager.init();
    _initialized = true;
    notifyListeners();
  }

  void _onManagerUpdated() {
    notifyListeners();
  }

  bool get isMeshRunning => _manager.isMeshRunning;
  String get deviceId => _manager.deviceId;
  bool get isSyncing => _manager.isSyncing;
  DateTime? get lastSyncTime => _manager.lastSyncTime;
  List<DiscoveredBlePeer> get nearbyPeers => _manager.nearbyPeers;

  int get pendingCount => _manager.storage.pendingCount;
  int get receivedCount => _manager.storage.receivedCount;
  int get relayedCount => _manager.storage.relayedCount;
  int get uploadedCount => _manager.storage.uploadedCount;

  List<MeshPacketRecord> get packetRecords => _manager.storage.getAllRecords();

  Future<bool> toggleMesh() async {
    if (_manager.isMeshRunning) {
      await _manager.stopMesh();
      return false;
    } else {
      return await _manager.startMesh();
    }
  }

  Future<int> syncNow() async {
    return await _manager.syncPendingPackets();
  }

  Future<MeshPacketModel> broadcastSos({
    required double latitude,
    required double longitude,
    required String emergencyType,
    required String notes,
    String severity = 'CRITICAL',
    int peopleCount = 1,
    List<String> vulnerabilities = const [],
  }) async {
    return await _manager.broadcastLocalSos(
      latitude: latitude,
      longitude: longitude,
      emergencyType: emergencyType,
      notes: notes,
      severity: severity,
      peopleCount: peopleCount,
      vulnerabilities: vulnerabilities,
    );
  }

  Future<void> testSimulateMultiHopRelay({
    required String testOriginId,
    required String emergencyType,
  }) async {
    await _manager.testSimulateMultiHopRelay(
      testOriginId: testOriginId,
      emergencyType: emergencyType,
    );
  }

  @override
  void dispose() {
    _manager.removeListener(_onManagerUpdated);
    super.dispose();
  }
}

