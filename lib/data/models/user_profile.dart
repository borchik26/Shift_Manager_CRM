/// User profile model for authentication and user management
/// Represents a user from the 'profiles' table in Supabase
class UserProfile {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String role; // 'employee' or 'manager'
  final String status; // 'active', 'inactive', or 'pending'
  final DateTime createdAt;
  final DateTime? lastLogin;

  const UserProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.role,
    required this.status,
    required this.createdAt,
    this.lastLogin,
  });

  /// Full name computed from first and last name
  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    final combined = '$first $last'.trim();
    return combined.isEmpty ? email : combined;
  }

  /// Get display name (full name or email)
  String get displayName => fullName;

  /// Check if user is pending approval
  bool get isPending => status == 'pending';

  /// Check if user is active
  bool get isActive => status == 'active';

  /// Check if user is inactive
  bool get isInactive => status == 'inactive';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? status,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
