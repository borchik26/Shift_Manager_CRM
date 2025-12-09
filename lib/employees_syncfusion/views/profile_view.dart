import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/ui/constants/kit_colors.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/position_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/employees_syncfusion/models/profile_model.dart';
import 'package:my_app/employees_syncfusion/viewmodels/profile_view_model.dart';
import 'package:my_app/employees_syncfusion/widgets/edit_profile_dialog.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:timeline_tile/timeline_tile.dart';

class ProfileView extends StatefulWidget {
  final String employeeId;

  const ProfileView({
    super.key,
    required this.employeeId,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel(
      employeeRepository: locator<EmployeeRepository>(),
      positionRepository: locator<PositionRepository>(),
      shiftRepository: locator<ShiftRepository>(),
    );
    _viewModel.loadProfile(widget.employeeId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ValueListenableBuilder<AsyncValue<EmployeeProfile>>(
        valueListenable: _viewModel.profileState,
        builder: (context, state, child) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.hasError) {
            return Center(child: Text('Ошибка: ${state.errorOrNull}'));
          }

          final profile = state.dataOrNull;
          if (profile == null) {
            return const Center(child: Text('Профиль не найден'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;

              if (isDesktop) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildHeaderCard(profile),
                            const SizedBox(height: 24),
                            _buildInfoCard(profile),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildSalaryCard(profile),
                            const SizedBox(height: 24),
                            _buildTimeCard(profile),
                            const SizedBox(height: 24),
                            _buildStatsCard(profile),
                            const SizedBox(height: 24),
                            _buildHistoryCard(profile),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeaderCard(profile),
                    const SizedBox(height: 16),
                    _buildInfoCard(profile),
                    const SizedBox(height: 16),
                    _buildSalaryCard(profile),
                    const SizedBox(height: 16),
                    _buildTimeCard(profile),
                    const SizedBox(height: 16),
                    _buildStatsCard(profile),
                    const SizedBox(height: 16),
                    _buildHistoryCard(profile),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }

  Widget _buildHeaderCard(EmployeeProfile profile) {
    final theme = Theme.of(context);
    return _buildCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primary,
            child: ClipOval(
              child: Image.network(
                profile.avatarUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    size: 50,
                    color: theme.colorScheme.onPrimary,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.role,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              profile.branch,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showEditProfileDialog(profile),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Редактировать'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(EmployeeProfile profile) {
    final theme = Theme.of(context);
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Контактная информация',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.email_outlined, profile.email),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.phone_outlined, profile.phone),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on_outlined, profile.address),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Принят: ${profile.hireDate.toString().split(' ')[0]}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCard(EmployeeProfile profile) {
    final theme = Theme.of(context);
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Учет времени',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Отработано в этом месяце',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${profile.workedHours.toInt()} / ${profile.totalHours.toInt()} ч',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 12.0,
            percent: profile.hoursPercent,
            backgroundColor: theme.brightness == Brightness.dark
                ? KitColors.neutral800
                : Colors.grey.shade200,
            progressColor: theme.colorScheme.primary,
            barRadius: const Radius.circular(6),
            animation: true,
            center: Text(
              '${(profile.actualHoursPercent * 100).toInt()}%',
              style: const TextStyle(fontSize: 9, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryCard(EmployeeProfile profile) {
    final theme = Theme.of(context);
    final salaryFormatted = profile.calculatedSalary
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    final rateFormatted = profile.hourlyRate
        .toStringAsFixed(0)
        .replaceAll('.', ',');

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Расчет зарплаты',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$rateFormatted ₽/ч',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Начислено за месяц',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$salaryFormatted ₽',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${profile.workedHours.toInt()} часов',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.totalShifts} смен',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(EmployeeProfile profile) {
    final theme = Theme.of(context);

    return _buildCard(
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
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(EmployeeProfile profile) {
    final theme = Theme.of(context);
    return _buildCard(
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
              : _buildGroupedShifts(profile.weekGroups),
        ],
      ),
    );
  }

  Widget _buildGroupedShifts(List<WeekGroup> weekGroups) {
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
                Text(
                  '📅',
                  style: const TextStyle(fontSize: 16),
                ),
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
                  endChild: _buildShiftTile(shift),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildShiftTile(ShiftEvent shift) {
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

  void _showEditProfileDialog(EmployeeProfile profile) {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        employeeId: widget.employeeId,
        profile: profile,
        viewModel: _viewModel,
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
