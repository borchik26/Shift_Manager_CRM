/// Shift model for schedule management
class Shift {
  final String id;
  final String? employeeId; // Nullable to support unassigned/free shifts
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? notes;
  final bool isNightShift;
  final String?
  employeePreferences; // Employee's preferences/wishes for this shift
  final String?
  roleTitle; // Role assigned to this shift (Администратор, Повар, etc.)
  final double hourlyRate; // Hourly rate in rubles

  const Shift({
    required this.id,
    this.employeeId, // Now optional
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
    this.isNightShift = false,
    this.employeePreferences,
    this.roleTitle,
    required this.hourlyRate,
  });

  Duration get duration => endTime.difference(startTime);

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String?, // Nullable
      location: json['location'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      isNightShift: json['is_night_shift'] as bool? ?? false,
      employeePreferences: json['employee_preferences'] as String?,
      roleTitle: json['role_title'] as String?,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 400.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'location': location,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'notes': notes,
      'is_night_shift': isNightShift,
      'employee_preferences': employeePreferences,
      'role_title': roleTitle,
      'hourly_rate': hourlyRate,
    };
  }

  Shift copyWith({
    String? id,
    String? employeeId,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    String? notes,
    bool? isNightShift,
    String? employeePreferences,
    String? roleTitle,
    double? hourlyRate,
  }) {
    return Shift(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isNightShift: isNightShift ?? this.isNightShift,
      employeePreferences: employeePreferences ?? this.employeePreferences,
      roleTitle: roleTitle ?? this.roleTitle,
      hourlyRate: hourlyRate ?? this.hourlyRate,
    );
  }
}
