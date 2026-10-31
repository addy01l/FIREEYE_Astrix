import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Base host configuration
  /// Priority:
  /// 1. Compile-time --dart-define=BACKEND_BASE_URL=https://your-service.onrender.com
  /// 2. Android emulator: http://10.0.2.2:8000
  /// 3. Windows desktop: http://127.0.0.1:8000
  /// 4. Web: http://localhost:8000
  /// 5. Physical device: user-configurable in Profile & Settings screen
  static String get defaultBaseUrl {
    const envUrl = String.fromEnvironment('BACKEND_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl.replaceAll(RegExp(r'/$'), '');
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
      if (Platform.isWindows) return 'http://127.0.0.1:8000';
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  static String baseUrl = defaultBaseUrl;

  static void setBaseUrl(String url) {
    baseUrl = url.replaceAll(RegExp(r'/$'), '');
  }

  static String get healthEndpoint => '$baseUrl/health';
  static String get apiBasePath => '$baseUrl/api/v1';

  // Verified WebSocket endpoint
  static String get wsAlertsEndpoint {
    final host = baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    return '$host/api/v1/ws/';
  }

  static String get wsAlertsUrl => wsAlertsEndpoint;

  static String get loginEndpoint => '/api/v1/auth/login';
  static String get registerEndpoint => '/api/v1/auth/register';
  static String get meEndpoint => '/api/v1/auth/me';
  static String get zonesEndpoint => '/api/v1/disaster/zones';
  static String get incidentsEndpoint => zonesEndpoint;
  static String get sheltersEndpoint => '/api/v1/shelters/';
  static String get householdsEndpoint => '/api/v1/households/';
  static String get sosEndpoint => '/api/v1/sos/';
  static String get activeSosEndpoint => '/api/v1/sos/active';
  static String get priorityQueueEndpoint => '/api/v1/priority/queue';
  static String get routingEndpoint => '/api/v1/routing/safe-route';
  static String get rescueCentersEndpoint => sheltersEndpoint;
  static String get victimsEndpoint => priorityQueueEndpoint;
}
