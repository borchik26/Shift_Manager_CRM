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
  final String? address; // ✅ ADDED: Physical address
  final double hourlyRate; // ✅ ADDED: Hourly rate in rubles
  final List<DesiredDayOff> desiredDaysOff;

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
    this.address,
    this.hourlyRate = 0.0, // Default hourly rate
    this.desiredDaysOff = const [],
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
      address: json['address'] as String?, // ✅ ADDED
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0.0, // ✅ ADDED
      desiredDaysOff: (json['desired_days_off'] as List<dynamic>?)
              ?.map((e) => DesiredDayOff.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
      'address': address, // ✅ ADDED
      'hourly_rate': hourlyRate, // ✅ ADDED
      'desired_days_off': desiredDaysOff.map((d) => d.toJson()).toList(),
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
    String? address, // ✅ ADDED
    double? hourlyRate, // ✅ ADDED
    List<DesiredDayOff>? desiredDaysOff,
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
      address: address ?? this.address, // ✅ ADDED
      hourlyRate: hourlyRate ?? this.hourlyRate, // ✅ ADDED
      desiredDaysOff: desiredDaysOff ?? this.desiredDaysOff,
    );
  }
}

/// Represents a desired day off with optional comment
class DesiredDayOff {
  final DateTime date; // Date only (time set to midnight)
  final String? comment; // Optional comment (e.g., "Хочу побыть с семьей")

  const DesiredDayOff({
    required this.date,
    this.comment,
  });

  /// Creates DesiredDayOff from JSON (snake_case keys)
  factory DesiredDayOff.fromJson(Map<String, dynamic> json) {
    return DesiredDayOff(
      date: DateTime.parse(json['date'] as String),
      comment: json['comment'] as String?,
    );
  }

  /// Converts DesiredDayOff to JSON (snake_case keys)
  Map<String, dynamic> toJson() {
    return {
      'date': _dateOnly(date).toIso8601String(),
      'comment': comment,
    };
  }

  /// Helper to strip time component (returns date at midnight)
  static DateTime _dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}
