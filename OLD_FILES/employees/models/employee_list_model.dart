import 'package:flutter/material.dart';
import 'package:my_app/data/models/employee.dart';

enum EmployeeStatus {
  onShift,
  dayOff,
  vacation;

  String get label {
    switch (this) {
      case EmployeeStatus.onShift:
        return 'На смене';
      case EmployeeStatus.dayOff:
        return 'Выходной';
      case EmployeeStatus.vacation:
        return 'Отпуск';
    }
  }

  Color get color {
    switch (this) {
      case EmployeeStatus.onShift:
        return Colors.green;
      case EmployeeStatus.dayOff:
        return Colors.grey;
      case EmployeeStatus.vacation:
        return Colors.orange;
    }
  }
}

class EmployeeListModel {
  final String id;
  final String name;
  final String role;
  final String branch;
  final EmployeeStatus status;
  final double hours;
  final String avatarUrl;

  EmployeeListModel({
    required this.id,
    required this.name,
    required this.role,
    required this.branch,
    required this.status,
    required this.hours,
    required this.avatarUrl,
  });

  factory EmployeeListModel.fromEmployee(Employee employee) {
    // Mock status logic based on ID for demo purposes
    final statusIndex = employee.id.hashCode % 3;
    final status = EmployeeStatus.values[statusIndex];

    // Mock hours based on ID
    final hours = (employee.id.hashCode % 40) + 120.0;

    return EmployeeListModel(
      id: employee.id,
      name: '${employee.firstName} ${employee.lastName}',
      role: employee.position,
      branch: employee.branch,
      status: status,
      hours: hours,
      avatarUrl: employee.avatarUrl ?? '',
    );
  }
}
