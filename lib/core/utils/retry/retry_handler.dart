import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:my_app/core/utils/exceptions/app_exceptions.dart';

/// Handler для retry с экспоненциальным backoff
class RetryHandler {
  /// Выполняет операцию с автоматическими retry
  ///
  /// [operation] - операция для выполнения
  /// [maxRetries] - максимальное количество попыток (по умолчанию 3)
  /// [initialDelay] - начальная задержка (по умолчанию 100ms)
  /// [backoffMultiplier] - множитель для экспоненциального backoff (по умолчанию 2.0)
  /// [shouldRetry] - функция для определения, нужен ли retry
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
    double backoffMultiplier = 2.0,
    bool Function(Object error)? shouldRetry,
  }) async {
    shouldRetry ??= _defaultShouldRetry;

    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        if (attempt >= maxRetries || !shouldRetry(error)) {
          rethrow;
        }

        debugPrint(
          '⚠️ RetryHandler: Attempt $attempt failed, retrying in ${currentDelay.inMilliseconds}ms...',
        );

        await Future.delayed(currentDelay);
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffMultiplier).toInt(),
        );
      }
    }
  }

  /// Определяет, стоит ли повторять операцию
  ///
  /// Retry для:
  /// - NetworkException (проблемы с сетью)
  /// - TimeoutException (таймаут)
  /// - ServerException (5xx ошибки сервера)
  /// - SocketException (проблемы с сокетом)
  ///
  /// НЕ retry для:
  /// - AuthException (401/403) - требуется повторный логин
  /// - ValidationException - данные неверны
  /// - ConflictException - конфликт данных
  /// - NotFoundException - ресурс не существует
  static bool _defaultShouldRetry(Object error) {
    if (error is NetworkException) return true;
    if (error is TimeoutException) return true;
    if (error is ServerException) return true;
    if (error is SocketException) return true;

    // Для стандартных исключений Dart
    if (error is SocketException) return true;

    // НЕ делаем retry для этих типов
    if (error is AuthException) return false;
    if (error is ValidationException) return false;
    if (error is ConflictException) return false;
    if (error is NotFoundException) return false;
    if (error is CircuitBreakerOpenException) return false;

    // По умолчанию не делаем retry для неизвестных ошибок
    return false;
  }
}
