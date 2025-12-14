import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_app/config/locator_config.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/abstractions/logging_abstraction.dart';
import 'package:logging/logging.dart';

/// Represents different states of app initialization
sealed class AppState {
  const AppState();
}

class InitializingApp extends AppState {
  final int? retryAttempt;
  const InitializingApp({this.retryAttempt});
}

class AppInitialized extends AppState {
  const AppInitialized();
}

class AppInitializationError extends AppState {
  final Object error;
  final StackTrace stackTrace;
  final int attemptsMade;
  const AppInitializationError(this.error, this.stackTrace, {this.attemptsMade = 1});
}

/// ViewModel responsible for handling app startup and initialization
class StartupViewModel {
  StartupViewModel({LoggingAbstraction? loggingAbstraction})
    : _loggingAbstraction = loggingAbstraction ?? LoggingAbstraction();

  final appStateNotifier = ValueNotifier<AppState>(const InitializingApp());

  final LoggingAbstraction _loggingAbstraction;
  StreamSubscription<LogRecord>? loggingSubscription;

  /// Максимальное количество попыток при старте
  static const _maxStartupRetries = 3;

  /// Задержка между попытками (100ms → 200ms → 400ms)
  static const _initialRetryDelay = Duration(milliseconds: 100);

  Future<void> runStartupLogic() async {
    debugPrint('🚦 Startup Logic Started');
    appStateNotifier.value = const InitializingApp();

    int attempt = 0;
    Duration currentDelay = _initialRetryDelay;
    Object? lastError;
    StackTrace? lastStackTrace;

    while (attempt < _maxStartupRetries) {
      attempt++;

      try {
        if (attempt > 1) {
          debugPrint('🔄 Retry attempt $attempt/$_maxStartupRetries...');
          appStateNotifier.value = InitializingApp(retryAttempt: attempt);
        }

        locator.reset(); // Clear before re-registering (hot restart safe)
        locator.registerMany(modules);
        loggingSubscription = _loggingAbstraction.initializeLogging();
        debugPrint('✅ Locator setup done');

        final authService = locator<AuthService>();
        final routerService = locator<RouterService>();

        debugPrint('🔄 Fetching user profile...');
        await authService.initializeAuth();
        final isLoggedIn = authService.currentUser != null;
        debugPrint('👤 User logged in? $isLoggedIn');

        if (isLoggedIn) {
          debugPrint('✅ Profile fetched');
          routerService.replaceAll([Path(name: '/dashboard')]);
        } else {
          routerService.replaceAll([Path(name: '/login')]);
        }

        appStateNotifier.value = const AppInitialized();
        return; // Success!
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        debugPrint('🛑 Startup attempt $attempt failed: $e');

        if (attempt < _maxStartupRetries) {
          await Future.delayed(currentDelay);
          currentDelay *= 2; // Exponential backoff
        }
      }
    }

    // All retries exhausted
    debugPrint('🛑 All $_maxStartupRetries startup attempts failed');
    try {
      locator<RouterService>().replaceAll([Path(name: '/login')]);
    } catch (_) {
      // If locator or router is unavailable, silently ignore and surface the error state.
    }
    appStateNotifier.value = AppInitializationError(
      lastError!,
      lastStackTrace!,
      attemptsMade: attempt,
    );
  }

  Future<void> initializeApp() async {
    await runStartupLogic();
  }

  Future<void> retryInitialization() async {
    await initializeApp(); // reset() already called inside
  }

  void dispose() {
    appStateNotifier.dispose();
    loggingSubscription?.cancel();
  }
}
