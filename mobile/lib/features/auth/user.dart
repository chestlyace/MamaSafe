enum UserRole { chw, supervisor, admin }

class User {
  final int id;
  final String username;
  final String name;
  final UserRole role;
  final String? facility;
  final String? district;
  final String? region;
  final String? whatsappNumber;
  final bool isActive;
  final DateTime? lastActive;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.facility,
    this.district,
    this.region,
    this.whatsappNumber,
    this.isActive = true,
    this.lastActive,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      name: (json['name'] as String?) ?? (json['full_name'] as String?) ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.chw,
      ),
      facility: json['facility'] as String?,
      district: json['district'] as String?,
      region: json['region'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastActive: json['last_active'] != null
          ? DateTime.tryParse(json['last_active'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  User copyWith({
    String? name,
    String? facility,
    String? district,
    String? region,
    String? whatsappNumber,
  }) {
    return User(
      id: id,
      username: username,
      name: name ?? this.name,
      role: role,
      facility: facility ?? this.facility,
      district: district ?? this.district,
      region: region ?? this.region,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      isActive: isActive,
      lastActive: lastActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'role': role.name,
        'facility': facility,
        'district': district,
        'region': region,
        'whatsapp_number': whatsappNumber,
        'is_active': isActive,
        'last_active': lastActive?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };
}

User userFromRoleName(String roleName) {
  return User(
    id: 0,
    username: '',
    name: '',
    role: UserRole.values.firstWhere(
      (role) => role.name == roleName,
      orElse: () => UserRole.chw,
    ),
  );
}
