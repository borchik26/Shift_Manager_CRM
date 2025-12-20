import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/position_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/employees_syncfusion/models/profile_model.dart';
import 'package:my_app/employees_syncfusion/viewmodels/profile_view_model.dart';
import 'package:my_app/employees_syncfusion/widgets/edit_profile_dialog.dart';
import 'package:my_app/employees_syncfusion/widgets/profile_header_card.dart';
import 'package:my_app/employees_syncfusion/widgets/profile_salary_card.dart';
import 'package:my_app/employees_syncfusion/widgets/profile_stats_card.dart';
import 'package:my_app/employees_syncfusion/widgets/profile_history_card.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

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
                        child: ProfileHeaderCard(
                          profile: profile,
                          onEdit: () => _showEditProfileDialog(profile),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            ProfileSalaryCard(profile: profile),
                            const SizedBox(height: 24),
                            _buildTimeCard(profile),
                            const SizedBox(height: 24),
                            ProfileStatsCard(profile: profile),
                            const SizedBox(height: 24),
                            ProfileHistoryCard(profile: profile),
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
                    ProfileHeaderCard(
                      profile: profile,
                      onEdit: () => _showEditProfileDialog(profile),
                    ),
                    const SizedBox(height: 16),
                    ProfileSalaryCard(profile: profile),
                    const SizedBox(height: 16),
                    _buildTimeCard(profile),
                    const SizedBox(height: 16),
                    ProfileStatsCard(profile: profile),
                    const SizedBox(height: 16),
                    ProfileHistoryCard(profile: profile),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimeCard(EmployeeProfile profile) {
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
                ? Colors.grey.shade800
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
}
