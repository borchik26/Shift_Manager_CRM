import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/data/models/audit_log.dart';
import 'package:my_app/audit_logs/models/audit_log_constants.dart';
import 'package:my_app/audit_logs/widgets/changes_diff_widget.dart';

/// Dialog for displaying detailed audit log information
/// Shows all log fields including changes diff
class AuditLogDetailDialog extends StatelessWidget {
  final AuditLog log;

  const AuditLogDetailDialog({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Детали лога',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic info
                    _buildInfoCard(
                      title: 'Основная информация',
                      children: [
                        _buildInfoRow(
                          label: 'Дата и время',
                          value: DateFormat('dd.MM.yyyy HH:mm:ss')
                              .format(log.createdAt),
                          icon: Icons.access_time,
                        ),
                        _buildInfoRow(
                          label: 'Действие',
                          value: AuditLogActionType.getLabel(log.actionType ?? 'unknown'),
                          icon: Icons.flash_on,
                          valueColor: _getActionColor(log.actionType ?? 'unknown'),
                        ),
                        _buildInfoRow(
                          label: 'Сущность',
                          value: AuditLogEntityType.getLabel(log.entityType ?? 'unknown'),
                          icon: Icons.category,
                        ),
                        if (log.entityId != null)
                          _buildInfoRow(
                            label: 'ID сущности',
                            value: log.entityId!,
                            icon: Icons.fingerprint,
                            valueStyle: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        _buildInfoRow(
                          label: 'Статус',
                          value: AuditLogStatus.getLabel(log.status ?? 'success'),
                          icon: Icons.check_circle,
                          valueColor: log.status == 'success'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // User info
                    _buildInfoCard(
                      title: 'Информация о пользователе',
                      children: [
                        _buildInfoRow(
                          label: 'Email',
                          value: log.userEmail ?? 'unknown',
                          icon: Icons.email,
                        ),
                        if (log.userName != null)
                          _buildInfoRow(
                            label: 'Имя',
                            value: log.userName!,
                            icon: Icons.person,
                          ),
                        _buildInfoRow(
                          label: 'Роль',
                          value: log.userRole == 'manager'
                              ? 'Менеджер'
                              : 'Сотрудник',
                          icon: Icons.badge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    if (log.description?.isNotEmpty ?? false)
                      _buildInfoCard(
                        title: 'Описание',
                        children: [
                          Text(
                            log.description!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    if (log.description?.isNotEmpty ?? false)
                      const SizedBox(height: 24),

                    // Changes diff
                    if (log.changes != null && log.changes!.isNotEmpty)
                      _buildInfoCard(
                        title: 'Изменения',
                        children: [
                          ChangesDiffWidget(changes: log.changes!),
                        ],
                      ),
                    if (log.changes != null && log.changes!.isNotEmpty)
                      const SizedBox(height: 24),

                    // Metadata
                    if (log.metadata != null && log.metadata!.isNotEmpty)
                      _buildInfoCard(
                        title: 'Метаданные',
                        children: [
                          _buildMetadataView(log.metadata!),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: valueStyle ??
                    TextStyle(
                      color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight:
                          valueColor != null ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataView(Map<String, dynamic> metadata) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: metadata.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key}:',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getActionColor(String actionType) {
    switch (actionType) {
      case AuditLogActionType.create:
        return Colors.green;
      case AuditLogActionType.update:
        return Colors.blue;
      case AuditLogActionType.delete:
        return Colors.red;
      case AuditLogActionType.login:
        return Colors.teal;
      case AuditLogActionType.logout:
        return Colors.orange;
      case AuditLogActionType.approve:
        return Colors.green;
      case AuditLogActionType.reject:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
