import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'mesh_packet_model.dart';

class MeshPacketRecord {
  final MeshPacketModel packet;
  MeshPacketState state;
  final DateTime storedAt;
  DateTime? lastAttemptAt;
  int retryCount;
  String? associatedSosCode;

  MeshPacketRecord({
    required this.packet,
    required this.state,
    required this.storedAt,
    this.lastAttemptAt,
    this.retryCount = 0,
    this.associatedSosCode,
  });

  Map<String, dynamic> toJson() => {
        'packet': packet.toJson(),
        'state': state.name,
        'stored_at': storedAt.toIso8601String(),
        'last_attempt_at': lastAttemptAt?.toIso8601String(),
        'retry_count': retryCount,
        'associated_sos_code': associatedSosCode,
      };

  factory MeshPacketRecord.fromJson(Map<String, dynamic> json) {
    return MeshPacketRecord(
      packet: MeshPacketModel.fromJson(json['packet'] as Map<String, dynamic>),
      state: MeshPacketState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => MeshPacketState.pending,
      ),
      storedAt: DateTime.tryParse(json['stored_at'] as String? ?? '') ?? DateTime.now(),
      lastAttemptAt: json['last_attempt_at'] != null ? DateTime.tryParse(json['last_attempt_at'] as String) : null,
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      associatedSosCode: json['associated_sos_code'] as String?,
    );
  }
}

class MeshStorageService {
  static const String _queueKey = 'fireeye_mesh_queue_v1';
  static const String _seenKey = 'fireeye_mesh_seen_v1';

  final Map<String, MeshPacketRecord> _records = {};
  final Set<String> _seenPacketIds = {};
  bool _initialized = false;

  static final MeshStorageService instance = MeshStorageService._internal();
  MeshStorageService._internal();

  Future<void> init() async {
    if (_initialized) return;
    try {
      final sp = await SharedPreferences.getInstance();

      // Load seen packet IDs for duplicate prevention
      final seenList = sp.getStringList(_seenKey) ?? [];
      _seenPacketIds.addAll(seenList);

      // Load persisted store-and-forward queue
      final queueRaw = sp.getStringList(_queueKey) ?? [];
      for (final raw in queueRaw) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final record = MeshPacketRecord.fromJson(map);
          _records[record.packet.packetId] = record;
          _seenPacketIds.add(record.packet.packetId);
        } catch (_) {}
      }
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  /// O(1) duplicate check
  bool hasSeenPacket(String packetId) {
    return _seenPacketIds.contains(packetId);
  }

  /// Store packet in queue and register its ID to avoid loops/dups
  Future<bool> savePacket(MeshPacketModel packet, MeshPacketState state) async {
    await init();

    if (_records.containsKey(packet.packetId)) {
      // Packet already in queue; update routing trail if hopCount is lower
      final existing = _records[packet.packetId]!;
      if (packet.hopCount < existing.packet.hopCount) {
        _records[packet.packetId] = MeshPacketRecord(
          packet: packet,
          state: state,
          storedAt: existing.storedAt,
          retryCount: existing.retryCount,
          associatedSosCode: existing.associatedSosCode,
        );
        await _persist();
        return true;
      }
      return false; // Duplicate
    }

    // Add to seen registry and records
    _seenPacketIds.add(packet.packetId);
    _records[packet.packetId] = MeshPacketRecord(
      packet: packet,
      state: state,
      storedAt: DateTime.now(),
    );

    await _persist();
    return true;
  }

  Future<void> updatePacketState(
    String packetId,
    MeshPacketState newState, {
    String? associatedSosCode,
  }) async {
    await init();
    final rec = _records[packetId];
    if (rec != null) {
      rec.state = newState;
      rec.lastAttemptAt = DateTime.now();
      if (associatedSosCode != null) {
        rec.associatedSosCode = associatedSosCode;
      }
      await _persist();
    }
  }

  Future<void> incrementRetry(String packetId) async {
    await init();
    final rec = _records[packetId];
    if (rec != null) {
      rec.retryCount++;
      rec.lastAttemptAt = DateTime.now();
      await _persist();
    }
  }

  List<MeshPacketRecord> getAllRecords() {
    final list = _records.values.toList();
    list.sort((a, b) => b.storedAt.compareTo(a.storedAt));
    return list;
  }

  List<MeshPacketRecord> getPendingUploads() {
    return _records.values
        .where((r) =>
            r.state == MeshPacketState.pending ||
            r.state == MeshPacketState.received ||
            r.state == MeshPacketState.relayed)
        .toList();
  }

  MeshPacketRecord? getRecord(String packetId) => _records[packetId];

  int get pendingCount => _records.values.where((r) => r.state == MeshPacketState.pending).length;
  int get receivedCount => _records.values.where((r) => r.state == MeshPacketState.received).length;
  int get relayedCount => _records.values.where((r) => r.state == MeshPacketState.relayed).length;
  int get uploadedCount => _records.values.where((r) => r.state == MeshPacketState.uploaded || r.state == MeshPacketState.acknowledged).length;

  Future<void> clearAll() async {
    _records.clear();
    _seenPacketIds.clear();
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_queueKey);
    await sp.remove(_seenKey);
  }

  Future<void> _persist() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final serializedQueue = _records.values.map((r) => jsonEncode(r.toJson())).toList();
      await sp.setStringList(_queueKey, serializedQueue);
      await sp.setStringList(_seenKey, _seenPacketIds.toList());
    } catch (_) {}
  }
}

