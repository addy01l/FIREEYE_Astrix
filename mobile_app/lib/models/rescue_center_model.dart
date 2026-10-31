class RescueCenterModel {
  final String id;
  final String name;
  final String stationUnit;
  final String location;
  final double latitude;
  final double longitude;
  final String contactPhone;
  final int activePersonnel;
  final int availableVehicles;
  final String status; // READY, DISPATCHED, STANDBY

  RescueCenterModel({
    required this.id,
    required this.name,
    required this.stationUnit,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.contactPhone,
    required this.activePersonnel,
    required this.availableVehicles,
    this.status = 'READY',
  });

  factory RescueCenterModel.fromJson(Map<String, dynamic> json) {
    return RescueCenterModel(
      id: json['id']?.toString() ?? 'RC-01',
      name: json['name'] as String? ?? 'Tactical Rescue Post',
      stationUnit: json['station_unit'] as String? ?? 'Unit Alpha',
      location: json['location'] as String? ?? 'Central Tactical Base',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 30.3165,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 78.0322,
      contactPhone: json['contact_phone'] as String? ?? '+91 98765 00000',
      activePersonnel: (json['active_personnel'] as num?)?.toInt() ?? 24,
      availableVehicles: (json['available_vehicles'] as num?)?.toInt() ?? 6,
      status: json['status'] as String? ?? 'READY',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'station_unit': stationUnit,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'contact_phone': contactPhone,
      'active_personnel': activePersonnel,
      'available_vehicles': availableVehicles,
      'status': status,
    };
  }
}

