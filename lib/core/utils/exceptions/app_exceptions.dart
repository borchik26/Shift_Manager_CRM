/// Типизированные исключения приложения
sealed class AppException implements Exception {
  final String message;
  final Object? originalError;

  const AppException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// Ошибка сети (нет интернета, DNS, etc)
class NetworkException extends AppException {
  const NetworkException(super.message, [super.originalError]);
}

/// Превышено время ожидания
class TimeoutException extends AppException {
  const TimeoutException(super.message, [super.originalError]);
}

/// Ошибка авторизации (401, 403)
class AuthException extends AppException {
  final int? statusCode;
  const AuthException(super.message, [super.originalError, this.statusCode]);
}

/// Ошибка сервера (5xx)
class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, [super.originalError, this.statusCode]);
}

/// Ошибка валидации (400, неверные данные)
class ValidationException extends AppException {
  const ValidationException(super.message, [super.originalError]);
}

/// Конфликт данных (409, overlap смен, дубликаты)
class ConflictException extends AppException {
  const ConflictException(super.message, [super.originalError]);
}

/// Ресурс не найден (404)
class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.originalError]);
}

/// Circuit breaker открыт - сервис временно недоступен
class CircuitBreakerOpenException extends AppException {
  const CircuitBreakerOpenException()
      : super('Сервис временно недоступен. Попробуйте позже.');
}
