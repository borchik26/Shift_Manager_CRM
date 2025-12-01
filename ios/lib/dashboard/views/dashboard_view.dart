import 'package:flutter/material.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/dashboard/viewmodels/dashboard_view_model.dart';

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
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _viewModel.getSelectedIndex(widget.currentPath);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final destinations = [
      _NavigationItem(
        label: 'Главная',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        path: '/dashboard',
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

    final drawer = !isDesktop
        ? Drawer(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text('Shift Manager'),
                    subtitle: Text('Управление сменами'),
                  ),
                  const Divider(),
                  ...destinations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = selectedIndex == index;
                    return ListTile(
                      leading: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                      ),
                      title: Text(item.label),
                      selected: isSelected,
                      onTap: () {
                        Navigator.of(context).pop();
                        _viewModel.navigateTo(item.path);
                      },
                    );
                  }),
                  const Spacer(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Выйти'),
                    onTap: _viewModel.logout,
                  ),
                ],
              ),
            ),
          )
        : null;

    return Scaffold(
      drawer: drawer,
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                final destination = destinations[index];
                _viewModel.navigateTo(destination.path);
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
                      onPressed: _viewModel.logout,
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
            child: Column(
              children: [
                if (!isDesktop)
                  AppBar(
                    title: const Text('Shift Manager'),
                    leading: Builder(
                      builder: (context) {
                        return IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        );
                      },
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: _viewModel.logout,
                      ),
                    ],
                  ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                final destination = destinations[index];
                _viewModel.navigateTo(destination.path);
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
