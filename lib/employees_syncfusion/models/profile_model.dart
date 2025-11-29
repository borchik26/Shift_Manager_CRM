import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';

enum ShiftType {
  morning,
  day,
  evening,
  night;

  String get displayName {
    switch (this) {
      case ShiftType.morning:
        return 'Утро';
      case ShiftType.day:
        return 'День';
      case ShiftType.evening:
        return 'Вечер';
      case ShiftType.night:
        return 'Ночь';
    }
  }

  String get icon {
    switch (this) {
      case ShiftType.morning:
        return '🌅';
      case ShiftType.day:
        return '☀️';
      case ShiftType.evening:
        return '🌆';
      case ShiftType.night:
        return '🌙';
    }
  }
}

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

class LocationStats {
  final String location;
  final double hours;
  final int shiftsCount;
  final double percentage;

  const LocationStats({
    required this.location,
    required this.hours,
    required this.shiftsCount,
    required this.percentage,
  });
}

class ShiftEvent {
  final DateTime date;
  final String timeRange; // "09:00 - 18:00"
  final double durationHours;
  final String location;
  final ShiftType shiftType;
  final bool isWarning;
  final String? warningText;

  const ShiftEvent({
    required this.date,
    required this.timeRange,
    required this.durationHours,
    required this.location,
    required this.shiftType,
    this.isWarning = false,
    this.warningText,
  });

  factory ShiftEvent.fromShift(Shift shift) {
    final duration = shift.endTime
        .difference(shift.startTime)
        .inHours
        .toDouble();
    final timeRange =
        '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}';
    final shiftType = _determineShiftType(shift.startTime);

    return ShiftEvent(
      date: shift.startTime,
      timeRange: timeRange,
      durationHours: duration,
      location: shift.location,
      shiftType: shiftType,
      isWarning: false,
      warningText: null,
    );
  }

  static ShiftType _determineShiftType(DateTime startTime) {
    final hour = startTime.hour;
    if (hour >= 6 && hour < 12) return ShiftType.morning;
    if (hour >= 12 && hour < 18) return ShiftType.day;
    if (hour >= 18 && hour < 22) return ShiftType.evening;
    return ShiftType.night;
  }

  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class WeekGroup {
  final String title;
  final List<ShiftEvent> shifts;

  const WeekGroup({
    required this.title,
    required this.shifts,
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
  final List<ShiftEvent> recentShifts;
  final double workedHours;
  final double totalHours;
  final List<LocationStats> locationStats;
  final double averageShiftHours;
  final int totalShifts;
  final int nightShiftsCount;
  final List<WeekGroup> weekGroups;

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
    required this.locationStats,
    required this.averageShiftHours,
    required this.totalShifts,
    required this.nightShiftsCount,
    required this.weekGroups,
  });

  double get hoursPercent {
    if (totalHours <= 0) return 0;
    final percent = workedHours / totalHours;
    // Clamp to valid range [0.0, 1.0] for LinearPercentIndicator
    return percent.clamp(0.0, 1.0);
  }

  /// Actual percentage (may exceed 100% for overtime)
  double get actualHoursPercent {
    if (totalHours <= 0) return 0;
    return workedHours / totalHours;
  }

  double get loadPercentage =>
      totalHours > 0 ? (workedHours / totalHours) * 100 : 0;

  String get loadStatus {
    if (loadPercentage < 50) return 'Низкая';
    if (loadPercentage < 80) return 'Норма';
    if (loadPercentage < 100) return 'Высокая';
    return 'Переработка';
  }

  factory EmployeeProfile.fromEmployee(
    Employee employee, {
    List<ShiftEvent>? recentShifts,
    double? workedHours,
  }) {
    final shifts = recentShifts ?? [];

    // Calculate statistics
    final totalShifts = shifts.length;
    final averageShiftHours = totalShifts > 0
        ? (shifts.fold<double>(0, (sum, s) => sum + s.durationHours) /
                  totalShifts)
              .toDouble()
        : 0.0;
    final nightShiftsCount = shifts
        .where((s) => s.shiftType == ShiftType.night)
        .length;

    // Calculate location statistics
    final locationStats = calculateLocationStats(shifts, workedHours ?? 0);

    // Group shifts by weeks
    final weekGroups = groupShiftsByWeek(shifts);

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
      avatarUrl:
          employee.avatarUrl ?? 'https://i.pravatar.cc/150?u=${employee.id}',
      email: employee.email ?? 'employee@example.com',
      phone: employee.phone ?? '+7 (999) 000-00-00',
      address: 'г. Москва, ул. Ленина, д. 1', // Mock address
      branch: employee.branch,
      hireDate: employee.hireDate,
      history: history,
      recentShifts: shifts,
      workedHours: workedHours ?? 0,
      totalHours: 160,
      locationStats: locationStats,
      averageShiftHours: averageShiftHours,
      totalShifts: totalShifts,
      nightShiftsCount: nightShiftsCount,
      weekGroups: weekGroups,
    );
  }

  static List<LocationStats> calculateLocationStats(
    List<ShiftEvent> shifts,
    double totalHours,
  ) {
    final Map<String, double> hoursPerLocation = {};
    final Map<String, int> shiftsPerLocation = {};

    for (var shift in shifts) {
      hoursPerLocation[shift.location] =
          (hoursPerLocation[shift.location] ?? 0) + shift.durationHours;
      shiftsPerLocation[shift.location] =
          (shiftsPerLocation[shift.location] ?? 0) + 1;
    }

    return hoursPerLocation.entries.map((entry) {
      return LocationStats(
        location: entry.key,
        hours: entry.value,
        shiftsCount: shiftsPerLocation[entry.key] ?? 0,
        percentage: totalHours > 0 ? (entry.value / totalHours) * 100 : 0,
      );
    }).toList()..sort((a, b) => b.hours.compareTo(a.hours));
  }

  static List<WeekGroup> groupShiftsByWeek(List<ShiftEvent> shifts) {
    if (shifts.isEmpty) return [];

    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    final thisWeek = shifts
        .where((s) => s.date.isAfter(thisWeekStart))
        .toList();
    final lastWeek = shifts
        .where(
          (s) =>
              s.date.isAfter(lastWeekStart) && s.date.isBefore(thisWeekStart),
        )
        .toList();
    final older = shifts.where((s) => s.date.isBefore(lastWeekStart)).toList();

    final groups = <WeekGroup>[];
    if (thisWeek.isNotEmpty) {
      groups.add(WeekGroup(title: 'Эта неделя', shifts: thisWeek));
    }
    if (lastWeek.isNotEmpty) {
      groups.add(WeekGroup(title: 'Прошлая неделя', shifts: lastWeek));
    }
    if (older.isNotEmpty) {
      groups.add(WeekGroup(title: 'Ранее', shifts: older));
    }

    return groups;
  }
}
