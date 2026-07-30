enum UserRole { chw, supervisor, admin }

class User {
  final int id;
  final String email;
  final String name;
  final UserRole role;
  final int facilityId;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.facilityId,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'] as String,
      ),
      facilityId: json['facility_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role.name,
    'facility_id': facilityId,
    'created_at': createdAt.toIso8601String(),
  };
}
