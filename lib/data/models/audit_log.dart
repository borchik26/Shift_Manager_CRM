/// Audit log model representing a single audit event in the system
/// Tracks all CRUD operations, authentication events, and user actions
class AuditLog {
  /// Unique identifier (UUID)
  final String id;

  // User information
  final String? userId;
  final String? userEmail;
  final String? userName;
  final String? userRole; // 'manager' or 'employee'

  // Action details
  final String? actionType; // create, update, delete, login, logout, etc.
  final String? entityType; // shift, employee, branch, position, user, auth
  final String? entityId; // ID of the affected object (nullable for auth events)

  // Operation result
  final String? status; // 'success' or 'failed'
  final String? description; // Human-readable description

  // Changes tracking (for update operations)
  final Map<String, dynamic>? changes; // {"before": {...}, "after": {...}}

  // Additional context
  final Map<String, dynamic>? metadata; // IP, platform, source, etc.

  // Timestamp
  final DateTime createdAt;

  const AuditLog({
    required this.id,
    this.userId,
    this.userEmail,
    this.userName,
    this.userRole,
    this.actionType,
    this.entityType,
    this.entityId,
    this.status,
    this.description,
    this.changes,
    this.metadata,
    required this.createdAt,
  });

  /// Create AuditLog from JSON (from Supabase)
  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      userEmail: json['user_email'] as String?,
      userName: json['user_name'] as String?,
      userRole: json['user_role'] as String?,
      actionType: json['action_type'] as String?,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      status: json['status'] as String?,
      description: json['description'] as String?,
      changes: json['changes'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert AuditLog to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName,
      'user_role': userRole,
      'action_type': actionType,
      'entity_type': entityType,
      'entity_id': entityId,
      'status': status,
      'description': description,
      'changes': changes,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with some fields updated
  AuditLog copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? userRole,
    String? actionType,
    String? entityType,
    String? entityId,
    String? status,
    String? description,
    Map<String, dynamic>? changes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return AuditLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      actionType: actionType ?? this.actionType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      status: status ?? this.status,
      description: description ?? this.description,
      changes: changes ?? this.changes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AuditLog(id: $id, actionType: ${actionType ?? 'unknown'}, entityType: ${entityType ?? 'unknown'}, '
        'userEmail: ${userEmail ?? 'unknown'}, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuditLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
