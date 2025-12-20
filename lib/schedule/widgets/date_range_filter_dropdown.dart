import 'package:flutter/material.dart';
import 'package:my_app/schedule/models/date_range_filter.dart';

/// Dropdown фильтр для выбора периода времени
class DateRangeFilterDropdown extends StatelessWidget {
  const DateRangeFilterDropdown({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final DateRangeFilter selectedFilter;
  final void Function(DateRangeFilter) onFilterChanged;

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
      child: DropdownButton<DateRangeFilter>(
        value: selectedFilter,
        isDense: true,
        hint: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.date_range,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Период',
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
        items: DateRangeFilter.values.map((filter) {
          IconData icon;
          switch (filter) {
            case DateRangeFilter.all:
              icon = Icons.all_inclusive;
              break;
            case DateRangeFilter.today:
              icon = Icons.today;
              break;
            case DateRangeFilter.week:
              icon = Icons.view_week;
              break;
            case DateRangeFilter.month:
              icon = Icons.calendar_month;
              break;
          }

          return DropdownMenuItem<DateRangeFilter>(
            value: filter,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.grey.shade600),
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
          return DateRangeFilter.values.map((filter) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.date_range, size: 16),
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
