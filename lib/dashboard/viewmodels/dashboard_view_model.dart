import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/dashboard/models/dashboard_stats.dart';
import 'package:my_app/dashboard/models/dashboard_alert.dart';

class DashboardViewModel {
  final AuthService _authService;
  final RouterService _routerService;
  final EmployeeRepository _employeeRepository;
  final ShiftRepository _shiftRepository;

  DashboardViewModel({
    required AuthService authService,
    required RouterService routerService,
    required EmployeeRepository employeeRepository,
    required ShiftRepository shiftRepository,
  })  : _authService = authService,
        _routerService = routerService,
        _employeeRepository = employeeRepository,
        _shiftRepository = shiftRepository;

  // States
  final statsState = ValueNotifier<AsyncValue<DashboardStats>>(
    const AsyncLoading(),
  );
  final weeklyShiftsState = ValueNotifier<AsyncValue<List<Shift>>>(
    const AsyncLoading(),
  );
  final alertsState = ValueNotifier<AsyncValue<List<DashboardAlert>>>(
    const AsyncLoading(),
  );

  // Cached data
  DashboardStats? _stats;
  List<Shift> _weeklyShifts = [];
  List<DashboardAlert> _alerts = [];

  // Getters
  DashboardStats? get stats => _stats;
  List<Shift> get weeklyShifts => _weeklyShifts;
  List<DashboardAlert> get alerts => _alerts;

  /// Get weekly shifts count by day (Monday-Sunday)
  List<int> get weeklyShiftsCount {
    if (_weeklyShifts.isEmpty) {
      return List.filled(7, 0);
    }

    final now = DateTime.now();
    final monday = _getMonday(now);
    final counts = List.filled(7, 0);

    for (final shift in _weeklyShifts) {
      final shiftDate = DateTime(
        shift.startTime.year,
        shift.startTime.month,
        shift.startTime.day,
      );
      final daysDiff = shiftDate.difference(monday).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        counts[daysDiff]++;
      }
    }

