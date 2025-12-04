import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/dashboard/views/dashboard_view.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/data/models/user.dart';
import 'package:my_app/data/repositories/auth_repository.dart';
import 'package:my_app/data/services/api_service.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';

// Mock classes for testing
class MockApiService implements ApiService {
  @override
  Future<User?> login(String username, String password) async {
    return User(id: '1', username: username, role: 'admin');
  }

  @override
  Future<void> logout() async {
    // Mock implementation
  }

  @override
  Future<List<Employee>> getEmployees() async {
    return [];
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    return null;
  }

  @override
  Future<Employee> createEmployee(Employee employee) async {
    return employee;
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    return employee;
  }

  @override
  Future<void> deleteEmployee(String id) async {
    // Mock implementation
  }

  @override
  Future<List<Shift>> getShifts({DateTime? startDate, DateTime? endDate}) async {
    return [];
  }

  @override
  Future<List<Shift>> getShiftsByEmployee(String employeeId) async {
    return [];
  }

  @override
  Future<Shift?> getShiftById(String id) async {
    return null;
  }

  @override
  Future<Shift> createShift(Shift shift) async {
    return shift;
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    return shift;
  }

  @override
  Future<void> deleteShift(String id) async {
    // Mock implementation
  }

  @override
  Future<List<String>> getAvailableBranches() async {
    return [];
  }

  @override
  Future<List<String>> getAvailableRoles() async {
    return [];
  }
}

class MockRouterService extends RouterService {
  bool _replaceWasCalled = false;
  String? _lastReplacedPath;
  bool _replaceAllWasCalled = false;
  List<String>? _lastReplacedAllPaths;

  bool get replaceWasCalled => _replaceWasCalled;
  String? get lastReplacedPath => _lastReplacedPath;
  bool get replaceAllWasCalled => _replaceAllWasCalled;
  List<String>? get lastReplacedAllPaths => _lastReplacedAllPaths;

  MockRouterService() : super(supportedRoutes: []);

  @override
  void replace(Path path) {
    _replaceWasCalled = true;
    _lastReplacedPath = path.name;
  }

  @override
  void goTo(Path path) {
    // Mock implementation
  }

  @override
  void back() {
    // Mock implementation
  }

  @override
  void replaceAll(List<Path> routeDatas) {
    _replaceAllWasCalled = true;
    _lastReplacedAllPaths = routeDatas.map((p) => p.name).toList();
  }

  @override
  void backUntil(Path path) {
    // Mock implementation
  }

  @override
  void remove(Path path) {
    // Mock implementation
  }

  @override
  void replaceAllWithRoute(RouteData resolvedRoute) {
    // Mock implementation
  }
}

