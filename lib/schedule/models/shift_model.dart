import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/core/utils/color_generator.dart';

class ShiftModel {
  final String id;
  final String? employeeId; // Nullable to support unassigned/free shifts
  final DateTime startTime;
  final DateTime endTime;
  final String roleTitle;
  final String location;
  final Color color;
  final String? employeePreferences; // Employee's preferences/wishes
  final double hourlyRate; // Hourly rate in rubles

  const ShiftModel({
    required this.id,
    this.employeeId, // Now optional
    required this.startTime,
    required this.endTime,
    required this.roleTitle,
    required this.location,
    required this.color,
    this.employeePreferences,
    required this.hourlyRate,
  });

  double get durationInHours =>
      endTime.difference(startTime).inMinutes / 60.0;

  /// Calculate labor cost for this shift
  double get cost => durationInHours * hourlyRate;

  String get timeRange {
    final start = DateFormat('HH:mm').format(startTime);
    final end = DateFormat('HH:mm').format(endTime);
    return '$start - $end';
  }

  /// Maps role title to corresponding color using hash-based generation
  /// Ensures stable colors - same role always gets same color
  static Color getColorForRole(String? roleTitle) {
    if (roleTitle == null || roleTitle.isEmpty || roleTitle == 'Неизвестно') {
      return Colors.grey; // Fallback for unknown roles
    }
    return ColorGenerator.generateColor(roleTitle);
  }

  factory ShiftModel.fromShift(Shift shift) {
    // Use role from shift if available, otherwise fallback to grey
    final roleTitle = shift.roleTitle ?? 'Неизвестно';
    final color = getColorForRole(roleTitle);

    // Convert null employeeId to 'unassigned' for UI
    final employeeId = shift.employeeId ?? 'unassigned';

    return ShiftModel(
      id: shift.id,
      employeeId: employeeId,
      startTime: shift.startTime,
      endTime: shift.endTime,
      roleTitle: roleTitle,
      location: shift.location,
      color: color,
      employeePreferences: shift.employeePreferences,
      hourlyRate: shift.hourlyRate,
    );
  }

  ShiftModel copyWith({
    String? id,
    String? employeeId,
    DateTime? startTime,
    DateTime? endTime,
    String? roleTitle,
    String? location,
    Color? color,
    String? employeePreferences,
    double? hourlyRate,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      employeeId: employeeId, // Don't use ?? to allow setting to null
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roleTitle: roleTitle ?? this.roleTitle,
      location: location ?? this.location,
      color: color ?? this.color,
      employeePreferences: employeePreferences ?? this.employeePreferences,
      hourlyRate: hourlyRate ?? this.hourlyRate,
    );
  }
}
