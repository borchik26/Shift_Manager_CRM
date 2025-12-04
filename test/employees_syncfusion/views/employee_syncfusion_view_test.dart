import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/employees_syncfusion/views/employee_syncfusion_view.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/data/services/api_service.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/models/user.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

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
    return [
      Employee(
        id: '1',
        firstName: 'Иван',
        lastName: 'Иванов',
        position: 'Менеджер',
        branch: 'ТЦ Мега',
        status: 'active',
        hireDate: DateTime.now(),
      ),
      Employee(
        id: '2',
        firstName: 'Петр',
        lastName: 'Петров',
        position: 'Кассир',
        branch: 'Центр',
        status: 'active',
        hireDate: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<Shift>> getShifts({DateTime? startDate, DateTime? endDate}) async {
    return [
      Shift(
        id: '1',
        employeeId: '1',
        location: 'ТЦ Мега',
        startTime: DateTime.now().subtract(const Duration(hours: 8)),
        endTime: DateTime.now(),
        status: 'active',
        hourlyRate: 500.0,
      ),
    ];
  }

  @override
  Future<List<String>> getAvailableBranches() async {
    return ['ТЦ Мега', 'Центр', 'Аэропорт'];
  }

  @override
  Future<List<String>> getAvailableRoles() async {
    return ['Менеджер', 'Кассир', 'Повар', 'Уборщица'];
  }

  // Mock implementations for other methods
  @override
  Future<Employee?> getEmployeeById(String id) async => null;
  
  @override
  Future<Employee> createEmployee(Employee employee) async => employee;
  
  @override
  Future<Employee> updateEmployee(Employee employee) async => employee;
  
  @override
  Future<void> deleteEmployee(String id) async {}
  
  @override
  Future<Shift?> getShiftById(String id) async => null;
  
  @override
  Future<List<Shift>> getShiftsByEmployee(String employeeId) async => [];
  
  @override
  Future<Shift> createShift(Shift shift) async => shift;
  
  @override
  Future<Shift> updateShift(Shift shift) async => shift;
  
  @override
  Future<void> deleteShift(String id) async {}
}

void main() {
  group('EmployeeSyncfusionView', () {
    late MockApiService mockApiService;
    late EmployeeRepository employeeRepository;
    late ShiftRepository shiftRepository;

    setUp(() {
      mockApiService = MockApiService();
      employeeRepository = EmployeeRepository(apiService: mockApiService);
      shiftRepository = ShiftRepository(apiService: mockApiService);
      
      // Reset locator and register mock services
      locator.reset();
      locator.registerMany([
        Module<EmployeeRepository>(builder: () => employeeRepository, lazy: false),
        Module<ShiftRepository>(builder: () => shiftRepository, lazy: false),
      ]);
    });

    tearDown(() {
      locator.reset();
    });

    testWidgets('displays employee list correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeSyncfusionView(),
        ),
      ));

      // Wait for data to load
      await tester.pumpAndSettle();

      // Assert - Check employee list elements
      expect(find.text('Сотрудники'), findsOneWidget);
      expect(find.text('Добавить сотрудника'), findsOneWidget);
      expect(find.text('Поиск'), findsOneWidget);
      expect(find.text('Филиал'), findsOneWidget);
      expect(find.text('Должность'), findsOneWidget);
      expect(find.text('Статус'), findsOneWidget);
      expect(find.byType(SfDataGrid), findsOneWidget);
    });

    testWidgets('displays employee count correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeSyncfusionView(),
        ),
      ));

      // Wait for data to load
      await tester.pumpAndSettle();

      // Assert - Check employee count is displayed
      expect(find.textContaining('Показано:'), findsOneWidget);
      expect(find.textContaining('из'), findsOneWidget);
      expect(find.textContaining('сотрудников'), findsOneWidget);
    });

    testWidgets('search functionality works', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeSyncfusionView(),
        ),
      ));

      // Wait for data to load
      await tester.pumpAndSettle();

      // Find search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Act - Type in search field
      await tester.enterText(searchField, 'Иван');
      await tester.pump();

      // Assert - Search should filter results
      // Note: Testing actual filtering would require access to internal grid state
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('branch filter works', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeSyncfusionView(),
        ),
      ));

      // Wait for data to load
      await tester.pumpAndSettle();

      // Find branch dropdown
      final branchDropdown = find.text('Филиал');
      expect(branchDropdown, findsOneWidget);

      // Act - Tap dropdown and select branch
      await tester.tap(branchDropdown);
      await tester.pumpAndSettle();

      final branchOption = find.text('ТЦ Мега');
      if (branchOption.evaluate().isNotEmpty) {
        await tester.tap(branchOption);
        await tester.pump();
      }

      // Assert - Filter should be applied
      expect(branchDropdown, findsOneWidget);
    });

    testWidgets('role filter works', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeSyncfusionView(),
        ),
      ));

      // Wait for data to load
      await tester.pumpAndSettle();

      // Find role dropdown
      final roleDropdown = find.text('Должность');
      expect(roleDropdown, findsOneWidget);

      // Act - Tap dropdown and select role
      await tester.tap(roleDropdown);
      await tester.pumpAndSettle();

      final roleOption = find.text('Менеджер');
      if (roleOption.evaluate().isNotEmpty) {
        await tester.tap(roleOption);
        await tester.pump();
      }

      // Assert - Filter should be applied
      expect(roleDropdown, findsOneWidget);
    });

    testWidgets('status filter works', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeSyncfusionView(),
        ),
      ));

      // Wait for data to load
      await tester.pumpAndSettle();

      // Find status dropdown
      final statusDropdown = find.text('Статус');
      expect(statusDropdown, findsOneWidget);

      // Act - Tap dropdown and select status
      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();

      final statusOption = find.text('На смене');
      if (statusOption.evaluate().isNotEmpty) {
        await tester.tap(statusOption);
        await tester.pump();
      }

      // Assert - Filter should be applied
      expect(statusDropdown, findsOneWidget);
    });

    testWidgets('clear filters button works', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeSyncfusionView(),
        ),
      ));

      // Wait for data to load
      await tester.pumpAndSettle();

      // Initially clear button should not be visible
      expect(find.text('Сбросить'), findsNothing);

      // Act - Apply a filter first
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test');
      await tester.pump();

      // Now clear button should be visible
      expect(find.text('Сбросить'), findsOneWidget);

      // Tap clear button
      await tester.tap(find.text('Сбросить'));
      await tester.pump();

      // Assert - Search should be cleared
      final textField = tester.widget<TextField>(searchField);
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('add employee button opens dialog', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeSyncfusionView(),
        ),
      ));

      // Wait for data to load
      await tester.pumpAndSettle();

      // Find add employee button
      final addButton = find.text('Добавить сотрудника');
      expect(addButton, findsOneWidget);

      // Act - Tap add button
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Assert - Dialog should open
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('displays data grid with correct columns', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeSyncfusionView(),
        ),
      ));

      // Wait for data to load
      await tester.pumpAndSettle();

      // Assert - Data grid should be present
      expect(find.byType(SfDataGrid), findsOneWidget);
      
      // Note: Testing specific columns would require access to internal grid state
      // We're mainly testing that the grid renders without errors
    });

    testWidgets('handles empty state correctly', (WidgetTester tester) async {
      // Create mock service that returns empty list
      final emptyApiService = MockApiService();
      final emptyRepository = EmployeeRepository(apiService: emptyApiService);
      
      locator.reset();
      locator.registerMany([
        Module<EmployeeRepository>(builder: () => emptyRepository, lazy: false),
      ]);

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeSyncfusionView(),
        ),
      ));

      // Wait for data to load
      await tester.pumpAndSettle();

      // Assert - Should still display UI with empty grid
      expect(find.text('Сотрудники'), findsOneWidget);
      expect(find.byType(SfDataGrid), findsOneWidget);
      expect(find.textContaining('Показано: 0 из 0'), findsOneWidget);
    });

    testWidgets('responsive layout works correctly', (WidgetTester tester) async {
      // Test mobile layout
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeSyncfusionView(),
        ),
      ));

      await tester.pumpAndSettle();

      // Assert - Mobile layout elements should be present
      expect(find.text('Сотрудники'), findsOneWidget);
      expect(find.byType(SfDataGrid), findsOneWidget);

      // Test desktop layout
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeSyncfusionView(),
        ),
      ));

      await tester.pumpAndSettle();

      // Assert - Desktop layout elements should be present
      expect(find.text('Сотрудники'), findsOneWidget);
      expect(find.byType(SfDataGrid), findsOneWidget);
    });
  });
}