void main() {
  group('DashboardView', () {
    late MockApiService mockApiService;
    late AuthRepository authRepository;
    late AuthService authService;
    late MockRouterService mockRouterService;

    setUp(() {
      mockApiService = MockApiService();
      authRepository = AuthRepository(apiService: mockApiService);
      authService = AuthService(authRepository: authRepository);
      mockRouterService = MockRouterService();
      
      // Reset locator and register mock services
      locator.reset();
      locator.registerMany([
        Module<AuthService>(builder: () => authService, lazy: false),
        Module<RouterService>(builder: () => mockRouterService, lazy: false),
      ]);
    });

    tearDown(() {
      locator.reset();
    });

    testWidgets('displays dashboard correctly on desktop', (WidgetTester tester) async {
      // Set desktop screen size
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      
      // Act
      await tester.pumpWidget(MaterialApp(
        home: DashboardView(
          child: const Scaffold(body: Text('Dashboard Content')),
          currentPath: '/dashboard',
        ),
      ));

      // Assert - Check dashboard elements for desktop
      expect(find.text('Shift Manager'), findsOneWidget);
      expect(find.text('Управление сменами'), findsOneWidget);
      expect(find.text('Главная'), findsOneWidget);
      expect(find.text('Сотрудники'), findsOneWidget);
      expect(find.text('График'), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(Drawer), findsNothing);
      expect(find.text('Dashboard Content'), findsOneWidget);
    });

    testWidgets('displays dashboard correctly on mobile', (WidgetTester tester) async {
      // Set mobile screen size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      
      // Act
      await tester.pumpWidget(MaterialApp(
        home: DashboardView(
          child: const Scaffold(body: Text('Dashboard Content')),
          currentPath: '/dashboard',
        ),
      ));

      // Assert - Check dashboard elements for mobile
      expect(find.text('Shift Manager'), findsOneWidget);
      expect(find.text('Главная'), findsOneWidget);
      expect(find.text('Сотрудники'), findsOneWidget);
      expect(find.text('График'), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.text('Dashboard Content'), findsOneWidget);
    });

    testWidgets('navigates to employees when employees is selected', (WidgetTester tester) async {
      // Set desktop screen size
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      
      // Act
      await tester.pumpWidget(MaterialApp(
        home: DashboardView(
          child: const Scaffold(body: Text('Dashboard Content')),
          currentPath: '/dashboard',
        ),
      ));

      // Find employees navigation item
      final employeesDestination = find.text('Сотрудники');
      expect(employeesDestination, findsOneWidget);

      // Act - Tap employees destination
      await tester.tap(employeesDestination);
      await tester.pump();

      // Assert - Navigation should have happened
      expect(mockRouterService.replaceWasCalled, isTrue);
      expect(mockRouterService.lastReplacedPath, '/dashboard/employees');
    });

    testWidgets('navigates to schedule when schedule is selected', (WidgetTester tester) async {
      // Set desktop screen size
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      
      // Act
      await tester.pumpWidget(MaterialApp(
        home: DashboardView(
          child: const Scaffold(body: Text('Dashboard Content')),
          currentPath: '/dashboard',
        ),
      ));

      // Find schedule navigation item
      final scheduleDestination = find.text('График');
      expect(scheduleDestination, findsOneWidget);

      // Act - Tap schedule destination
      await tester.tap(scheduleDestination);
      await tester.pump();

      // Assert - Navigation should have happened
      expect(mockRouterService.replaceWasCalled, isTrue);
      expect(mockRouterService.lastReplacedPath, '/dashboard/schedule');
    });

    testWidgets('logout button works correctly', (WidgetTester tester) async {
      // Set desktop screen size
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      
      // Act
      await tester.pumpWidget(MaterialApp(
        home: DashboardView(
          child: const Scaffold(body: Text('Dashboard Content')),
          currentPath: '/dashboard',
        ),
      ));

      // Find logout button
      final logoutButton = find.byIcon(Icons.logout);
      expect(logoutButton, findsOneWidget);

      // Act - Tap logout button
      await tester.tap(logoutButton);
      await tester.pump();

      // Assert - Logout navigation should have happened
      expect(mockRouterService.replaceAllWasCalled, isTrue);
      expect(mockRouterService.lastReplacedAllPaths, contains('/login'));
    });

    testWidgets('correct navigation item is selected based on current path', (WidgetTester tester) async {
      // Set desktop screen size
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      
      // Act - Test with employees path
      await tester.pumpWidget(MaterialApp(
        home: DashboardView(
          child: const Scaffold(body: Text('Dashboard Content')),
          currentPath: '/dashboard/employees',
        ),
      ));

      // Assert - Employees should be selected (index 1)
      final navigationRail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(navigationRail.selectedIndex, 1);

      // Act - Test with schedule path
      await tester.pumpWidget(MaterialApp(
        home: DashboardView(
          child: const Scaffold(body: Text('Dashboard Content')),
          currentPath: '/dashboard/schedule',
        ),
      ));

      // Assert - Schedule should be selected (index 2)
      final navigationRail2 = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(navigationRail2.selectedIndex, 2);

      // Act - Test with dashboard path
      await tester.pumpWidget(MaterialApp(
        home: DashboardView(
          child: const Scaffold(body: Text('Dashboard Content')),
          currentPath: '/dashboard',
        ),
      ));

      // Assert - Dashboard should be selected (index 0)
      final navigationRail3 = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(navigationRail3.selectedIndex, 0);
    });

    testWidgets('mobile drawer works correctly', (WidgetTester tester) async {
      // Set mobile screen size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      
      // Act
      await tester.pumpWidget(MaterialApp(
        home: DashboardView(
          child: const Scaffold(body: Text('Dashboard Content')),
          currentPath: '/dashboard',
        ),
      ));

      // Open drawer
      final menuButton = find.byIcon(Icons.menu);
      expect(menuButton, findsOneWidget);
      
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Assert - Drawer should be open
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('Главная'), findsOneWidget);
      expect(find.text('Сотрудники'), findsOneWidget);
      expect(find.text('График'), findsOneWidget);
      expect(find.text('Выйти'), findsOneWidget);

      // Test navigation from drawer
      final employeesItem = find.text('Сотрудники');
      await tester.tap(employeesItem);
      await tester.pump();

      // Assert - Navigation should have happened and drawer closed
      expect(mockRouterService.replaceWasCalled, isTrue);
      expect(mockRouterService.lastReplacedPath, '/dashboard/employees');
    });

    testWidgets('mobile bottom navigation works correctly', (WidgetTester tester) async {
      // Set mobile screen size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      
      // Act
      await tester.pumpWidget(MaterialApp(
        home: DashboardView(
          child: const Scaffold(body: Text('Dashboard Content')),
          currentPath: '/dashboard',
        ),
      ));

      // Find bottom navigation bar
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget);

      // Test tapping on employees
      final employeesItem = find.text('Сотрудники');
      await tester.tap(employeesItem);
      await tester.pump();

      // Assert - Navigation should have happened
      expect(mockRouterService.replaceWasCalled, isTrue);
      expect(mockRouterService.lastReplacedPath, '/dashboard/employees');
    });
  });
}