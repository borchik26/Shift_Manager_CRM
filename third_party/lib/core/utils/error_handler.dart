import 'package:flutter/material.dart';
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
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Network error. Please check your connection.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }

    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Unauthorized. Please login again.';
    }

    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'Access denied.';
    }

    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Resource not found.';
    }

    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error. Please try again later.';
    }

    // Generic error message
    return 'An error occurred. Please try again.';
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