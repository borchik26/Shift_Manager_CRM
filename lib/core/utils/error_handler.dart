import 'package:flutter/material.dart';
import 'package:my_app/core/utils/exceptions/app_exceptions.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';

/// Global error handler for the application
class ErrorHandler {
  static void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    NotifyService? notifyService,
  }) {
    // Log error (in production, send to crash reporting service)
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }

    // Show user-friendly error message
    if (notifyService != null) {
      final message = _getUserFriendlyMessage(error);
      notifyService.setToastEvent(ToastEventError(message: message));
    }
  }

  static String _getUserFriendlyMessage(dynamic error) {
    // Типизированные исключения — предпочтительный путь
    if (error is NetworkException) {
      return 'Ошибка сети. Проверьте подключение к интернету.';
    }

    if (error is TimeoutException) {
      return 'Превышено время ожидания. Попробуйте позже.';
    }

    if (error is AuthException) {
      return 'Ошибка авторизации. Войдите в систему снова.';
    }

    if (error is ServerException) {
      return 'Ошибка сервера. Попробуйте позже.';
    }

    if (error is ValidationException) {
      return error.message; // Валидация обычно имеет понятное сообщение
    }

    if (error is ConflictException) {
      return error.message; // Конфликт обычно имеет понятное сообщение
    }

    if (error is NotFoundException) {
      return 'Ресурс не найден.';
    }

    if (error is CircuitBreakerOpenException) {
      return 'Сервис временно недоступен. Попробуйте через минуту.';
    }

    // Fallback для строковых ошибок (совместимость)
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Ошибка сети. Проверьте подключение к интернету.';
    }

    if (errorString.contains('timeout')) {
      return 'Превышено время ожидания. Попробуйте позже.';
    }

    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Ошибка авторизации. Войдите в систему снова.';
    }

    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'Доступ запрещён.';
    }

    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Ресурс не найден.';
    }

    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Ошибка сервера. Попробуйте позже.';
    }

    // Generic error message
    return 'Произошла ошибка. Попробуйте снова.';
  }

  /// Handle async operations with error handling
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    NotifyService? notifyService,
    String? errorMessage,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleError(error, stackTrace: stackTrace, notifyService: notifyService);
      if (errorMessage != null && notifyService != null) {
        notifyService.setToastEvent(ToastEventError(message: errorMessage));
      }
      return null;
    }
  }
}