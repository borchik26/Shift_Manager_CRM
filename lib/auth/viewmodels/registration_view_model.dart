import 'package:flutter/foundation.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/repositories/auth_repository.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';

/// ViewModel for user registration with role selection
class RegistrationViewModel {
  final AuthRepository _authRepository;
  final registerState = ValueNotifier<AsyncValue<void>>(const AsyncData(null));
  final selectedRole = ValueNotifier<String>('employee');
  final availableRoles = ValueNotifier<List<String>>([]);

  RegistrationViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Load available user roles on init
  Future<void> loadAvailableRoles() async {
    try {
      final roles = await _authRepository.getAvailableUserRoles();
      availableRoles.value = roles;
      // Set default to first available role
      if (roles.isNotEmpty) {
        selectedRole.value = roles.first;
      }
    } catch (e) {
      debugPrint('Failed to load roles: $e');
      // Fallback to default roles
      availableRoles.value = ['employee', 'manager'];
    }
  }

  /// Register new user
  Future<void> register(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    registerState.value = const AsyncLoading();
    try {
      final user = await _authRepository.register(
        email,
        password,
        firstName,
        lastName,
        selectedRole.value,
      );

      if (user == null) {
        throw Exception('Ошибка при создании учётной записи');
      }

      registerState.value = const AsyncData(null);

      // Show success message
      locator<NotifyService>().setToastEvent(
        ToastEventSuccess(
          message: 'Регистрация успешна! Ожидайте активации аккаунта.',
        ),
      );
    } catch (e, s) {
      registerState.value = AsyncError(e.toString(), e, s);
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Ошибка регистрации: ${e.toString()}'),
      );
    }
  }

  /// Update selected role
  void setRole(String role) {
    selectedRole.value = role;
  }

  void dispose() {
    registerState.dispose();
    selectedRole.dispose();
    availableRoles.dispose();
  }
}
