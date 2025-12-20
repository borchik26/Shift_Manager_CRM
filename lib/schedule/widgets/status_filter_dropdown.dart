import 'package:flutter/material.dart';
import 'package:my_app/schedule/models/shift_status_filter.dart';

/// Dropdown фильтр для выбора статуса смены
class StatusFilterDropdown extends StatelessWidget {
  const StatusFilterDropdown({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final ShiftStatusFilter selectedFilter;
  final void Function(ShiftStatusFilter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButton<ShiftStatusFilter>(
        value: selectedFilter,
        isDense: true,
        hint: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Статус',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        items: ShiftStatusFilter.values.map((filter) {
          IconData icon;
          Color iconColor;

          switch (filter) {
            case ShiftStatusFilter.all:
              icon = Icons.check_circle_outline;
              iconColor = Colors.grey.shade600;
              break;
            case ShiftStatusFilter.withConflicts:
              icon = Icons.error;
              iconColor = Colors.red;
              break;
            case ShiftStatusFilter.withWarnings:
              icon = Icons.warning;
              iconColor = Colors.orange;
              break;
            case ShiftStatusFilter.normal:
              icon = Icons.check_circle;
              iconColor = Colors.green;
              break;
          }

          return DropdownMenuItem<ShiftStatusFilter>(
            value: filter,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  filter.label,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            onFilterChanged(value);
          }
        },
        selectedItemBuilder: (context) {
          return ShiftStatusFilter.values.map((filter) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Text(
                  filter.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }
}
