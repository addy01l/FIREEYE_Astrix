import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/websocket_service.dart';

import '../models/alert_model.dart';

import '../services/mesh/mesh_manager.dart';



class AlertProvider extends ChangeNotifier {

  final WebSocketService _wsService = WebSocketService();

  StreamSubscription? _sub;

  StreamSubscription? _meshAlertSub;



  final List<AlertModel> _alerts = [

    AlertModel(

      id: 'ALT-101',

      title: 'CHEMICAL HAZARD BULLETIN',

      message: 'Active thermal plume detected at Selaqui corridor. Upwind evacuation advised.',

      severity: 'CRITICAL',

      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),

      latitude: 30.3662,

      longitude: 77.9221,

    ),

    AlertModel(

      id: 'ALT-102',

      title: 'SLOPE MOVEMENT ADVISORY',

      message: 'Monsoon debris hazard on Rajpur Road bypass. Traffic diverted to Sector 2.',

      severity: 'WARNING',

      timestamp: DateTime.now().subtract(const Duration(minutes: 42)),

      latitude: 30.3842,

      longitude: 78.0754,

    ),

  ];



  int _unreadCount = 2;



  List<AlertModel> get alerts => _alerts;

  int get unreadCount => _unreadCount;

  ValueNotifier<WsConnectionState> get wsState => _wsService.connectionState;



  AlertProvider() {

    _initWebSocket();

    _initMeshAlerts();

  }



  void _initMeshAlerts() {

    _meshAlertSub = MeshManager.instance.onSosAlertReceived.listen((packet) {

      final alertId = packet.packetId.length > 8 ? packet.packetId.substring(0, 8) : packet.packetId;

      final alert = AlertModel(

        id: 'ALT-$alertId',

        title: '🚨 OFFLINE BLE SOS RELAY RECEIVED',

        message: '${packet.notes} • Stranded: ${packet.peopleCount} • Hop: ${packet.hopCount}',

        severity: 'CRITICAL',

        timestamp: DateTime.fromMillisecondsSinceEpoch(packet.timestamp),

        latitude: packet.latitude,

        longitude: packet.longitude,

        isLiveWebSocket: false,

      );

      _alerts.insert(0, alert);

      _unreadCount++;

      notifyListeners();

    });

  }



  void _initWebSocket() {

    _wsService.connect();

    _sub = _wsService.alertStream.listen((data) {

      final alert = AlertModel.fromWebSocket(data);

      _alerts.insert(0, alert);

      _unreadCount++;

      notifyListeners();

    });

  }



  void markAllRead() {

    _unreadCount = 0;

    notifyListeners();

  }



  void dismissAlert(String id) {

    _alerts.removeWhere((a) => a.id == id);

    if (_unreadCount > _alerts.length) {

      _unreadCount = _alerts.length;

    }

    notifyListeners();

  }



  void clearAlerts() {

    _alerts.clear();

    _unreadCount = 0;

    notifyListeners();

  }



  void reconnectWs() {

    _wsService.connect();

  }



  @override

  void dispose() {

    _sub?.cancel();
    _meshAlertSub?.cancel();

    super.dispose();

  }

}

