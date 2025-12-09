import 'package:flutter/material.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';

class DashboardView extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const DashboardView({
    super.key,
    required this.child,
    required this.currentPath,
  });

  int _getSelectedIndex(String currentPath) {
    if (currentPath.startsWith('/dashboard/employees')) {
      return 1;
    } else if (currentPath.startsWith('/dashboard/schedule')) {
      return 2;
    } else if (currentPath == '/dashboard') {
      return 0;
    }
    return 0;
  }

  void _navigateTo(String path) {
    final routerService = locator<RouterService>();

    // Smart navigation: if path already exists in stack, go back to it
    // Otherwise, replace current route
    if (routerService.existsInStack(path)) {
      routerService.backUntil(Path(name: path));
    } else {
      routerService.replace(Path(name: path));
    }
  }

  Future<void> _logout() async {
    try {
      await locator<AuthService>().logout();
      locator<RouterService>().replaceAll([Path(name: '/login')]);
    } catch (e) {
      // Error handling is done in AuthService
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(currentPath);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final destinations = [
      _NavigationItem(
        label: 'Главная',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        path: '/dashboard',
      ),
      _NavigationItem(
        label: 'Филиалы',
        icon: Icons.spoke,
        selectedIcon: Icons.settings,
        path: '/dashboard/branches',
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
    ];

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                final destination = destinations[index];
                _navigateTo(destination.path);
              },
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.person),
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _logout,
                      tooltip: 'Выйти',
                    ),
                  ),
                ),
              ),
              destinations: destinations
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),
          Expanded(
            child: isDesktop
                ? child
                : SafeArea(
                    top: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: child,
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                final destination = destinations[index];
                _navigateTo(destination.path);
              },
              items: destinations
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
