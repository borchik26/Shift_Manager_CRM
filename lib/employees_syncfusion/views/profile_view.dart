import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/employees_syncfusion/models/profile_model.dart';
import 'package:my_app/employees_syncfusion/viewmodels/profile_view_model.dart';
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
    // Force dark theme for this view to match screenshot
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111111),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0088CC),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF111111),
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
                          flex: 2, // Give more space to history/time
                          child: Column(
                            children: [
                              _buildTimeCard(profile),
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
                      _buildTimeCard(profile),
                      const SizedBox(height: 16),
                      _buildHistoryCard(profile),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }

  Widget _buildHeaderCard(EmployeeProfile profile) {
    return _buildCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF0088CC),
            backgroundImage: NetworkImage(profile.avatarUrl),
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.role,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              profile.branch,
              style: const TextStyle(
                color: Color(0xFF0088CC),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0088CC),
                side: const BorderSide(color: Color(0xFF444444)),
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
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Контактная информация',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCard(EmployeeProfile profile) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Учет времени',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Отработано в этом месяце',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '${profile.workedHours.toInt()} / ${profile.totalHours.toInt()} ч',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 12.0,
            percent: profile.hoursPercent,
            backgroundColor: const Color(0xFF333333),
            progressColor: const Color(0xFF0088CC),
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

  Widget _buildHistoryCard(EmployeeProfile profile) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'История смен',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          profile.recentShifts.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Нет данных о сменах',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: profile.recentShifts.length,
                  itemBuilder: (context, index) {
                    final shift = profile.recentShifts[index];
                    final isFirst = index == 0;
                    final isLast = index == profile.recentShifts.length - 1;

                    return TimelineTile(
                      alignment: TimelineAlign.start,
                      isFirst: isFirst,
                      isLast: isLast,
                      indicatorStyle: IndicatorStyle(
                        width: 24,
                        color: shift.isWarning
                            ? Colors.orange
                            : _getLocationColor(shift.location),
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
      ),
    );
  }

  Widget _buildShiftTile(ShiftEvent shift) {
    final dateFormat = DateFormat('dd MMMM, EEEE');
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
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${shift.shiftType.icon} ${shift.timeRange} (${shift.durationHours.toInt()}ч) [${shift.shiftType.displayName}] • $locationIcon ${shift.location}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          if (shift.isWarning && shift.warningText != null) ...[
            const SizedBox(height: 4),
            Text(
              '⚠️ ${shift.warningText}',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Get color for each location
  Color _getLocationColor(String location) {
    if (location.contains('ТЦ Мега')) return const Color(0xFFFF6B35); // Orange
    if (location.contains('Центр')) return const Color(0xFF00BCD4); // Cyan
    if (location.contains('Аэропорт')) return const Color(0xFF9C27B0); // Purple
    return const Color(0xFF0088CC); // Blue default
  }

  // Get icon for each location
  String _getLocationIcon(String location) {
    if (location.contains('ТЦ Мега')) return '🏪';
    if (location.contains('Центр')) return '🏢';
    if (location.contains('Аэропорт')) return '✈️';
    return '📍';
  }
}
