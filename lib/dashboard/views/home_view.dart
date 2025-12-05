import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:my_app/dashboard/widgets/stat_card.dart';
import 'package:my_app/dashboard/widgets/weekly_calendar_widget.dart';
import 'package:my_app/dashboard/widgets/alerts_list_widget.dart';
import 'package:my_app/dashboard/widgets/safe_loading_hours_chart.dart';
import 'package:my_app/dashboard/models/dashboard_stats.dart';
import 'package:my_app/dashboard/models/dashboard_alert.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(
      authService: locator<AuthService>(),
      routerService: locator(),
      employeeRepository: locator<EmployeeRepository>(),
      shiftRepository: locator<ShiftRepository>(),
    );
    _viewModel.loadDashboard();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 24),

            // Statistics cards
            _buildStatsRow(context),
            const SizedBox(height: 24),

            // Main content
            isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('d MMMM, EEEE', 'ru');
    final formattedDate = dateFormat.format(now);
    final authService = locator<AuthService>();
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return ValueListenableBuilder(
      valueListenable: authService.currentUserNotifier,
      builder: (context, user, _) {
        final userName = user?.username ?? 'Admin';

        // Mobile: Column layout
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Добрый день, $userName!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Сегодня: $formattedDate',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          );
        }

        // Desktop: Row layout
        return Row(
          children: [
            Text(
              'Добрый день, $userName!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            Text(
              'Сегодня: $formattedDate',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return ValueListenableBuilder<AsyncValue<DashboardStats>>(
      valueListenable: _viewModel.statsState,
      builder: (context, asyncStats, _) {
        return asyncStats.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          data: (stats) {
            final cards = [
              StatCard(
                title: 'Сотрудников',
                value: '${stats.totalEmployees}',
                icon: Icons.people,
                color: Colors.blue,
              ),
              StatCard(
                title: 'Смен сегодня',
                value: '${stats.todayShifts}',
                icon: Icons.calendar_today,
                color: Colors.green,
              ),
              StatCard(
                title: 'Часов за неделю',
                value: stats.weeklyHours.toStringAsFixed(0),
                icon: Icons.access_time,
                color: Colors.orange,
              ),
              StatCard(
                title: 'Конфликтов',
                value: '${stats.conflicts}',
                icon: Icons.warning,
                color: stats.conflicts > 0 ? Colors.red : Colors.grey,
              ),
            ];

            // Mobile: Grid 2x2
            if (isMobile) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 12),
                      Expanded(child: cards[1]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: cards[2]),
                      const SizedBox(width: 12),
                      Expanded(child: cards[3]),
                    ],
                  ),
                ],
              );
            }

            // Desktop: Row 1x4
            return Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
                const SizedBox(width: 16),
                Expanded(child: cards[2]),
                const SizedBox(width: 16),
                Expanded(child: cards[3]),
              ],
            );
          },
          error: (message) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Ошибка загрузки статистики: $message',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left column (30%)
          Expanded(
            flex: 3,
            child: ValueListenableBuilder<AsyncValue<List<DashboardAlert>>>(
              valueListenable: _viewModel.alertsState,
              builder: (context, asyncAlerts, _) {
                return asyncAlerts.when(
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  data: (alerts) => AlertsListWidget(alerts: alerts),
                  error: (message) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Ошибка: $message'),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 24),
          // Right column (70%)
          Expanded(
            flex: 7,
            child: Column(
              children: [
                Expanded(
                  child: ValueListenableBuilder<AsyncValue<List<Shift>>>(
                    valueListenable: _viewModel.weeklyShiftsState,
                    builder: (context, asyncShifts, _) {
                      return asyncShifts.when(
                        loading: () => const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                        data: (_) => WeeklyCalendarWidget(
                          shiftsCount: _viewModel.weeklyShiftsCount,
                        ),
                        error: (message) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Ошибка: $message'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SafeLoadingHoursChart(
                    weeklyShiftsState: _viewModel.weeklyShiftsState,
                    getWeeklyHours: () => _viewModel.weeklyHoursData,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<AsyncValue<List<Shift>>>(
          valueListenable: _viewModel.weeklyShiftsState,
          builder: (context, asyncShifts, _) {
            return asyncShifts.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              data: (_) => WeeklyCalendarWidget(
                shiftsCount: _viewModel.weeklyShiftsCount,
              ),
              error: (message) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Ошибка: $message'),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        SafeLoadingHoursChart(
          weeklyShiftsState: _viewModel.weeklyShiftsState,
          getWeeklyHours: () => _viewModel.weeklyHoursData,
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<AsyncValue<List<DashboardAlert>>>(
          valueListenable: _viewModel.alertsState,
          builder: (context, asyncAlerts, _) {
            return asyncAlerts.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              data: (alerts) => AlertsListWidget(alerts: alerts),
              error: (message) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Ошибка: $message'),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

