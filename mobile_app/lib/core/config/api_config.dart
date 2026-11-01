class ApiConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xwiwmwgyayqyhkfiinnv.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3aXdtd2d5YXlxeWhrZmlpbm52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0NTQwMTksImV4cCI6MjEwOTAzMDAxOX0.kOdGBwpIx0qUgHAp2tAwRNsOrTy9NULNbtdbKHDkrjI',
  );
  static bool get hasSupabaseConfig => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Base host configuration
  /// Priority:
  /// 1. Compile-time: --dart-define=BACKEND_BASE_URL=https://hackathon-1-cs4a.onrender.com
  /// 2. Live production default: https://hackathon-1-cs4a.onrender.com
  /// 3. Runtime configuration via Profile & Settings screen
  static const String liveProductionUrl = 'https://hackathon-1-cs4a.onrender.com';

  static String get defaultBaseUrl {
    const envUrl = String.fromEnvironment('BACKEND_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl.replaceAll(RegExp(r'/$'), '');
    return liveProductionUrl;
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
  static String get mySosEndpoint => '/api/v1/sos/my';
  static String get usersEndpoint => '/api/v1/users/';
  static String get priorityQueueEndpoint => '/api/v1/priority/queue';
  static String get routingEndpoint => '/api/v1/routing/safe-route';
  static String get rescueCentersEndpoint => sheltersEndpoint;
  static String get victimsEndpoint => priorityQueueEndpoint;
}
