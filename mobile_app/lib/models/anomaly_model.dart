class AnomalyModel {
  final int id;
  final double latitude;
  final double longitude;
  final double brightness;
  final double frp;
  final bool isWildfire;

  AnomalyModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.brightness,
    required this.frp,
    required this.isWildfire,
  });

  factory AnomalyModel.fromJson(Map<String, dynamic> json) {
    return AnomalyModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      frp: (json['frp'] as num?)?.toDouble() ?? 0.0,
      isWildfire: json['is_wildfire'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'brightness': brightness,
      'frp': frp,
      'is_wildfire': isWildfire,
    };
  }
}

