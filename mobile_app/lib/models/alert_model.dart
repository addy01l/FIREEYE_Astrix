class AlertModel {
  final String id;
  final String title;
  final String message;
  final String severity; // CRITICAL, WARNING, INFO
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final bool isLiveWebSocket;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.isLiveWebSocket = false,
  });

  factory AlertModel.fromWebSocket(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final lat = (data['latitude'] as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();
    final isWildfire = data['is_wildfire'] == true;
    final conf = data['confidence']?.toString() ?? 'high';

    return AlertModel(
      id: 'WS-${DateTime.now().millisecondsSinceEpoch}',
      title: isWildfire ? 'CRITICAL THERMAL ANOMALY' : 'THERMAL HOTSPOT ALERT',
      message: 'Sensor detected anomaly at (${lat?.toStringAsFixed(4)}, ${lng?.toStringAsFixed(4)}) with $conf confidence.',
      severity: isWildfire ? 'CRITICAL' : 'WARNING',
      timestamp: DateTime.now(),
      latitude: lat,
      longitude: lng,
      isLiveWebSocket: true,
    );
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id']?.toString() ?? 'ALT-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Disaster Alert',
      message: json['message'] as String? ?? '',
      severity: (json['severity'] as String? ?? 'INFO').toUpperCase(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isLiveWebSocket: json['is_live_websocket'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'is_live_websocket': isLiveWebSocket,
    };
  }
}

