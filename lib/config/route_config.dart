import 'package:flutter/material.dart';
import 'package:my_app/auth/views/login_view.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';
import 'package:my_app/dashboard/views/dashboard_view.dart';
import 'package:my_app/employees_syncfusion/views/profile_view.dart';
import 'package:my_app/employees_syncfusion/views/employee_syncfusion_view.dart';
import 'package:my_app/not_found/not_found_view.dart';
import 'package:my_app/schedule/views/schedule_view.dart';

final routes = [
  // Home -> Redirect to Login
  RouteEntry(
    path: '/',
    builder: (key, routeData) => const LoginView(),
    requiresAuth: false,
  ),
  
  // Auth
  RouteEntry(
    path: '/login',
    builder: (key, routeData) => const LoginView(),
    requiresAuth: false,
  ),
  
  // Dashboard - REQUIRES AUTH
  RouteEntry(
    path: '/dashboard',
    builder: (key, routeData) => DashboardView(
      currentPath: '/dashboard',
      child: const Center(child: Text('Dashboard Home')),
    ),
    requiresAuth: true,
  ),
  
  // Employees - REQUIRES AUTH
  RouteEntry(
    path: '/dashboard/employees',
    builder: (key, routeData) => DashboardView(
      currentPath: '/dashboard/employees',
      child: const EmployeeSyncfusionView(),
    ),
    requiresAuth: true,
  ),
  RouteEntry(
    path: '/dashboard/employees/:id',
    builder: (key, routeData) {
      final id = routeData.pathParameters['id'] ?? '';
      return DashboardView(
        currentPath: '/dashboard/employees',
        child: ProfileView(employeeId: id),
      );
    },
    requiresAuth: true,
  ),
  
  // Schedule - REQUIRES AUTH
  RouteEntry(
    path: '/dashboard/schedule',
    builder: (key, routeData) => DashboardView(
      currentPath: '/dashboard/schedule',
      child: const ScheduleView(),
    ),
    requiresAuth: true,
  ),
  
  // 404
  RouteEntry(
    path: '/404',
    builder: (key, routeData) => const NotFoundView(),
    requiresAuth: false,
  ),
];

// Temporary placeholder widget for routes
class _PlaceholderView extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _PlaceholderView({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!),
            ],
            const SizedBox(height: 24),
            const Text('This screen will be implemented soon'),
          ],
        ),
      ),
    );
  }
}