    return counts;
  }

  /// Get weekly hours data by day (Monday-Sunday)
  List<double> get weeklyHoursData {
    if (_weeklyShifts.isEmpty) {
      return List.filled(7, 0.0);
    }

    final now = DateTime.now();
    final monday = _getMonday(now);
    final hours = List.filled(7, 0.0);

    for (final shift in _weeklyShifts) {
      final shiftDate = DateTime(
        shift.startTime.year,
        shift.startTime.month,
        shift.startTime.day,
      );
      final daysDiff = shiftDate.difference(monday).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        hours[daysDiff] += shift.duration.inHours.toDouble();
      }
    }

    return hours;
  }

  /// Load all dashboard data
  Future<void> loadDashboard() async {
    try {
      // Load all data in parallel
      await Future.wait([
        _loadStats(),
        _loadWeeklyShifts(),
        _loadAlerts(),
      ]);
    } catch (e) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Ошибка загрузки данных: ${e.toString()}'),
      );
    }
  }

  /// Load and calculate statistics
  Future<void> _loadStats() async {
    try {
      statsState.value = const AsyncLoading();
      final employees = await _employeeRepository.getEmployees();
      final shifts = await _shiftRepository.getShifts();

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final todayShifts = shifts.where((shift) {
        return shift.startTime.isAfter(todayStart) &&
            shift.startTime.isBefore(todayEnd);
      }).length;

      final weeklyHours = _calculateWeeklyHours(shifts);
      final conflicts = _countConflicts(shifts);

      _stats = DashboardStats(
        totalEmployees: employees.length,
        todayShifts: todayShifts,
        weeklyHours: weeklyHours,
        conflicts: conflicts,
      );

      statsState.value = AsyncData(_stats!);
    } catch (e) {
      statsState.value = AsyncError(
        'Ошибка загрузки статистики: ${e.toString()}',
        e,
      );
    }
  }

  /// Load weekly shifts (current week Monday-Sunday)
  Future<void> _loadWeeklyShifts() async {
    try {
      weeklyShiftsState.value = const AsyncLoading();
      final now = DateTime.now();
      final monday = _getMonday(now);
      final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59));

      final shifts = await _shiftRepository.getShifts(
        startDate: monday,
        endDate: sunday,
      );

      _weeklyShifts = shifts;
      weeklyShiftsState.value = AsyncData(_weeklyShifts);
    } catch (e) {
      weeklyShiftsState.value = AsyncError(
        'Ошибка загрузки смен: ${e.toString()}',
        e,
      );
    }
  }

  /// Load alerts
  Future<void> _loadAlerts() async {
    try {
      alertsState.value = const AsyncLoading();
      final employees = await _employeeRepository.getEmployees();
      final shifts = await _shiftRepository.getShifts();

      final alerts = <DashboardAlert>[];

      // Count day off requests
      int dayOffRequests = 0;
      for (final employee in employees) {
        dayOffRequests += employee.desiredDaysOff.length;
      }
      if (dayOffRequests > 0) {
        alerts.add(
          DashboardAlert(
            type: AlertType.warning,
            message: '$dayOffRequests ${_getRequestWordForm(dayOffRequests)} на выходной',
          ),
        );
      }

      // Check for missing shifts on Friday
      final now = DateTime.now();
      final friday = _getNextFriday(now);
      final fridayShifts = shifts.where((shift) {
        final shiftDate = DateTime(
          shift.startTime.year,
          shift.startTime.month,
          shift.startTime.day,
        );
        return shiftDate.isAtSameMomentAs(friday);
      }).length;

      // Estimate needed shifts (rough calculation: employees / 2)
      final neededShifts = (employees.length / 2).ceil();
      if (fridayShifts < neededShifts) {
        final missing = neededShifts - fridayShifts;
        alerts.add(
          DashboardAlert(
            type: AlertType.info,
            message: 'Недостаёт $missing ${_getShiftWordForm(missing)} на пятницу',
          ),
        );
      }

      _alerts = alerts;
      alertsState.value = AsyncData(_alerts);
    } catch (e) {
      alertsState.value = AsyncError(
        'Ошибка загрузки уведомлений: ${e.toString()}',
        e,
      );
    }
  }

  /// Calculate total hours for current week
  double _calculateWeeklyHours(List<Shift> shifts) {
    final now = DateTime.now();
    final monday = _getMonday(now);
    final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59));

    double totalHours = 0.0;
    for (final shift in shifts) {
      if (shift.startTime.isAfter(monday) &&
          shift.startTime.isBefore(sunday)) {
        totalHours += shift.duration.inHours.toDouble();
      }
    }

    return totalHours;
  }

  /// Count conflicts (overlapping shifts for same employee)
  int _countConflicts(List<Shift> shifts) {
    int conflicts = 0;
    final employeeShifts = <String, List<Shift>>{};

    // Group shifts by employee
    for (final shift in shifts) {
      employeeShifts.putIfAbsent(shift.employeeId, () => []).add(shift);
    }

    // Check for overlaps for each employee
    for (final employeeShiftList in employeeShifts.values) {
      // Sort by start time
      employeeShiftList.sort((a, b) => a.startTime.compareTo(b.startTime));

      for (int i = 0; i < employeeShiftList.length - 1; i++) {
        for (int j = i + 1; j < employeeShiftList.length; j++) {
          final shift1 = employeeShiftList[i];
          final shift2 = employeeShiftList[j];

          // Check if time ranges overlap
          if (shift1.startTime.isBefore(shift2.endTime) &&
              shift1.endTime.isAfter(shift2.startTime)) {
            conflicts++;
            break; // Count each conflict only once
          }
        }
      }
    }

    return conflicts;
  }

  /// Get Monday of current week
  DateTime _getMonday(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: weekday - 1));
  }

  /// Get next Friday
  DateTime _getNextFriday(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final daysUntilFriday = (5 - weekday) % 7;
    if (daysUntilFriday == 0 && date.hour >= 12) {
      // If it's Friday afternoon, get next Friday
      return DateTime(date.year, date.month, date.day + 7);
    }
    return DateTime(date.year, date.month, date.day + daysUntilFriday);
  }

  /// Get word form for "запрос/запроса/запросов"
  String _getRequestWordForm(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'запрос';
    } else if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'запроса';
    } else {
      return 'запросов';
    }
  }

  /// Get word form for "смена/смены/смен"
  String _getShiftWordForm(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'смена';
    } else if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'смены';
    } else {
      return 'смен';
    }
  }

  void navigateTo(String path) {
    _routerService.replace(Path(name: path));
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _routerService.replaceAll([Path(name: '/login')]);
    } catch (e) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Ошибка выхода: ${e.toString()}'),
      );
    }
  }

  int getSelectedIndex(String currentPath) {
    if (currentPath.startsWith('/dashboard/employees')) {
      return 1;
    } else if (currentPath.startsWith('/dashboard/schedule')) {
      return 2;
    } else if (currentPath == '/dashboard') {
      return 0;
    }
    return 0;
  }

  /// Dispose resources
  void dispose() {
    // БЕЗОПАСНО: SafeLoadingHoursChart wrapper "заморозил" данные,
    // поэтому chart не получит уведомлений во время unmount.
    // Dispose ValueNotifier'ы с небольшой задержкой для дополнительной защиты.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      statsState.dispose();
      weeklyShiftsState.dispose();
      alertsState.dispose();
    });
  }
}
