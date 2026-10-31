class ShelterModel {
  final String id;
  final String name;
  final String address;
  final int capacity;
  final int occupancy;
  final double latitude;
  final double longitude;
  final String contactPhone;
  final bool hasMedical;
  final bool hasGenerator;
  final String status; // OPERATIONAL, NEAR CAPACITY, FULL, OFFLINE

  ShelterModel({
    required this.id,
    required this.name,
    required this.address,
    required this.capacity,
    required this.occupancy,
    required this.latitude,
    required this.longitude,
    required this.contactPhone,
    required this.hasMedical,
    required this.hasGenerator,
    this.status = 'OPERATIONAL',
  });

  int get availableBeds => (capacity - occupancy).clamp(0, capacity);
  double get occupancyRate => capacity > 0 ? (occupancy / capacity).clamp(0.0, 1.0) : 0.0;

  factory ShelterModel.fromJson(Map<String, dynamic> json) {
    return ShelterModel(
      id: json['id']?.toString() ?? 'SHL-${json['name'] ?? '01'}',
      name: json['name'] as String? ?? 'Disaster Relief Shelter',
      address: json['address'] as String? ?? 'Community Relief Center',
      capacity: (json['capacity'] as num?)?.toInt() ?? 250,
      occupancy: (json['occupancy'] as num?)?.toInt() ?? 100,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 30.3340,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 78.0550,
      contactPhone: json['contact_phone'] as String? ?? '+91 94101 22334',
      hasMedical: json['has_medical'] == true,
      hasGenerator: json['has_generator'] == true,
      status: json['status'] as String? ?? 'OPERATIONAL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'capacity': capacity,
      'occupancy': occupancy,
      'latitude': latitude,
      'longitude': longitude,
      'contact_phone': contactPhone,
      'has_medical': hasMedical,
      'has_generator': hasGenerator,
      'status': status,
    };
  }
}

