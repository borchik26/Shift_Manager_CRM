import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';

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

class ShiftEvent {
  final DateTime date;
  final String timeRange; // "09:00 - 18:00"
  final double durationHours;
  final String location;
  final bool isWarning;
  final String? warningText;

  const ShiftEvent({
    required this.date,
    required this.timeRange,
    required this.durationHours,
    required this.location,
    this.isWarning = false,
    this.warningText,
  });

  factory ShiftEvent.fromShift(Shift shift) {
    final duration = shift.endTime.difference(shift.startTime).inHours.toDouble();
    final timeRange = '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}';
    
    return ShiftEvent(
      date: shift.startTime,
      timeRange: timeRange,
      durationHours: duration,
      location: shift.location,
      isWarning: false,
      warningText: null,
    );
  }

  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
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
  final List<ShiftEvent> recentShifts;
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
    required this.recentShifts,
    required this.workedHours,
    required this.totalHours,
  });

  double get hoursPercent => totalHours > 0 ? workedHours / totalHours : 0;

  factory EmployeeProfile.fromEmployee(
    Employee employee, {
    List<ShiftEvent>? recentShifts,
  }) {
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
      recentShifts: recentShifts ?? [],
      workedHours: 128, // Mock worked hours
      totalHours: 160, // Mock total hours
    );
  }
}