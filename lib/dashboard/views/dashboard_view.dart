import 'package:flutter/material.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';

class DashboardView extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const DashboardView({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(
      authService: locator<AuthService>(),
      routerService: locator<RouterService>(),
      employeeRepository: locator<EmployeeRepository>(),
      shiftRepository: locator<ShiftRepository>(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _navigateTo(String path) {
    _viewModel.navigateTo(path);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _viewModel.getSelectedIndex(widget.currentPath);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final destinations = [
      _NavigationItem(
        label: 'Главная',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        path: '/dashboard',
      ),
      _NavigationItem(
        label: 'Филиалы',
        icon: Icons.spoke_outlined,
        selectedIcon: Icons.spoke,
        path: '/dashboard/branches',
      ),
      _NavigationItem(
        label: 'Должности',
        icon: Icons.badge_outlined,
        selectedIcon: Icons.badge,
        path: '/dashboard/positions',
      ),
      _NavigationItem(
        label: 'Сотрудники',
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        path: '/dashboard/employees',
      ),
      _NavigationItem(
        label: 'График',
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        path: '/dashboard/schedule',
      ),
      _NavigationItem(
        label: 'Логи',
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        path: '/dashboard/audit-logs',
      ),
    ];

    // Filter destinations based on role
    final filteredDestinations = _viewModel.isEmployee
        ? [destinations[0], destinations[3], destinations[4]] // Главная, Сотрудники, График
        : destinations; // All items for manager

    return Scaffold(
      appBar: !isDesktop
          ? AppBar(
              title: const Text('CRM'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _viewModel.logout,
                  tooltip: 'Выйти',
                ),
              ],
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                final destination = filteredDestinations[index];
                _navigateTo(destination.path);
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedIconTheme: IconThemeData(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              unselectedIconTheme: IconThemeData(
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500,
              ),
              selectedLabelTextStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500,
              ),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Icon(
                    Icons.person,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _viewModel.logout,
                      tooltip: 'Выйти',
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              destinations: filteredDestinations
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                final destination = filteredDestinations[index];
                _navigateTo(destination.path);
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedItemColor: isDarkMode ? Colors.white : Colors.black,
              unselectedItemColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              type: BottomNavigationBarType.fixed,
              items: filteredDestinations
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      activeIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }
}

class _NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;

  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });
}
