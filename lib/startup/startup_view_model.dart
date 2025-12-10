import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_app/config/locator_config.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/abstractions/logging_abstraction.dart';
import 'package:logging/logging.dart';

/// Represents different states of app initialization
sealed class AppState {
  const AppState();
}

class InitializingApp extends AppState {
  const InitializingApp();
}

class AppInitialized extends AppState {
  const AppInitialized();
}

class AppInitializationError extends AppState {
  final Object error;
  final StackTrace stackTrace;
  const AppInitializationError(this.error, this.stackTrace);
}

/// ViewModel responsible for handling app startup and initialization
class StartupViewModel {
  StartupViewModel({LoggingAbstraction? loggingAbstraction})
    : _loggingAbstraction = loggingAbstraction ?? LoggingAbstraction();

  final appStateNotifier = ValueNotifier<AppState>(const InitializingApp());

  final LoggingAbstraction _loggingAbstraction;
  StreamSubscription<LogRecord>? loggingSubscription;

  Future<void> initializeApp() async {
    appStateNotifier.value = const InitializingApp();
    try {
      locator.reset(); // Clear before re-registering (hot restart safe)
      locator.registerMany(modules);
      loggingSubscription = _loggingAbstraction.initializeLogging();
      appStateNotifier.value = const AppInitialized();
    } catch (e, st) {
      appStateNotifier.value = AppInitializationError(e, st);
    }
  }

  Future<void> retryInitialization() async {
    await initializeApp(); // reset() already called inside
  }

  void dispose() {
    appStateNotifier.dispose();
    loggingSubscription?.cancel();
  }
}
