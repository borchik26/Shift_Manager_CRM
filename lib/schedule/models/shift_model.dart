import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/data/models/shift.dart';

class ShiftModel {
  final String id;
  final String employeeId;
  final DateTime startTime;
  final DateTime endTime;
  final String roleTitle;
  final String location;
  final Color color;
  final String? employeePreferences; // Employee's preferences/wishes
  final double hourlyRate; // Hourly rate in rubles

  const ShiftModel({
    required this.id,
    required this.employeeId,
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

  /// Maps role title to corresponding color from legend
  static Color getColorForRole(String? roleTitle) {
    switch (roleTitle) {
      case 'Менеджер':
        return Colors.blue;
      case 'Повар':
        return Colors.orange;
      case 'Кассир':
        return Colors.green;
      case 'Уборщица':
        return Colors.purple;
      default:
        return Colors.grey; // Fallback for unknown roles
    }
  }

  factory ShiftModel.fromShift(Shift shift) {
    // Use role from shift if available, otherwise fallback to grey
    final roleTitle = shift.roleTitle ?? 'Неизвестно';
    final color = getColorForRole(roleTitle);

    return ShiftModel(
      id: shift.id,
      employeeId: shift.employeeId,
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
      employeeId: employeeId ?? this.employeeId,
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
