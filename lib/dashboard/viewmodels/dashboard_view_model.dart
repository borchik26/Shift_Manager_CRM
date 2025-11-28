import 'package:flutter/material.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';

class DashboardViewModel {
  final AuthService _authService;
  final RouterService _routerService;

  DashboardViewModel({
    required AuthService authService,
    required RouterService routerService,
  })  : _authService = authService,
        _routerService = routerService;

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
}