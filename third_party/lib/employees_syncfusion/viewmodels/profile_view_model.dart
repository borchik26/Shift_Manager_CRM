import 'package:flutter/foundation.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/employees_syncfusion/models/profile_model.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';

class ProfileViewModel {
  final EmployeeRepository _employeeRepository;
  final ShiftRepository _shiftRepository;
  final profileState = ValueNotifier<AsyncValue<EmployeeProfile>>(
    const AsyncLoading(),
  );

  // Filter state
  String? _selectedLocationFilter;
  ShiftType? _selectedShiftTypeFilter;
  List<ShiftEvent> _allShifts = [];

  ProfileViewModel({
    required EmployeeRepository employeeRepository,
    required ShiftRepository shiftRepository,
  }) : _employeeRepository = employeeRepository,
       _shiftRepository = shiftRepository;

  String? get selectedLocationFilter => _selectedLocationFilter;
  ShiftType? get selectedShiftTypeFilter => _selectedShiftTypeFilter;

  void setLocationFilter(String? location) {
    _selectedLocationFilter = location;
    _applyFilters();
  }

  void setShiftTypeFilter(ShiftType? shiftType) {
    _selectedShiftTypeFilter = shiftType;
    _applyFilters();
  }

  void clearFilters() {
    _selectedLocationFilter = null;
    _selectedShiftTypeFilter = null;
    _applyFilters();
  }

  void _applyFilters() {
    final currentProfile = profileState.value.dataOrNull;
    if (currentProfile == null) return;

    var filteredShifts = List<ShiftEvent>.from(_allShifts);

    if (_selectedLocationFilter != null) {
      filteredShifts = filteredShifts
          .where((s) => s.location == _selectedLocationFilter)
          .toList();
    }

    if (_selectedShiftTypeFilter != null) {
      filteredShifts = filteredShifts
          .where((s) => s.shiftType == _selectedShiftTypeFilter)
          .toList();
    }

    // Recalculate stats with filtered shifts
    final workedHours = filteredShifts.fold<double>(
      0.0,
      (sum, shift) => sum + shift.durationHours,
    );

    final locationStats = EmployeeProfile.calculateLocationStats(
      filteredShifts,
      workedHours,
    );
    final weekGroups = EmployeeProfile.groupShiftsByWeek(filteredShifts);
    final totalShifts = filteredShifts.length;
    final averageShiftHours = totalShifts > 0
        ? (filteredShifts.fold<double>(0, (sum, s) => sum + s.durationHours) /
                  totalShifts)
              .toDouble()
        : 0.0;
    final nightShiftsCount = filteredShifts
        .where((s) => s.shiftType == ShiftType.night)
        .length;

    // Create new profile with filtered data
    final newProfile = EmployeeProfile(
      id: currentProfile.id,
      name: currentProfile.name,
      role: currentProfile.role,
      avatarUrl: currentProfile.avatarUrl,
      email: currentProfile.email,
      phone: currentProfile.phone,
      address: currentProfile.address,
      branch: currentProfile.branch,
      hireDate: currentProfile.hireDate,
      history: currentProfile.history,
      recentShifts: filteredShifts,
      workedHours: workedHours,
      totalHours: currentProfile.totalHours,
      locationStats: locationStats,
      averageShiftHours: averageShiftHours,
      totalShifts: totalShifts,
      nightShiftsCount: nightShiftsCount,
      weekGroups: weekGroups,
      hourlyRate: currentProfile.hourlyRate,
      calculatedSalary: workedHours * currentProfile.hourlyRate,
    );

    profileState.value = AsyncData(newProfile);
  }

