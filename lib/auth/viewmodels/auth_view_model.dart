import 'package:flutter/foundation.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';

class AuthViewModel {
  final AuthService _authService;
  final loginState = ValueNotifier<AsyncValue<void>>(const AsyncData(null));

  AuthViewModel({required AuthService authService})
      : _authService = authService;

  Future<void> login(String email, String password) async {
    loginState.value = const AsyncLoading();
    try {
      await _authService.login(email, password);
      loginState.value = const AsyncData(null);
    } catch (e, s) {
      loginState.value = AsyncError(e.toString(), e, s);
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Ошибка входа: ${e.toString()}'),
      );
    }
  }

  void dispose() {
    loginState.dispose();
  }
}