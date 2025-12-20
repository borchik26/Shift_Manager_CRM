import 'package:flutter/material.dart';
import 'package:my_app/core/ui/constants/kit_colors.dart';
import 'package:my_app/employees_syncfusion/models/profile_model.dart';

class ProfileStatsCard extends StatelessWidget {
  final EmployeeProfile profile;

  const ProfileStatsCard({
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
            'Статистика',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatRow(
            '🎯 Средняя смена',
            '${profile.averageShiftHours.toStringAsFixed(1)} ч',
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            '📈 Загрузка',
            '${profile.loadPercentage.toInt()}% (${profile.loadStatus})',
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            '🌙 Ночных смен',
            '${profile.nightShiftsCount} из ${profile.totalShifts}',
          ),
          if (profile.actualHoursPercent > 1.0) ...[
            const SizedBox(height: 12),
            _buildStatRow(
              '💪 Переработка',
              '+${(profile.workedHours - profile.totalHours).toInt()} ч',
              color: Colors.orange,
            ),
          ],
          const SizedBox(height: 24),
          Text(
            '📊 Статистика по локациям',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...profile.locationStats.map(
            (stat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    _getLocationIcon(stat.location),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stat.location,
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              '${stat.hours.toInt()}ч (${stat.percentage.toInt()}%)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getLocationColor(context, stat.location),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: stat.percentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            _getLocationColor(context, stat.location),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
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
