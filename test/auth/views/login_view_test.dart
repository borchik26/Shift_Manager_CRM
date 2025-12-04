import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/auth/views/login_view.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/data/models/user.dart';
import 'package:my_app/data/repositories/auth_repository.dart';
import 'package:my_app/data/services/api_service.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';

// Mock classes for testing
class MockApiService implements ApiService {
  @override
  Future<User?> login(String username, String password) async {
    if (username == 'admin@example.com' && password == 'password123') {
      return User(
        id: '1',
        username: username,
        role: 'admin',
      );
    }
    return null;
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

  bool get replaceWasCalled => _replaceWasCalled;
  String? get lastReplacedPath => _lastReplacedPath;

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
    // Mock implementation
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
  group('LoginView', () {
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

    testWidgets('displays login form correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: LoginView(),
      ));

      // Assert - Check form elements
      expect(find.text('Вход в систему'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Пароль'), findsOneWidget);
      expect(find.text('Войти'), findsOneWidget);
      expect(find.text('Тестовые данные:\nEmail: admin@example.com\nПароль: password123'), findsOneWidget);
    });

    testWidgets('validates form fields correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: LoginView(),
      ));

      // Find email and password fields
      final emailField = find.widgetWithText(TextFormField, 'Email');
      final passwordField = find.widgetWithText(TextFormField, 'Пароль');
      final loginButton = find.text('Войти');

      // Test empty email
      await tester.enterText(emailField, '');
      await tester.enterText(passwordField, 'password123');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Введите email'), findsOneWidget);

      // Test invalid email
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Введите корректный email'), findsOneWidget);

      // Test empty password
      await tester.enterText(emailField, 'admin@example.com');
      await tester.enterText(passwordField, '');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Введите пароль'), findsOneWidget);

      // Test short password
      await tester.enterText(passwordField, '123');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Пароль должен быть не менее 6 символов'), findsOneWidget);
    });

    testWidgets('shows loading state during login', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: LoginView(),
      ));

      // Find email and password fields
      final emailField = find.widgetWithText(TextFormField, 'Email');
      final passwordField = find.widgetWithText(TextFormField, 'Пароль');
      final loginButton = find.text('Войти');

      // Enter valid credentials
      await tester.enterText(emailField, 'admin@example.com');
      await tester.enterText(passwordField, 'password123');

      // Tap login button
      await tester.tap(loginButton);
      await tester.pump(); // Start loading

      // Assert - Loading indicator should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Войти'), findsNothing);
    });

    testWidgets('successful login navigates to dashboard', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: LoginView(),
      ));

      // Find email and password fields
      final emailField = find.widgetWithText(TextFormField, 'Email');
      final passwordField = find.widgetWithText(TextFormField, 'Пароль');
      final loginButton = find.text('Войти');

      // Enter valid credentials
      await tester.enterText(emailField, 'admin@example.com');
      await tester.enterText(passwordField, 'password123');

      // Tap login button
      await tester.tap(loginButton);
      await tester.pump(); // Start loading

      // Wait for login to complete
      await tester.pumpAndSettle();

      // Assert - Navigation should have happened
      expect(mockRouterService.replaceWasCalled, isTrue);
      expect(mockRouterService.lastReplacedPath, '/dashboard');
    });

    testWidgets('failed login shows error message', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: LoginView(),
      ));

      // Find email and password fields
      final emailField = find.widgetWithText(TextFormField, 'Email');
      final passwordField = find.widgetWithText(TextFormField, 'Пароль');
      final loginButton = find.text('Войти');

      // Enter invalid credentials
      await tester.enterText(emailField, 'invalid@example.com');
      await tester.enterText(passwordField, 'wrongpassword');

      // Tap login button
      await tester.tap(loginButton);
      await tester.pump(); // Start loading

      // Wait for login to complete
      await tester.pumpAndSettle();

      // Assert - Error message should be shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Ошибка входа: Invalid credentials'), findsOneWidget);
      
      // Assert - No navigation on error
      expect(mockRouterService.replaceWasCalled, isFalse);
    });

    testWidgets('password visibility toggle works', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: LoginView(),
      ));

      // Find password field and visibility toggle
      final passwordField = find.widgetWithText(TextFormField, 'Пароль');
      final visibilityToggle = find.byIcon(Icons.visibility);

      // Assert - Password should be obscured initially
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      
      // Tap visibility toggle
      await tester.tap(visibilityToggle);
      await tester.pump();

      // Assert - Password should be visible now
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('form is pre-filled with test data', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: LoginView(),
      ));

      // Find email and password fields
      final emailField = find.widgetWithText(TextFormField, 'Email');
      final passwordField = find.widgetWithText(TextFormField, 'Пароль');

      // Assert - Fields should be pre-filled with test data
      expect(tester.widget<TextFormField>(emailField).controller?.text, 'admin@example.com');
      expect(tester.widget<TextFormField>(passwordField).controller?.text, 'password123');
    });
  });
}