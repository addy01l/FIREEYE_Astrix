import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/providers/mesh_provider.dart';
import 'package:mobile_app/screens/mesh/mesh_status_screen.dart';
import 'package:mobile_app/services/mesh/mesh_manager.dart';
import 'package:mobile_app/services/mesh/mesh_packet_model.dart';
import 'package:mobile_app/services/mesh/mesh_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MeshStorageService.instance.clearAll();
  });

  tearDown(() {
    MeshManager.instance.dispose();
  });

  group('FIRE-EYE BLE Mesh Packet Protocol & Cryptographic Integrity', () {
    test('createSOS generates valid UUID, SHA-256 payload hash and HMAC-SHA256 signature', () {
      final packet = MeshPacketModel.createSOS(
        originDeviceId: 'FE-DEV-NODE-A',
        latitude: 30.3165,
        longitude: 78.0322,
        severity: 'CRITICAL',
        peopleCount: 3,
        vulnerabilities: ['👶 Infants / Children', '🧓 Elderly / Disabled'],
        notes: 'Trapped in building collapse',
      );

      expect(packet.packetId, isNotEmpty);
      expect(packet.originDeviceId, equals('FE-DEV-NODE-A'));
      expect(packet.ttl, equals(8));
      expect(packet.hopCount, equals(0));
      expect(packet.hops, equals(['FE-DEV-NODE-A']));
      expect(packet.payloadHash, isNotEmpty);
      expect(packet.authSignature, isNotEmpty);
      expect(packet.verifyIntegrity(), isTrue);
    });

    test('verifyIntegrity fails when packet payload has been tampered with', () {
      final original = MeshPacketModel.createSOS(
        originDeviceId: 'FE-DEV-NODE-A',
        latitude: 30.3165,
        longitude: 78.0322,
        severity: 'CRITICAL',
        peopleCount: 1,
        vulnerabilities: [],
      );

      expect(original.verifyIntegrity(), isTrue);

      // Create tampered version with altered latitude but forged/reused signature
      final tampered = MeshPacketModel(
        version: original.version,
        packetId: original.packetId,
        originDeviceId: original.originDeviceId,
        messageType: original.messageType,
        householdId: original.householdId,
        timestamp: original.timestamp,
        latitude: 35.0000, // Tampered location!
        longitude: original.longitude,
        severity: original.severity,
        peopleCount: original.peopleCount,
        vulnerabilities: original.vulnerabilities,
        batteryLevel: original.batteryLevel,
        notes: original.notes,
        ttl: original.ttl,
        hopCount: original.hopCount,
        hops: original.hops,
        payloadHash: original.payloadHash,
        authSignature: original.authSignature,
      );

      expect(tampered.verifyIntegrity(), isFalse);
    });

    test('isExpired detects stale packets older than 24 hours', () {
      final fresh = MeshPacketModel.createSOS(
        originDeviceId: 'FE-DEV-NODE-A',
        latitude: 30.3165,
        longitude: 78.0322,
        severity: 'CRITICAL',
        peopleCount: 1,
        vulnerabilities: [],
      );
      expect(fresh.isExpired(), isFalse);

      final staleTimestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - (86400 + 3600); // 25 hours ago
      final stale = MeshPacketModel(
        version: fresh.version,
        packetId: fresh.packetId,
        originDeviceId: fresh.originDeviceId,
        messageType: fresh.messageType,
        timestamp: staleTimestamp,
        latitude: fresh.latitude,
        longitude: fresh.longitude,
        severity: fresh.severity,
        peopleCount: fresh.peopleCount,
        vulnerabilities: fresh.vulnerabilities,
        batteryLevel: fresh.batteryLevel,
        notes: fresh.notes,
        ttl: fresh.ttl,
        hopCount: fresh.hopCount,
        hops: fresh.hops,
        payloadHash: fresh.payloadHash,
        authSignature: fresh.authSignature,
      );
      expect(stale.isExpired(), isTrue);
    });
  });

  group('FIRE-EYE Multi-Hop BLE Store-and-Forward Relay Logic', () {
    test('canRelay allows new peer to forward, decrements TTL, and prevents loops', () {
      final packet = MeshPacketModel.createSOS(
        originDeviceId: 'FE-NODE-A',
        latitude: 30.3165,
        longitude: 78.0322,
        severity: 'CRITICAL',
        peopleCount: 2,
        vulnerabilities: ['🧓 Elderly'],
      );

      // Node B can relay it
      expect(packet.canRelay('FE-NODE-B'), isTrue);

      // Node A (origin) cannot relay again (routing loop prevention)
      expect(packet.canRelay('FE-NODE-A'), isFalse);

      // Node B creates relayed copy
      final relayed1 = packet.createRelayedCopy('FE-NODE-B');
      expect(relayed1.ttl, equals(7));
      expect(relayed1.hopCount, equals(1));
      expect(relayed1.hops, equals(['FE-NODE-A', 'FE-NODE-B']));
      expect(relayed1.verifyIntegrity(), isTrue);

      // Node C can relay the packet from Node B
      expect(relayed1.canRelay('FE-NODE-C'), isTrue);
      // But Node B cannot relay again
      expect(relayed1.canRelay('FE-NODE-B'), isFalse);

      // Node C creates second relayed copy
      final relayed2 = relayed1.createRelayedCopy('FE-NODE-C');
      expect(relayed2.ttl, equals(6));
      expect(relayed2.hopCount, equals(2));
      expect(relayed2.hops, equals(['FE-NODE-A', 'FE-NODE-B', 'FE-NODE-C']));
      expect(relayed2.verifyIntegrity(), isTrue);
    });

    test('canRelay drops packet when TTL reaches 1 or 0', () {
      final exhaustedPacket = MeshPacketModel(
        version: 'v1.0',
        packetId: 'EXHAUSTED-01',
        originDeviceId: 'FE-NODE-A',
        messageType: 'SOS',
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        latitude: 30.3165,
        longitude: 78.0322,
        severity: 'CRITICAL',
        peopleCount: 1,
        vulnerabilities: [],
        batteryLevel: 90,
        notes: '',
        ttl: 1, // Final hop, cannot be relayed further
        hopCount: 7,
        hops: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
        payloadHash: '',
        authSignature: '',
      );

      expect(exhaustedPacket.canRelay('FE-NODE-H'), isFalse);
    });

    test('toBackendJson outputs format required by POST /api/v1/mesh/packet', () {
      final packet = MeshPacketModel.createSOS(
        originDeviceId: 'FE-NODE-A',
        latitude: 30.3165,
        longitude: 78.0322,
        severity: 'CRITICAL',
        peopleCount: 4,
        vulnerabilities: ['👶 Infants'],
        householdId: 'HH-101',
      );

      final backendJson = packet.toBackendJson();
      expect(backendJson['message_id'], equals(packet.packetId));
      expect(backendJson['sender_id'], equals('FE-NODE-A'));
      expect(backendJson['type'], equals('SOS'));
      expect(backendJson['household_id'], equals('HH-101'));
      expect(backendJson['latitude'], equals(30.3165));
      expect(backendJson['longitude'], equals(78.0322));
      expect(backendJson['severity'], equals('CRITICAL'));
      expect(backendJson['ttl'], equals(8));
      expect(backendJson['hops'], equals(['FE-NODE-A']));
      expect(backendJson['payload'], isA<Map<String, dynamic>>());
      expect((backendJson['payload'] as Map)['people_count'], equals(4));
    });
  });

  group('FIRE-EYE Local Persistent Store-and-Forward Storage & Deduplication', () {
    test('MeshStorageService prevents duplicate packets and tracks state lifecycle', () async {
      final storage = MeshStorageService.instance;
      await storage.init();

      final packet = MeshPacketModel.createSOS(
        originDeviceId: 'FE-NODE-A',
        latitude: 30.3165,
        longitude: 78.0322,
        severity: 'CRITICAL',
        peopleCount: 1,
        vulnerabilities: [],
      );

      // First save
      final saved1 = await storage.savePacket(packet, MeshPacketState.pending);
      expect(saved1, isTrue);
      expect(storage.hasSeenPacket(packet.packetId), isTrue);
      expect(storage.pendingCount, equals(1));

      // Attempt duplicate save of same packet
      final saved2 = await storage.savePacket(packet, MeshPacketState.received);
      expect(saved2, isFalse); // Rejected as duplicate
      expect(storage.pendingCount, equals(1));

      // State transition: PENDING -> UPLOADED
      await storage.updatePacketState(
        packet.packetId,
        MeshPacketState.uploaded,
        associatedSosCode: 'SOS-MESH-ABC123',
      );

      final updated = storage.getRecord(packet.packetId);
      expect(updated?.state, equals(MeshPacketState.uploaded));
      expect(updated?.associatedSosCode, equals('SOS-MESH-ABC123'));
      expect(storage.uploadedCount, equals(1));
      expect(storage.pendingCount, equals(0));
    });
  });

  group('FIRE-EYE Mesh Status UI Widget Tests', () {
    testWidgets('MeshStatusScreen displays Bluetooth node identity, stats and queue', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MeshProvider()),
          ],
          child: const MaterialApp(
            home: MeshStatusScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and UI components
      expect(find.text('BLUETOOTH MESH RELAY'), findsOneWidget);
      expect(find.text('Pending SOS'), findsOneWidget);
      expect(find.text('Received Packets'), findsOneWidget);
      expect(find.text('Relayed Multi-Hop'), findsOneWidget);
      expect(find.text('Cloud Uploaded'), findsOneWidget);
      expect(find.textContaining('NEARBY BLE RELAY PEERS'), findsOneWidget);
      expect(find.textContaining('STORE-AND-FORWARD PACKET QUEUE'), findsOneWidget);
    });
  });
}
