class VictimModel {
  final String id;
  final String fullName;
  final String incidentId;
  final String location;
  final String status; // TRAPPED, IN TRANSIT, RESCUED, MEDICAL CARE
  final int priorityScore;
  final bool hasInfants;
  final bool hasElderly;
  final String medicalCondition;
  final String contactNumber;
  final DateTime reportedAt;

  VictimModel({
    required this.id,
    required this.fullName,
    required this.incidentId,
    required this.location,
    required this.status,
    required this.priorityScore,
    required this.hasInfants,
    required this.hasElderly,
    required this.medicalCondition,
    required this.contactNumber,
    required this.reportedAt,
  });

  factory VictimModel.fromJson(Map<String, dynamic> json) {
    return VictimModel(
      id: json['id']?.toString() ?? 'VIC-01',
      fullName: json['full_name'] as String? ?? 'Affected Resident',
      incidentId: json['incident_id'] as String? ?? 'INC-01',
      location: json['location'] as String? ?? 'Sector 4, Building B',
      status: (json['status'] as String? ?? 'TRAPPED').toUpperCase(),
      priorityScore: (json['priority_score'] as num?)?.toInt() ?? 75,
      hasInfants: json['has_infants'] == true,
      hasElderly: json['has_elderly'] == true,
      medicalCondition: json['medical_condition'] as String? ?? 'Stable / Minor Inhalation',
      contactNumber: json['contact_number'] as String? ?? '+91 94110 00000',
      reportedAt: json['reported_at'] != null
          ? DateTime.tryParse(json['reported_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'incident_id': incidentId,
      'location': location,
      'status': status,
      'priority_score': priorityScore,
      'has_infants': hasInfants,
      'has_elderly': hasElderly,
      'medical_condition': medicalCondition,
      'contact_number': contactNumber,
      'reported_at': reportedAt.toIso8601String(),
    };
  }

  VictimModel copyWith({
    String? status,
    String? medicalCondition,
  }) {
    return VictimModel(
      id: id,
      fullName: fullName,
      incidentId: incidentId,
      location: location,
      status: status ?? this.status,
      priorityScore: priorityScore,
      hasInfants: hasInfants,
      hasElderly: hasElderly,
      medicalCondition: medicalCondition ?? this.medicalCondition,
      contactNumber: contactNumber,
      reportedAt: reportedAt,
    );
  }
}

