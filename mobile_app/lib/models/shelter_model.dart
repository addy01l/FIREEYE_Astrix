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
      id: json['id']?.toString() ?? json['shelter_code']?.toString() ?? (throw const FormatException('Shelter ID missing')),
      name: json['name'] as String? ?? (throw const FormatException('Shelter name missing')),
      address: json['address'] as String? ?? json['facility_type'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? (throw const FormatException('Shelter capacity missing')),
      occupancy: (json['occupancy'] as num?)?.toInt() ?? (throw const FormatException('Shelter occupancy missing')),
      latitude: (json['latitude'] as num?)?.toDouble() ?? (throw const FormatException('Shelter latitude missing')),
      longitude: (json['longitude'] as num?)?.toDouble() ?? (throw const FormatException('Shelter longitude missing')),
      contactPhone: json['contact_phone'] as String? ?? '',
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

