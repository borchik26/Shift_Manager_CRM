import 'package:flutter/foundation.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/employees/models/profile_model.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';

class ProfileViewModel {
  final EmployeeRepository _employeeRepository;
  final profileState = ValueNotifier<AsyncValue<EmployeeProfile>>(const AsyncLoading());

  ProfileViewModel({required EmployeeRepository employeeRepository})
      : _employeeRepository = employeeRepository;

  Future<void> loadProfile(String id) async {
    profileState.value = const AsyncLoading();
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      final employee = await _employeeRepository.getEmployeeById(id);
      if (employee != null) {
        profileState.value = AsyncData(EmployeeProfile.fromEmployee(employee));
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