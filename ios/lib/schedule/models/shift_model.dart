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

  const ShiftModel({
    required this.id,
    required this.employeeId,
    required this.startTime,
    required this.endTime,
    required this.roleTitle,
    required this.location,
    required this.color,
  });

  double get durationInHours => 
      endTime.difference(startTime).inMinutes / 60.0;

  String get timeRange {
    final start = DateFormat('HH:mm').format(startTime);
    final end = DateFormat('HH:mm').format(endTime);
    return '$start - $end';
  }

  factory ShiftModel.fromShift(Shift shift) {
    // Mock role based on shift data or random
    final roles = ['Администратор', 'Повар', 'Официант', 'Бармен'];
    
    final roleIndex = shift.id.hashCode.abs() % roles.length;
    
    // Color based on role
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
    ];

    return ShiftModel(
      id: shift.id,
      employeeId: shift.employeeId,
      startTime: shift.startTime,
      endTime: shift.endTime,
      roleTitle: roles[roleIndex],
      location: shift.location, // Use real location from Shift
      color: colors[roleIndex],
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
  }) {
    return ShiftModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roleTitle: roleTitle ?? this.roleTitle,
      location: location ?? this.location,
      color: color ?? this.color,
    );
  }
}