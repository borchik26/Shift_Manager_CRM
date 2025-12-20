import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/ui/constants/kit_colors.dart';
import 'package:my_app/employees_syncfusion/models/profile_model.dart';
import 'package:timeline_tile/timeline_tile.dart';

class ProfileHistoryCard extends StatelessWidget {
  final EmployeeProfile profile;

  const ProfileHistoryCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'История смен',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          profile.recentShifts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Нет данных о сменах',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              : _buildGroupedShifts(context, profile.weekGroups),
        ],
      ),
    );
  }

  Widget _buildGroupedShifts(BuildContext context, List<WeekGroup> weekGroups) {
    final theme = Theme.of(context);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weekGroups.length,
      itemBuilder: (context, groupIndex) {
        final group = weekGroups[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (groupIndex > 0) const SizedBox(height: 16),
            Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  group.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.shifts.length,
              itemBuilder: (context, index) {
                final shift = group.shifts[index];
                final isFirst = index == 0;
                final isLast = index == group.shifts.length - 1;
                final isLastGroup = groupIndex == weekGroups.length - 1;

                return TimelineTile(
                  alignment: TimelineAlign.start,
                  isFirst: isFirst && groupIndex == 0,
                  isLast: isLast && isLastGroup,
                  indicatorStyle: IndicatorStyle(
                    width: 24,
                    color: shift.isWarning
                        ? Colors.orange
                        : _getLocationColor(context, shift.location),
                    padding: const EdgeInsets.only(right: 12),
                  ),
                  beforeLineStyle: LineStyle(
                    color: Colors.grey.shade700,
                    thickness: 2,
                  ),
                  endChild: _buildShiftTile(context, shift),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildShiftTile(BuildContext context, ShiftEvent shift) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMMM, EEEE', 'ru');
    final formattedDate = dateFormat.format(shift.date);
    final locationIcon = _getLocationIcon(shift.location);

    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.only(bottom: 16, left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedDate,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${shift.shiftType.icon} ${shift.timeRange} (${shift.durationHours.toInt()}ч) [${shift.shiftType.displayName}] • $locationIcon ${shift.location}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (shift.isWarning && shift.warningText != null) ...[
            const SizedBox(height: 4),
            Text(
              '⚠️ ${shift.warningText}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getLocationColor(BuildContext context, String location) {
    if (location.contains('ТЦ Мега')) return KitColors.orange500;
    if (location.contains('Центр')) return KitColors.cyan500;
    if (location.contains('Аэропорт')) return KitColors.purple500;
    return Theme.of(context).colorScheme.primary;
  }

  String _getLocationIcon(String location) {
    if (location.contains('ТЦ Мега')) return '🏪';
    if (location.contains('Центр')) return '🏢';
    if (location.contains('Аэропорт')) return '✈️';
    return '📍';
  }
}
