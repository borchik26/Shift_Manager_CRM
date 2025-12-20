import 'package:my_app/data/models/audit_log.dart';
import 'package:my_app/audit_logs/models/audit_log_filter.dart';
import 'package:my_app/data/services/api_service.dart';

/// Repository for audit log operations
/// Provides clean interface for accessing audit logs data
class AuditLogRepository {
  final ApiService _apiService;

  AuditLogRepository({required ApiService apiService})
      : _apiService = apiService;

  /// Get audit logs with optional filtering and pagination
  ///
  /// Parameters:
  /// - [limit]: Maximum number of logs to return (default: 500)
  /// - [offset]: Number of logs to skip for pagination (default: 0)
  /// - [filter]: Optional filter criteria (date range, user, action type, etc.)
  ///
  /// Returns list of audit logs sorted by created_at descending (newest first)
  Future<List<AuditLog>> getAuditLogs({
    int limit = 500,
    int offset = 0,
    AuditLogFilter? filter,
  }) {
    return _apiService.getAuditLogs(
      limit: limit,
      offset: offset,
      filter: filter,
    );
  }

  /// Get audit logs for a specific entity
  ///
  /// Example: Get all logs for a specific shift
  /// ```dart
  /// final logs = await repository.getLogsForEntity(
  ///   entityType: 'shift',
  ///   entityId: 'shift-uuid-123',
  /// );
  /// ```
  Future<List<AuditLog>> getLogsForEntity({
    required String entityType,
    required String entityId,
    int limit = 100,
  }) {
    final filter = AuditLogFilter(
      entityType: entityType,
    );

    return getAuditLogs(limit: limit, filter: filter);
  }

  /// Get audit logs for a specific user
  ///
  /// Example: Get all actions performed by a user
  /// ```dart
  /// final logs = await repository.getLogsForUser(userId: 'user-uuid-123');
  /// ```
  Future<List<AuditLog>> getLogsForUser({
    required String userId,
    int limit = 500,
  }) {
    final filter = AuditLogFilter(userId: userId);
    return getAuditLogs(limit: limit, filter: filter);
  }

  /// Get recent audit logs (last N logs)
  ///
  /// Useful for displaying recent activity in dashboards
  Future<List<AuditLog>> getRecentLogs({int limit = 50}) {
    return getAuditLogs(limit: limit);
  }

  /// Get audit logs by action type
  ///
  /// Example: Get all delete operations
  /// ```dart
  /// final deleteLogs = await repository.getLogsByAction(actionType: 'delete');
  /// ```
  Future<List<AuditLog>> getLogsByAction({
    required String actionType,
    int limit = 500,
  }) {
    final filter = AuditLogFilter(actionType: actionType);
    return getAuditLogs(limit: limit, filter: filter);
  }

  /// Get audit logs within a date range
  ///
  /// Example: Get logs from last week
  /// ```dart
  /// final logs = await repository.getLogsByDateRange(
  ///   startDate: DateTime.now().subtract(Duration(days: 7)),
  ///   endDate: DateTime.now(),
  /// );
  /// ```
  Future<List<AuditLog>> getLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 500,
  }) {
    final filter = AuditLogFilter(
      startDate: startDate,
      endDate: endDate,
    );
    return getAuditLogs(limit: limit, filter: filter);
  }

  /// Delete all audit logs
  ///
  /// WARNING: This action is irreversible!
  /// Use with caution, typically only for managers
  Future<void> deleteAllAuditLogs() {
    return _apiService.deleteAllAuditLogs();
  }
}
