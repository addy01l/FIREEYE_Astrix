enum UserRole {
  commander,
  responder,
  volunteer,
  citizen;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.citizen;
    switch (role.toLowerCase().trim()) {
      case 'commander':
      case 'admin':
        return UserRole.commander;
      case 'responder':
      case 'rescue':
        return UserRole.responder;
      case 'volunteer':
        return UserRole.volunteer;
      case 'citizen':
      default:
        return UserRole.citizen;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.commander:
        return 'Incident Commander';
      case UserRole.responder:
        return 'Field Responder';
      case UserRole.volunteer:
        return 'Relief Volunteer';
      case UserRole.citizen:
        return 'Civilian User';
    }
  }
}

class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final UserRole role;
  final String? token;
  final String? assignedStation;
  final String? phone;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.token,
    this.assignedStation,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? 'citizen';
    return UserModel(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? 'USR-01',
      username: json['username'] as String? ?? 'operator',
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? json['username'] as String? ?? 'Tactical Operator',
      email: json['email'] as String? ?? '${json['username'] ?? 'operator'}@fireeye.gov.in',
      role: UserRole.fromString(roleStr),
      token: json['access_token'] as String? ?? json['token'] as String?,
      assignedStation: json['station'] as String? ?? 'Station Bravo 04',
      phone: json['phone'] as String? ?? '+91 98765 43210',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'role': role.name,
      'access_token': token,
      'station': assignedStation,
      'phone': phone,
    };
  }
}
