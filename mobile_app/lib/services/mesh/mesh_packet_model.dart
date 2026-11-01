import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

enum MeshPacketState {
  pending,
  received,
  relayed,
  uploaded,
  acknowledged,
  failed,
}

class MeshPacketModel {
  static const String currentProtocolVersion = 'v1.0';
  static const String networkSharedKey = String.fromEnvironment(
    'MESH_HMAC_KEY',
    defaultValue: 'fire-eye-mesh-hmac-sha256-default-key-32b',
  );
  static const int defaultInitialTtl = 8;
  static const int maxMessageAgeSeconds = 86400; // 24 hours

  final String version;
  final String packetId;
  final String originDeviceId;
  final String messageType;
  final String? householdId;
  final int timestamp; // Unix epoch seconds
  final double latitude;
  final double longitude;
  final String severity;
  final int peopleCount;
  final List<String> vulnerabilities;
  final int batteryLevel;
  final String notes;

  // Mutable multi-hop relay routing metadata
  final int ttl;
  final int hopCount;
  final List<String> hops;

  // Cryptographic integrity & anti-tampering
  final String payloadHash;
  final String authSignature;

  const MeshPacketModel({
    required this.version,
    required this.packetId,
    required this.originDeviceId,
    required this.messageType,
    this.householdId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.peopleCount,
    required this.vulnerabilities,
    required this.batteryLevel,
    required this.notes,
    required this.ttl,
    required this.hopCount,
    required this.hops,
    required this.payloadHash,
    required this.authSignature,
  });

  /// Factory to generate a fresh original SOS packet created by this device.
  factory MeshPacketModel.createSOS({
    required String originDeviceId,
    required double latitude,
    required double longitude,
    required String severity,
    required int peopleCount,
    required List<String> vulnerabilities,
    String? householdId,
    String notes = '',
    int batteryLevel = 100,
    String? customPacketId,
  }) {
    if (networkSharedKey.length < 32) {
      throw StateError('MESH_HMAC_KEY must be provisioned with at least 32 characters before BLE SOS can be broadcast.');
    }
    final packetId = customPacketId ?? const Uuid().v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Calculate cryptographic SHA-256 hash of immutable fields
    final payloadHash = _computeHash(
      packetId: packetId,
      originDeviceId: originDeviceId,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      severity: severity,
      peopleCount: peopleCount,
    );

    // Calculate HMAC-SHA256 signature
    final signature = _computeSignature(payloadHash);

    return MeshPacketModel(
      version: currentProtocolVersion,
      packetId: packetId,
      originDeviceId: originDeviceId,
      messageType: 'SOS',
      householdId: householdId ?? 'HH-${originDeviceId.substring(0, originDeviceId.length.clamp(0, 8))}',
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      severity: severity,
      peopleCount: peopleCount,
      vulnerabilities: vulnerabilities,
      batteryLevel: batteryLevel,
      notes: notes,
      ttl: defaultInitialTtl,
      hopCount: 0,
      hops: [originDeviceId],
      payloadHash: payloadHash,
      authSignature: signature,
    );
  }

  /// Verifies payload hash and HMAC signature. Returns false if tampered.
  bool verifyIntegrity() {
    final expectedHash = _computeHash(
      packetId: packetId,
      originDeviceId: originDeviceId,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      severity: severity,
      peopleCount: peopleCount,
    );

    if (expectedHash != payloadHash) {
      return false;
    }

    final expectedSignature = _computeSignature(payloadHash);
    return expectedSignature == authSignature;
  }

  /// Checks if message exceeds maximum allowed TTL age (replay/stale prevention)
  bool isExpired({int maxAgeSeconds = maxMessageAgeSeconds}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (timestamp > now + 300) {
      // Message claims to be from > 5 minutes into the future
      return true;
    }
    return (now - timestamp) > maxAgeSeconds;
  }