  Future<void> loadProfile(String id) async {
    profileState.value = const AsyncLoading();
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      final employee = await _employeeRepository.getEmployeeById(id);
      if (employee != null) {
        // Load recent shifts for this employee
        final shifts = await _shiftRepository.getShiftsByEmployee(id);

        // Convert shifts to ShiftEvents and sort by date (newest first)
        final recentShifts = shifts.map((s) => ShiftEvent.fromShift(s)).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        // Store all shifts for filtering
        _allShifts = List.from(recentShifts);

        // Calculate worked hours from actual shifts
        final workedHours = shifts.fold<double>(
          0.0,
          (sum, shift) =>
              sum + shift.endTime.difference(shift.startTime).inMinutes / 60.0,
        );

        profileState.value = AsyncData(
          EmployeeProfile.fromEmployee(
            employee,
            recentShifts: recentShifts,
            workedHours: workedHours,
          ),
        );
      } else {
        profileState.value = const AsyncError('Сотрудник не найден');
        locator<NotifyService>().setToastEvent(
          ToastEventError(message: 'Сотрудник не найден'),
        );
      }
    } catch (e, s) {
      profileState.value = AsyncError(e.toString(), e, s);
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Ошибка загрузки профиля: ${e.toString()}'),
      );
    }
  }

  Future<void> updateEmployeePosition(
    String employeeId,
    String newPosition,
  ) async {
    try {
      final currentProfile = profileState.value.dataOrNull;
      if (currentProfile == null) return;

      // Get the current employee
      final employee = await _employeeRepository.getEmployeeById(employeeId);
      if (employee == null) {
        locator<NotifyService>().setToastEvent(
          ToastEventError(message: 'Сотрудник не найден'),
        );
        return;
      }

      // Update employee position
      final updatedEmployee = employee.copyWith(position: newPosition);
      await _employeeRepository.updateEmployee(updatedEmployee);

      // Get new hourly rate based on position
      final newRate = EmployeeProfile.positionRates[newPosition] ?? 400.0;

      // Recalculate salary with new rate
      final updatedProfile = EmployeeProfile(
        id: currentProfile.id,
        name: currentProfile.name,
        role: newPosition,
        avatarUrl: currentProfile.avatarUrl,
        email: currentProfile.email,
        phone: currentProfile.phone,
        address: currentProfile.address,
        branch: currentProfile.branch,
        hireDate: currentProfile.hireDate,
        history: currentProfile.history,
        recentShifts: currentProfile.recentShifts,
        workedHours: currentProfile.workedHours,
        totalHours: currentProfile.totalHours,
        locationStats: currentProfile.locationStats,
        averageShiftHours: currentProfile.averageShiftHours,
        totalShifts: currentProfile.totalShifts,
        nightShiftsCount: currentProfile.nightShiftsCount,
        weekGroups: currentProfile.weekGroups,
        hourlyRate: newRate,
        calculatedSalary: currentProfile.workedHours * newRate,
      );

      profileState.value = AsyncData(updatedProfile);

      locator<NotifyService>().setToastEvent(
        ToastEventSuccess(
          message: 'Должность изменена на "$newPosition". Ставка: $newRate ₽/ч',
        ),
      );
    } catch (e) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Ошибка обновления: ${e.toString()}'),
      );
    }
  }

  Future<void> updateEmployee({
    required String employeeId,
    required String firstName,
    required String lastName,
    required String position,
    required String branch,
    required String status,
    required DateTime hireDate,
    String? email,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final currentProfile = profileState.value.dataOrNull;
      if (currentProfile == null) return;

      // Get the current employee
      final employee = await _employeeRepository.getEmployeeById(employeeId);
      if (employee == null) {
        locator<NotifyService>().setToastEvent(
          ToastEventError(message: 'Сотрудник не найден'),
        );
        return;
      }

      // Create updated employee
      final updatedEmployee = employee.copyWith(
        firstName: firstName,
        lastName: lastName,
        position: position,
        branch: branch,
        status: status,
        hireDate: hireDate,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl,
      );

      // Update via repository
      await _employeeRepository.updateEmployee(updatedEmployee);

      // Get new hourly rate based on position
      final newRate = EmployeeProfile.positionRates[position] ?? 400.0;

      // Reload shifts to ensure consistency
      final shifts = await _shiftRepository.getShiftsByEmployee(employeeId);
      final recentShifts = shifts.map((s) => ShiftEvent.fromShift(s)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      _allShifts = List.from(recentShifts);

      final workedHours = shifts.fold<double>(
        0.0,
        (sum, shift) =>
            sum + shift.endTime.difference(shift.startTime).inMinutes / 60.0,
      );

      // Create updated profile
      final updatedProfile = EmployeeProfile.fromEmployee(
        updatedEmployee,
        recentShifts: recentShifts,
        workedHours: workedHours,
        hourlyRate: newRate,
      );

      profileState.value = AsyncData(updatedProfile);

      locator<NotifyService>().setToastEvent(
        ToastEventSuccess(message: 'Профиль успешно обновлён'),
      );
    } catch (e) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Ошибка обновления: ${e.toString()}'),
      );
    }
  }

  void dispose() {
    profileState.dispose();
  }
}
