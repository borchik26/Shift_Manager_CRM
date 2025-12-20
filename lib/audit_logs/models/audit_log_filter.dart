/// Filter model for audit log queries
class AuditLogFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? userId;
  final String? actionType;
  final String? entityType;
  final String? status;
  final String? searchQuery; // Search by email or description

  const AuditLogFilter({
    this.startDate,
    this.endDate,
    this.userId,
    this.actionType,
    this.entityType,
    this.status,
    this.searchQuery,
  });

  /// Create a copy with some fields updated
  AuditLogFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? actionType,
    String? entityType,
    String? status,
    String? searchQuery,
  }) {
    return AuditLogFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userId: userId ?? this.userId,
      actionType: actionType ?? this.actionType,
      entityType: entityType ?? this.entityType,
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Check if any filter is active
  bool get hasActiveFilters {
    return startDate != null ||
        endDate != null ||
        userId != null ||
        actionType != null ||
        entityType != null ||
        status != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  /// Count of active filters
  int get activeFiltersCount {
    int count = 0;
    if (startDate != null) count++;
    if (endDate != null) count++;
    if (userId != null) count++;
    if (actionType != null) count++;
    if (entityType != null) count++;
    if (status != null) count++;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    return count;
  }

  /// Convert to JSON for API requests (if needed)
  Map<String, dynamic> toJson() {
    return {
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      if (userId != null) 'user_id': userId,
      if (actionType != null) 'action_type': actionType,
      if (entityType != null) 'entity_type': entityType,
      if (status != null) 'status': status,
      if (searchQuery != null && searchQuery!.isNotEmpty)
        'search_query': searchQuery,
    };
  }

  @override
  String toString() {
    return 'AuditLogFilter(hasActiveFilters: $hasActiveFilters, '
        'activeFiltersCount: $activeFiltersCount)';
  }
}
