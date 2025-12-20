import 'dart:async' as dart_async;

import 'package:flutter/foundation.dart';
import 'package:my_app/audit_logs/models/audit_log_filter.dart';
import 'package:my_app/core/utils/exceptions/app_exceptions.dart' as app;
import 'package:my_app/core/utils/retry/circuit_breaker.dart';
import 'package:my_app/core/utils/retry/retry_handler.dart';
import 'package:my_app/data/models/audit_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuditService {
  final SupabaseClient _client;
  final CircuitBreaker _circuitBreaker;
  static const _defaultTimeout = Duration(seconds: 30);

  AuditService()
      : _client = Supabase.instance.client,
        _circuitBreaker = CircuitBreaker();

  Future<T> _executeWithResilience<T>(
    Future<T> Function() operation, {
    Duration timeout = _defaultTimeout,
  }) async {
    return _circuitBreaker.execute(() async {
      return RetryHandler.execute(
        operation: () => _withTimeout(operation(), timeout: timeout),
      );
    });
  }

  Future<T> _withTimeout<T>(
    Future<T> operation, {
    Duration timeout = _defaultTimeout,
  }) {
    return operation.timeout(
      timeout,
      onTimeout: () => throw const app.TimeoutException(
        'Превышено время ожидания ответа от сервера',
      ),
    );
  }

  Never _handleError(Object error, String operation) {
    if (error is app.AppException) throw error;
    throw app.ServerException('Ошибка $operation: $error', error);
  }

  Future<List<AuditLog>> getAuditLogs({
    int limit = 500,
    int offset = 0,
    AuditLogFilter? filter,
  }) async {
    try {
      return await _executeWithResilience(() async {
        var query = _client.from('audit_logs').select();

        if (filter != null) {
          if (filter.userId != null) {
            query = query.eq('user_id', filter.userId!);
          }
          if (filter.actionType != null) {
            query = query.eq('action_type', filter.actionType!);
          }
          if (filter.entityType != null) {
            query = query.eq('entity_type', filter.entityType!);
          }
          if (filter.status != null) {
            query = query.eq('status', filter.status!);
          }
          if (filter.startDate != null) {
            query = query.gte(
              'created_at',
              filter.startDate!.toIso8601String(),
            );
          }
          if (filter.endDate != null) {
            query = query.lte('created_at', filter.endDate!.toIso8601String());
          }
          if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
            query = query.or(
              'user_email.ilike.%${filter.searchQuery}%,description.ilike.%${filter.searchQuery}%',
            );
          }
        }

        final response = await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        return (response as List)
            .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      _handleError(e, 'getAuditLogs');
    }
  }

  Future<void> deleteAllAuditLogs() async {
    try {
      await _executeWithResilience(() async {
        await _client
            .from('audit_logs')
            .delete()
            .gte('created_at', '2000-01-01T00:00:00.000Z');
      });
    } catch (e) {
      _handleError(e, 'deleteAllAuditLogs');
    }
  }

  void logAuditEvent({
    required String actionType,
    required String entityType,
    String? entityId,
    String? description,
    Map<String, dynamic>? changesBefore,
    Map<String, dynamic>? changesAfter,
    Map<String, dynamic>? metadata,
  }) {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return;

    dart_async.unawaited(
      _client
          .rpc(
            'log_audit_event',
            params: {
              'p_user_id': currentUser.id,
              'p_user_email': currentUser.email ?? 'unknown',
              'p_action_type': actionType,
              'p_entity_type': entityType,
              'p_user_name': currentUser.userMetadata?['full_name'],
              'p_user_role': currentUser.userMetadata?['role'] ?? 'employee',
              'p_entity_id': entityId,
              'p_status': 'success',
              'p_description': description ?? '$actionType $entityType',
              'p_changes': changesBefore != null && changesAfter != null
                  ? {'before': changesBefore, 'after': changesAfter}
                  : null,
              'p_metadata': metadata,
            },
          )
          .catchError((e) {
            debugPrint('Failed to log audit event: $e');
          }),
    );
  }
}
