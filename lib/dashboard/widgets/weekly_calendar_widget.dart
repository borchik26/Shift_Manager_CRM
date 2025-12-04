import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';
import 'package:my_app/core/utils/locator.dart';

/// Mini calendar widget showing current week with shift counts
class WeeklyCalendarWidget extends StatelessWidget {
  final List<int> shiftsCount; // Monday-Sunday

  const WeeklyCalendarWidget({
    super.key,
    required this.shiftsCount,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = _getMonday(now);
    final weekDays = List.generate(7, (index) => monday.add(Duration(days: index)));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Календарь недели',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: weekDays.asMap().entries.map((entry) {
                final index = entry.key;
                final date = entry.value;
                final isToday = _isSameDay(date, now);
                final count = shiftsCount[index];

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToSchedule(context, date),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < 6 ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isToday
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('EEE', 'ru').format(date),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isToday
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? Theme.of(context).primaryColor
                                      : Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$count',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          Text(
                            'смен',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _getMonday(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _navigateToSchedule(BuildContext context, DateTime date) {
    locator<RouterService>().replace(Path(name: '/dashboard/schedule'));
  }
}

