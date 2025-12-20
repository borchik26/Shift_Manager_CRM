import 'package:flutter/material.dart';
import 'package:my_app/audit_logs/models/audit_log_filter.dart';
import 'package:my_app/audit_logs/models/audit_log_constants.dart';

/// Dialog for filtering audit logs
/// Allows filtering by date range, user, action type, entity type, and status
class AuditLogFilterDialog extends StatefulWidget {
  final AuditLogFilter currentFilter;
  final Function(AuditLogFilter) onApply;

  const AuditLogFilterDialog({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<AuditLogFilterDialog> createState() => _AuditLogFilterDialogState();
}

class _AuditLogFilterDialogState extends State<AuditLogFilterDialog> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String? _actionType;
  late String? _entityType;
  late String? _status;

  @override
  void initState() {
    super.initState();
    _startDate = widget.currentFilter.startDate;
    _endDate = widget.currentFilter.endDate;
    _actionType = widget.currentFilter.actionType;
    _entityType = widget.currentFilter.entityType;
    _status = widget.currentFilter.status;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Text(
                    'Фильтры логов',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filters
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date range
                      const Text(
                        'Период',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: 'От',
                              value: _startDate,
                              onChanged: (date) =>
                                  setState(() => _startDate = date),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateField(
                              label: 'До',
                              value: _endDate,
                              onChanged: (date) =>
                                  setState(() => _endDate = date),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Action type
                      const Text(
                        'Тип действия',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: _actionType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Все действия'),
                          ),
                          ...AuditLogActionType.values.map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(AuditLogActionType.getLabel(type)),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _actionType = value),
                      ),
                      const SizedBox(height: 24),

                      // Entity type
                      const Text(
                        'Тип сущности',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: _entityType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Все сущности'),
                          ),
                          ...AuditLogEntityType.values.map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(AuditLogEntityType.getLabel(type)),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _entityType = value),
                      ),
                      const SizedBox(height: 24),

                      // Status
                      const Text(
                        'Статус',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: _status,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Все статусы'),
                          ),
                          DropdownMenuItem(
                            value: 'success',
                            child: Text('Успешно'),
                          ),
                          DropdownMenuItem(
                            value: 'failure',
                            child: Text('Ошибка'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _status = value),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _actionType = null;
                        _entityType = null;
                        _status = null;
                      });
                    },
                    child: const Text('Сбросить'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final filter = AuditLogFilter(
                        startDate: _startDate,
                        endDate: _endDate,
                        actionType: _actionType,
                        entityType: _entityType,
                        status: _status,
                        searchQuery: widget.currentFilter.searchQuery,
                      );
                      widget.onApply(filter);
                    },
                    child: const Text('Применить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value != null
              ? '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}'
              : 'Не выбрано',
          style: TextStyle(
            color: value != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }
}
