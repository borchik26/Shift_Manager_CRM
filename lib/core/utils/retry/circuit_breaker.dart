import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_app/core/utils/exceptions/app_exceptions.dart';

/// Состояние Circuit Breaker
enum CircuitState {
  /// Нормальная работа - запросы проходят
  closed,

  /// Circuit открыт - все запросы fail fast
  open,

  /// Пробный режим - пропускаем один запрос для проверки
  halfOpen,
}

/// Circuit Breaker для защиты от каскадных сбоев
///
/// Паттерн:
/// 1. closed → нормальная работа
/// 2. После [failureThreshold] ошибок → open (fail fast)
/// 3. Через [openDuration] → halfOpen (пробный запрос)
/// 4. Если пробный успешен → closed, иначе → open
class CircuitBreaker {
  CircuitBreaker({
    this.failureThreshold = 5,
    this.openDuration = const Duration(seconds: 60),
  });

  /// Количество ошибок для открытия circuit
  final int failureThreshold;

  /// Время в состоянии open перед пробным запросом
  final Duration openDuration;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;

  /// Текущее состояние circuit
  CircuitState get state => _state;

  /// Количество последовательных ошибок
  int get failureCount => _failureCount;

  /// Выполняет операцию с защитой Circuit Breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    // Проверяем состояние circuit
    _checkState();

    if (_state == CircuitState.open) {
      debugPrint('⚡ CircuitBreaker: OPEN - fail fast');
      throw const CircuitBreakerOpenException();
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (error) {
      _onFailure();
      rethrow;
    }
  }

  /// Проверяет, нужно ли перейти в halfOpen
  void _checkState() {
    if (_state == CircuitState.open && _lastFailureTime != null) {
      final elapsed = DateTime.now().difference(_lastFailureTime!);
      if (elapsed >= openDuration) {
        debugPrint('⚡ CircuitBreaker: OPEN → HALF_OPEN (trying one request)');
        _state = CircuitState.halfOpen;
      }
    }
  }

  /// Обработка успешного запроса
  void _onSuccess() {
    if (_state == CircuitState.halfOpen) {
      debugPrint('⚡ CircuitBreaker: HALF_OPEN → CLOSED (success)');
    }
    _state = CircuitState.closed;
    _failureCount = 0;
    _lastFailureTime = null;
  }

  /// Обработка ошибки
  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_state == CircuitState.halfOpen) {
      debugPrint('⚡ CircuitBreaker: HALF_OPEN → OPEN (failed)');
      _state = CircuitState.open;
    } else if (_failureCount >= failureThreshold) {
      debugPrint(
        '⚡ CircuitBreaker: CLOSED → OPEN (failures: $_failureCount/$failureThreshold)',
      );
      _state = CircuitState.open;
    }
  }

  /// Сброс состояния (для тестов или ручного сброса)
  void reset() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _lastFailureTime = null;
  }
}
