import 'dart:async' as dart_async;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:my_app/core/utils/exceptions/app_exceptions.dart' as app;
import 'package:my_app/core/utils/retry/circuit_breaker.dart';
import 'package:my_app/core/utils/retry/retry_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BaseSupabaseService<T> {
  final SupabaseClient _client;
  final CircuitBreaker _circuitBreaker;
  static const _defaultTimeout = Duration(seconds: 30);

  BaseSupabaseService()
      : _client = Supabase.instance.client,
        _circuitBreaker = CircuitBreaker();

  String get tableName;
  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T item);

  @protected
  Future<R> executeWithResilience<R>(
    Future<R> Function() operation, {
    Duration timeout = _defaultTimeout,
  }) async {
    return _circuitBreaker.execute(() async {
      return RetryHandler.execute(
        operation: () => _withTimeout(operation(), timeout: timeout),
      );
    });
  }

  Future<R> _withTimeout<R>(
    Future<R> operation, {
    Duration timeout = _defaultTimeout,
  }) {
    return operation.timeout(
      timeout,
      onTimeout: () => throw const app.TimeoutException(
        'Превышено время ожидания ответа от сервера',
      ),
    );
  }

  @protected
  Never handleError(Object error, String operation) {
    if (error is app.AppException) throw error;

    if (error is AuthException) {
      throw app.AuthException('Ошибка авторизации: ${error.message}', error);
    }

    if (error is PostgrestException) {
      final code = error.code;
      final message = error.message;

      if (code == '23505' || message.contains('overlaps')) {
        throw app.ConflictException(message, error);
      }

      if (code == 'PGRST116') {
        throw app.NotFoundException('Ресурс не найден', error);
      }

      if (code == '401' || code == '403') {
        throw app.AuthException(
          'Ошибка доступа',
          error,
          int.tryParse(code ?? ''),
        );
      }

      throw app.ServerException('Ошибка базы данных: $message', error);
    }

    if (error is SocketException) {
      throw app.NetworkException(
        'Ошибка сети. Проверьте подключение к интернету.',
        error,
      );
    }

    if (error is dart_async.TimeoutException) {
      throw const app.TimeoutException(
        'Превышено время ожидания ответа от сервера',
      );
    }

    throw app.ServerException('Ошибка $operation: $error', error);
  }

  Future<List<T>> getAll() async {
    return executeWithResilience(() async {
      final response = await _client.from(tableName).select();
      return (response as List).map((json) => fromJson(json)).toList();
    });
  }

  Future<T?> getById(String id) async {
    return executeWithResilience(() async {
      final response = await _client
          .from(tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return fromJson(response);
    });
  }

  Future<T> create(Map<String, dynamic> data) async {
    return executeWithResilience(() async {
      final response = await _client
          .from(tableName)
          .insert(data)
          .select()
          .single();

      return fromJson(response);
    });
  }

  Future<T> update(String id, Map<String, dynamic> data) async {
    return executeWithResilience(() async {
      final response = await _client
          .from(tableName)
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return fromJson(response);
    });
  }

  Future<void> delete(String id) async {
    return executeWithResilience(() async {
      await _client.from(tableName).delete().eq('id', id);
    });
  }
}
