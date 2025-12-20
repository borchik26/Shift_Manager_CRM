import 'package:flutter/material.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/models/audit_log.dart';
import 'package:my_app/audit_logs/models/audit_log_filter.dart';
import 'package:my_app/data/repositories/audit_log_repository.dart';

/// ViewModel for audit logs screen
/// Manages state, filtering, pagination and loading of audit logs
class AuditLogsViewModel extends ChangeNotifier {
  final AuditLogRepository _repository;
  final AuthService _authService;

  // State
  List<AuditLog> _logs = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  AuditLogFilter _currentFilter = const AuditLogFilter();
  String? _searchQuery;

  // AsyncValue state for initial loading
  final state = ValueNotifier<AsyncValue<List<AuditLog>>>(
    const AsyncLoading(),
  );

  // Getters
  List<AuditLog> get logs => _logs;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  AuditLogFilter get currentFilter => _currentFilter;
  String? get searchQuery => _searchQuery;

  AuditLogsViewModel({
    required AuditLogRepository repository,
    required AuthService authService,
  })  : _repository = repository,
        _authService = authService {
    _loadInitialData();
  }

  /// Load initial batch of logs (500)
  Future<void> _loadInitialData() async {
    state.value = const AsyncLoading();
    try {
      final logs = await _repository.getAuditLogs(
        limit: 500,
        offset: 0,
        filter: _currentFilter,
      );

      _logs = logs;
      _hasMore = logs.length >= 500;
      state.value = AsyncData(_logs);
    } catch (e, stack) {
      debugPrint('Error loading audit logs: $e\n$stack');
      state.value = AsyncError(e.toString(), e, stack);
    }
  }

  /// Load more logs when scrolling (200 more)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final moreLogs = await _repository.getAuditLogs(
        limit: 200,
        offset: _logs.length,
        filter: _currentFilter,
      );

      _logs.addAll(moreLogs);
      _hasMore = moreLogs.length >= 200;
      state.value = AsyncData(_logs);
    } catch (e) {
      debugPrint('Error loading more logs: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Apply filter and reload data
  void applyFilter(AuditLogFilter filter) {
    _currentFilter = filter;
    _loadInitialData();
  }

  /// Set search query and reload
  void setSearchQuery(String query) {
    _searchQuery = query.isEmpty ? null : query;
    _currentFilter = _currentFilter.copyWith(searchQuery: _searchQuery);
    _loadInitialData();
  }

  /// Clear all filters and reload
  void clearFilters() {
    _currentFilter = const AuditLogFilter();
    _searchQuery = null;
    _loadInitialData();
  }

  /// Refresh logs (pull to refresh)
  Future<void> refresh() async {
    return _loadInitialData();
  }

  /// Count of active filters
  int get activeFiltersCount {
    int count = 0;
    if (_currentFilter.userId != null) count++;
    if (_currentFilter.actionType != null) count++;
    if (_currentFilter.entityType != null) count++;
    if (_currentFilter.status != null) count++;
    if (_currentFilter.startDate != null) count++;
    if (_currentFilter.endDate != null) count++;
    if (_searchQuery != null && _searchQuery!.isNotEmpty) count++;
    return count;
  }

  /// Check if user is manager (for access control)
  bool get isManager => _authService.isManager;

  /// Delete all audit logs
  ///
  /// WARNING: This action is irreversible!
  /// Should be called only after user confirmation
  Future<void> deleteAllLogs() async {
    state.value = const AsyncLoading();
    try {
      await _repository.deleteAllAuditLogs();

      // Clear local state
      _logs.clear();
      _hasMore = false;

      state.value = AsyncData(_logs);
      notifyListeners();
    } catch (e, stack) {
      debugPrint('Error deleting all logs: $e\n$stack');
      state.value = AsyncError(e.toString(), e, stack);
      // Reload data to show current state
      await _loadInitialData();
    }
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }
}