  /// Checks if this packet can be safely forwarded by the current device
  bool canRelay(String currentDeviceId) {
    // 1. Must have remaining TTL
    if (ttl <= 1) return false;

    // 2. Loop prevention: do not relay if this device already forwarded it
    if (hops.contains(currentDeviceId)) return false;

    // 3. Expiry check
    if (isExpired()) return false;

    // 4. Cryptographic integrity check
    if (!verifyIntegrity()) return false;

    return true;
  }

  /// Creates a relayed copy with decremented TTL and appended hop trail
  MeshPacketModel createRelayedCopy(String currentDeviceId) {
    final updatedHops = List<String>.from(hops)..add(currentDeviceId);
    return MeshPacketModel(
      version: version,
      packetId: packetId,
      originDeviceId: originDeviceId,
      messageType: messageType,
      householdId: householdId,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      severity: severity,
      peopleCount: peopleCount,
      vulnerabilities: vulnerabilities,
      batteryLevel: batteryLevel,
      notes: notes,
      ttl: ttl - 1,
      hopCount: hopCount + 1,
      hops: updatedHops,
      payloadHash: payloadHash,
      authSignature: authSignature,
    );
  }

  /// Converts to format expected by backend endpoint `POST /api/v1/mesh/packet`
  Map<String, dynamic> toBackendJson() {
    return {
      'message_id': packetId,
      'sender_id': originDeviceId,
      'type': messageType,
      'household_id': householdId ?? 'HH-MOBILE',
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity,
      'timestamp': timestamp,
      'ttl': ttl,
      'hops': hops,
      'payload': {
        'vulnerabilities': vulnerabilities,
        'people_count': peopleCount,
        'battery_level': batteryLevel,
      },
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'packet_id': packetId,
      'origin_device_id': originDeviceId,
      'message_type': messageType,
      'household_id': householdId,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'severity': severity,
      'people_count': peopleCount,
      'vulnerabilities': vulnerabilities,
      'battery_level': batteryLevel,
      'notes': notes,
      'ttl': ttl,
      'hop_count': hopCount,
      'hops': hops,
      'payload_hash': payloadHash,
      'auth_signature': authSignature,
    };
  }

  factory MeshPacketModel.fromJson(Map<String, dynamic> json) {
    return MeshPacketModel(
      version: json['version'] as String? ?? 'v1.0',
      packetId: json['packet_id'] as String? ?? json['message_id'] as String,
      originDeviceId: json['origin_device_id'] as String? ?? json['sender_id'] as String? ?? 'DEV-UNKNOWN',
      messageType: json['message_type'] as String? ?? json['type'] as String? ?? 'SOS',
      householdId: json['household_id'] as String?,
      timestamp: (json['timestamp'] as num?)?.toInt() ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? 'CRITICAL',
      peopleCount: (json['people_count'] as num?)?.toInt() ?? 1,
      vulnerabilities: (json['vulnerabilities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (json['payload'] is Map && (json['payload'] as Map)['vulnerabilities'] is List
              ? ((json['payload'] as Map)['vulnerabilities'] as List).map((e) => e.toString()).toList()
              : <String>[]),
      batteryLevel: (json['battery_level'] as num?)?.toInt() ?? 100,
      notes: json['notes'] as String? ?? '',
      ttl: (json['ttl'] as num?)?.toInt() ?? 8,
      hopCount: (json['hop_count'] as num?)?.toInt() ?? ((json['hops'] as List?)?.length ?? 0),
      hops: (json['hops'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      payloadHash: json['payload_hash'] as String? ?? '',
      authSignature: json['auth_signature'] as String? ?? '',
    );
  }

  static String _computeHash({
    required String packetId,
    required String originDeviceId,
    required int timestamp,
    required double latitude,
    required double longitude,
    required String severity,
    required int peopleCount,
  }) {
    final raw = '$packetId|$originDeviceId|$timestamp|${latitude.toStringAsFixed(5)}|${longitude.toStringAsFixed(5)}|$severity|$peopleCount';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  static String _computeSignature(String payloadHash) {
    final key = utf8.encode(networkSharedKey);
    final bytes = utf8.encode(payloadHash);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }
}

