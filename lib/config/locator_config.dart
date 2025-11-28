import 'package:flutter/foundation.dart';
import 'package:my_app/core/utils/http/http_abstraction.dart';
import 'package:my_app/core/utils/http/http_interceptor.dart';
import 'package:my_app/config/route_config.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/data/services/api_service.dart';
import 'package:my_app/data/services/mock_api_service.dart';
import 'package:my_app/data/repositories/auth_repository.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';

final modules = [
  // Core Services
  Module<RouterService>(
    builder: () => RouterService(supportedRoutes: routes),
    lazy: false,
  ),
  Module<NotifyService>(builder: () => NotifyService(), lazy: false),
  Module<HttpAbstraction>(
    builder: () => HttpAbstraction(
      interceptors: [
        LoggingInterceptor(
          logBody: !kReleaseMode, // Only log bodies in debug mode
        ),
      ],
    ),
    lazy: true,
  ),

  // Data Layer - API Service
  Module<ApiService>(
    builder: () => MockApiService(),
    lazy: false,
  ),

  // Data Layer - Repositories
  Module<AuthRepository>(
    builder: () => AuthRepository(apiService: locator<ApiService>()),
    lazy: true,
  ),
  Module<EmployeeRepository>(
    builder: () => EmployeeRepository(apiService: locator<ApiService>()),
    lazy: true,
  ),
  Module<ShiftRepository>(
    builder: () => ShiftRepository(apiService: locator<ApiService>()),
    lazy: true,
  ),
];
