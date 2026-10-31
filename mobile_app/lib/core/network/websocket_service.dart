import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

enum WsConnectionState { disconnected, connecting, connected, error }

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _alertsController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get alertStream => _alertsController.stream;

  final ValueNotifier<WsConnectionState> connectionState = ValueNotifier(WsConnectionState.disconnected);
  bool _isDisposed = false;
  Timer? _reconnectTimer;

  void connect() {
    if (_isDisposed) return;
    if (connectionState.value == WsConnectionState.connected ||
        connectionState.value == WsConnectionState.connecting) {
      return;
    }

    final url = ApiConfig.wsAlertsEndpoint;
    connectionState.value = WsConnectionState.connecting;

    try {
      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (data) {
          if (connectionState.value != WsConnectionState.connected) {
            connectionState.value = WsConnectionState.connected;
          }
          try {
            final parsed = jsonDecode(data.toString());
            if (parsed is Map<String, dynamic>) {
              _alertsController.add(parsed);
            }
          } catch (_) {}
        },
        onDone: () {
          connectionState.value = WsConnectionState.disconnected;
          _scheduleReconnect();
        },
        onError: (err) {
          connectionState.value = WsConnectionState.error;
          _scheduleReconnect();
        },
      );
    } catch (_) {
      connectionState.value = WsConnectionState.error;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isDisposed && connectionState.value != WsConnectionState.connected) {
        connect();
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    connectionState.value = WsConnectionState.disconnected;
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _alertsController.close();
  }
}

