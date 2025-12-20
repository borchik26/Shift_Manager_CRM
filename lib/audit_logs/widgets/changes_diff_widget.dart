import 'package:flutter/material.dart';
import 'dart:convert';

/// Widget for displaying changes diff (before/after comparison)
/// Visualizes what changed in an audit log entry
class ChangesDiffWidget extends StatelessWidget {
  final Map<String, dynamic> changes;

  const ChangesDiffWidget({
    super.key,
    required this.changes,
  });

  @override
  Widget build(BuildContext context) {
    final before = changes['before'] as Map<String, dynamic>?;
    final after = changes['after'] as Map<String, dynamic>?;

    // If only "after" exists, it's a create operation
    if (before == null && after != null) {
      return _buildCreateView(after);
    }

    // If only "before" exists, it's a delete operation
    if (before != null && after == null) {
      return _buildDeleteView(before);
    }

    // If both exist, it's an update operation - show diff
    if (before != null && after != null) {
      return _buildUpdateView(before, after);
    }

    // No changes data
    return const Text(
      'Нет данных об изменениях',
      style: TextStyle(color: Colors.grey),
    );
  }

  Widget _buildCreateView(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle, size: 20, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'Созданные данные',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDataTable(data, Colors.green),
        ],
      ),
    );
  }

  Widget _buildDeleteView(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.remove_circle, size: 20, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                'Удаленные данные',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDataTable(data, Colors.red),
        ],
      ),
    );
  }

  Widget _buildUpdateView(
      Map<String, dynamic> before, Map<String, dynamic> after) {
    // Find changed fields
    final changedFields = <String>[];
    final allKeys = {...before.keys, ...after.keys};

    for (final key in allKeys) {
      final beforeValue = before[key];
      final afterValue = after[key];

      if (beforeValue != afterValue) {
        changedFields.add(key);
      }
    }

    if (changedFields.isEmpty) {
      return const Text(
        'Изменений не обнаружено',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: changedFields.map((field) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFieldDiff(
            field: field,
            before: before[field],
            after: after[field],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFieldDiff({
    required String field,
    required dynamic before,
    required dynamic after,
  }) {
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field name header
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _formatFieldName(field),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Before value
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'Было',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatValue(before),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // After value
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'Стало',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatValue(after),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(Map<String, dynamic> data, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 150,
                child: Text(
                  _formatFieldName(entry.key),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _formatValue(entry.value),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatFieldName(String fieldName) {
    // Convert snake_case to readable format
    return fieldName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value == null) {
      return '(пусто)';
    }

    if (value is String) {
      return value.isEmpty ? '(пустая строка)' : value;
    }

    if (value is bool) {
      return value ? 'Да' : 'Нет';
    }

    if (value is Map || value is List) {
      try {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(value);
      } catch (e) {
        return value.toString();
      }
    }

    return value.toString();
  }
}
