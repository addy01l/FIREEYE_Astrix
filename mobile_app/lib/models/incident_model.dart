class IncidentModel {
  final String id;
  final String title;
  final String type; // Industrial Fire, Wildfire, Landslide, Flash Flood, Structural Collapse
  final String severity; // CRITICAL, WARNING, WATCH, SAFE
  final String status; // ACTIVE, DISPATCHED, RESOLVED
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String description;
  final String locationName;
  final String source; // NASA FIRMS, Field Alert, Operator Report
  final double? frp;
  final double? brightness;
  final bool isLiveAnomaly;

  IncidentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.severity,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.description,
    required this.locationName,
    this.source = 'NASA FIRMS VIIRS',
    this.frp,
    this.brightness,
    this.isLiveAnomaly = false,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    final latitude = json['latitude'] as num?;
    final longitude = json['longitude'] as num?;
    final timestamp = DateTime.tryParse(
      (json['timestamp'] ?? json['reported_at'] ?? json['created_at'])?.toString() ?? '',
    );
    if (json['id'] == null || latitude == null || longitude == null || timestamp == null) {
      throw const FormatException('Incident record is missing its ID, coordinates, or timestamp');
    }
    return IncidentModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      severity: (json['severity'] as String? ?? 'UNKNOWN').toUpperCase(),
      status: (json['status'] as String? ?? 'UNKNOWN').toUpperCase(),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      timestamp: timestamp,
      description: json['description'] as String? ?? '',
      locationName: json['location_name'] as String? ?? '',
      source: json['source'] as String? ?? 'Unknown source',
      frp: (json['frp'] as num?)?.toDouble(),
      brightness: (json['brightness'] as num?)?.toDouble(),
      isLiveAnomaly: json['is_live_anomaly'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'severity': severity,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'location_name': locationName,
      'source': source,
      'frp': frp,
      'brightness': brightness,
    };
  }

  IncidentModel copyWith({
    String? status,
    String? severity,
    String? description,
  }) {
    return IncidentModel(
      id: id,
      title: title,
      type: type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      description: description ?? this.description,
      locationName: locationName,
      source: source,
      frp: frp,
      brightness: brightness,
      isLiveAnomaly: isLiveAnomaly,
    );
  }
}

