import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DiscoveredBlePeer {
  final String address;
  final String name;
  final int rssi;
  final DateTime lastSeen;

  DiscoveredBlePeer({
    required this.address,
    required this.name,
    required this.rssi,
    required this.lastSeen,
  });
}

class BleMeshAdapter {
  static const MethodChannel _methodChannel = MethodChannel('com.fireeye.app/ble_mesh');
  static const EventChannel _eventChannel = EventChannel('com.fireeye.app/ble_mesh_events');

  final StreamController<Map<String, dynamic>> _eventStreamController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get events => _eventStreamController.stream;

  StreamSubscription? _nativeSubscription;
  bool _isListening = false;

  static final BleMeshAdapter instance = BleMeshAdapter._internal();
  BleMeshAdapter._internal();

  bool get isAndroid {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  void initEventStream() {
    if (_isListening || !isAndroid) return;
    try {
      _nativeSubscription = _eventChannel.receiveBroadcastStream().listen(
        (event) {
          if (event is Map) {
            _eventStreamController.add(Map<String, dynamic>.from(event));
          }
        },
        onError: (err) {
          _eventStreamController.add({'type': 'ERROR', 'message': err.toString()});
        },
      );
      _isListening = true;
    } catch (e) {
      debugPrint('[BLE MESH ADAPTER] Native event channel unavailable: $e');
    }
  }

  Future<bool> isSupported() async {
    if (!isAndroid) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('isSupported');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    if (!isAndroid) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('isBluetoothEnabled');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPermissions() async {
    if (!isAndroid) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('hasPermissions');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    if (!isAndroid) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('requestPermissions');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startMesh({
    required String deviceId,
    String? initialPayload,
  }) async {
    initEventStream();
    if (!isAndroid) {
      _eventStreamController.add({'type': 'ERROR', 'message': 'BLE mesh transport is implemented for Android only.'});
      return false;
    }

    try {
      final res = await _methodChannel.invokeMethod<bool>('startMesh', {
        'deviceId': deviceId,
        'payload': initialPayload,
      });
      return res ?? false;
    } catch (e) {
      _eventStreamController.add({'type': 'ERROR', 'message': e.toString()});
      return false;
    }
  }

  Future<bool> stopMesh() async {
    if (!isAndroid) {
      _eventStreamController.add({'type': 'MESH_STOPPED'});
      return true;
    }

    try {
      final res = await _methodChannel.invokeMethod<bool>('stopMesh');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setMeshPayload(String payloadJson) async {
    if (!isAndroid) return true;
    try {
      final res = await _methodChannel.invokeMethod<bool>('setMeshPayload', {
        'payload': payloadJson,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getMeshStats() async {
    if (!isAndroid) {
      return {
        'isMeshActive': false,
        'isAdvertising': false,
        'isScanning': false,
        'discoveredPeersCount': 0,
        'connectedClientsCount': 0,
      };
    }

    try {
      final res = await _methodChannel.invokeMethod<Map>('getMeshStats');
      return Map<String, dynamic>.from(res ?? {});
    } catch (_) {
      return {};
    }
  }

  /// Inject event for unit testing or multi-hop simulated verification
  void simulateIncomingPacket(String rawJson, {String sourceAddress = 'TEST-PEER-01'}) {
    _eventStreamController.add({
      'type': 'PACKET_RECEIVED',
      'sourceAddress': sourceAddress,
      'rawJson': rawJson,
    });
  }

  void simulatePeerDiscovered({
    required String address,
    required String name,
    required int rssi,
  }) {
    _eventStreamController.add({
      'type': 'PEER_DISCOVERED',
      'address': address,
      'name': name,
      'rssi': rssi,
    });
  }

  void dispose() {
    _nativeSubscription?.cancel();
    _eventStreamController.close();
  }
}

