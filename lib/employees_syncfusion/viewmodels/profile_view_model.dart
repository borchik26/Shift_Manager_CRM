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
  final profileState = ValueNotifier<AsyncValue<EmployeeProfile>>(const AsyncLoading());

  ProfileViewModel({
    required EmployeeRepository employeeRepository,
    required ShiftRepository shiftRepository,
  })  : _employeeRepository = employeeRepository,
        _shiftRepository = shiftRepository;

  Future<void> loadProfile(String id) async {
    profileState.value = const AsyncLoading();
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      final employee = await _employeeRepository.getEmployeeById(id);
      if (employee != null) {
        // Load recent shifts for this employee
        final shifts = await _shiftRepository.getShiftsByEmployee(id);
        
        // Convert shifts to ShiftEvents and take last 5
        final recentShifts = shifts
            .map((s) => ShiftEvent.fromShift(s))
            .take(5)
            .toList();
        
        profileState.value = AsyncData(
          EmployeeProfile.fromEmployee(employee, recentShifts: recentShifts),
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

  void dispose() {
    profileState.dispose();
  }
}