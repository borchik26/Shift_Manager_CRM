import 'package:flutter/material.dart';
import 'package:my_app/data/models/employee.dart';

class HistoryEvent {
  final DateTime date;
  final String title;
  final String description;

  const HistoryEvent({
    required this.date,
    required this.title,
    required this.description,
  });
}

class EmployeeProfile {
  final String id;
  final String name;
  final String role;
  final String avatarUrl;
  final String email;
  final String phone;
  final String address;
  final String branch;
  final DateTime hireDate;
  final List<HistoryEvent> history;
  final double workedHours;
  final double totalHours;

  const EmployeeProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.email,
    required this.phone,
    required this.address,
    required this.branch,
    required this.hireDate,
    required this.history,
    required this.workedHours,
    required this.totalHours,
  });

  double get hoursPercent => totalHours > 0 ? workedHours / totalHours : 0;

  factory EmployeeProfile.fromEmployee(Employee employee) {
    // Mock history data
    final history = [
      HistoryEvent(
        date: DateTime.now().subtract(const Duration(days: 5)),
        title: 'Завершение смены',
        description: 'Отработано 8 часов в филиале Центр',
      ),
      HistoryEvent(
        date: DateTime.now().subtract(const Duration(days: 12)),
        title: 'Больничный',
        description: 'Открыт больничный лист',
      ),
      HistoryEvent(
        date: employee.hireDate,
        title: 'Прием на работу',
        description: 'Принят на должность ${employee.position}',
      ),
    ];

    return EmployeeProfile(
      id: employee.id,
      name: '${employee.firstName} ${employee.lastName}',
      role: employee.position,
      avatarUrl: employee.avatarUrl ?? 'https://i.pravatar.cc/150?u=${employee.id}',
      email: employee.email ?? 'employee@example.com',
      phone: employee.phone ?? '+7 (999) 000-00-00',
      address: 'г. Москва, ул. Ленина, д. 1', // Mock address
      branch: employee.branch,
      hireDate: employee.hireDate,
      history: history,
      workedHours: 128, // Mock worked hours
      totalHours: 160, // Mock total hours
    );
  }
}