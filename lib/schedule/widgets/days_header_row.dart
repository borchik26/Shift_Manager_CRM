import 'package:flutter/material.dart';

/// Days header row for mobile schedule grid
/// Shows horizontal scrolling days with sticky profession column
///
/// Layout: [Profession] | [Mon 01] | [Tue 02] | [Wed 03] | ...
///          120px       |   100px  |   100px  |   100px  |
class DaysHeaderRow extends StatelessWidget {
  final List<DateTime> dates;
  final ScrollController? scrollController; // Made optional

  const DaysHeaderRow({
    required this.dates,
    this.scrollController, // Made optional
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          // Empty space for profession column (no label needed)
          Container(
            width: 48,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
          ),

          // Horizontal scrolling dates (removed SingleChildScrollView)
          ...dates.map((date) {
            final isToday = date.year == today.year &&
                            date.month == today.month &&
                            date.day == today.day;

            return Container(
              width: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday ? Colors.blue.shade50 : null,
                border: Border(
                  left: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Weekday (ПН, ВТ, СР...)
                  Text(
                    _getDayName(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday ? Colors.blue : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  // Day number (01, 02, 03...)
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.blue : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Convert weekday number (1-7) to Russian abbreviation
  String _getDayName(int weekday) {
    const days = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    return days[weekday - 1];
  }
}
