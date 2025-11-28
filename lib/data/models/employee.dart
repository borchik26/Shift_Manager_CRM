/// Employee model for staff management
class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final String position;
  final String branch;
  final String status;
  final DateTime hireDate;
  final String? avatarUrl;
  final String? email;
  final String? phone;

  const Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.position,
    required this.branch,
    required this.status,
    required this.hireDate,
    this.avatarUrl,
    this.email,
    this.phone,
  });

  String get fullName => '$firstName $lastName';

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      position: json['position'] as String,
      branch: json['branch'] as String,
      status: json['status'] as String,
      hireDate: DateTime.parse(json['hire_date'] as String),
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'position': position,
      'branch': branch,
      'status': status,
      'hire_date': hireDate.toIso8601String(),
      'avatar_url': avatarUrl,
      'email': email,
      'phone': phone,
    };
  }

  Employee copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? position,
    String? branch,
    String? status,
    DateTime? hireDate,
    String? avatarUrl,
    String? email,
    String? phone,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      position: position ?? this.position,
      branch: branch ?? this.branch,
      status: status ?? this.status,
      hireDate: hireDate ?? this.hireDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}