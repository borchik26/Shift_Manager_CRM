/// User model for authentication
class User {
  final String id;
  final String username; // email
  final String role; // 'employee' or 'manager'
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? status; // 'active', 'inactive', 'pending'
  final DateTime? createdAt;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.username,
    required this.role,
    this.email,
    this.firstName,
    this.lastName,
    this.status,
    this.createdAt,
    this.lastLogin,
  });

  /// Full name computed from first and last name
  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    return '$first $last'.trim();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String? ?? json['email'] as String? ?? '',
      role: json['role'] as String,
      email: json['email'] as String?,
      firstName: json['first_name'] as String? ?? json['firstName'] as String?,
      lastName: json['last_name'] as String? ?? json['lastName'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email ?? username,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }
}