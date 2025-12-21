import 'package:flutter/foundation.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';

class AuthViewModel {
  final AuthService _authService;
  final RouterService _routerService;
  final loginState = ValueNotifier<AsyncValue<void>>(const AsyncData(null));

  AuthViewModel({
    required AuthService authService,
    required RouterService routerService,
  })  : _authService = authService,
        _routerService = routerService;

  Future<void> login(String email, String password) async {
    loginState.value = const AsyncLoading();
    try {
      await _authService.login(email, password);
      loginState.value = const AsyncData(null);
      _routerService.replace(Path(name: '/dashboard'));
    } catch (e, s) {
      loginState.value = AsyncError(e.toString(), e, s);
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Ошибка входа: ${e.toString()}'),
      );
    }
  }

  void navigateToRegister() {
    _routerService.replace(Path(name: '/register'));
  }

  void dispose() {
    loginState.dispose();
  }
}