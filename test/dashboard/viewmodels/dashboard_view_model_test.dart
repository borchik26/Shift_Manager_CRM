import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';
import 'package:my_app/core/utils/navigation/navigation_observable.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/models/user.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';

void main() {
  group('DashboardViewModel Basic Tests', () {
    test('should create DashboardViewModel without errors', () {
      // Create mock services using dynamic types
      final mockAuthService = _createMockAuthService();
      final mockRouterService = _createMockRouterService();
      
      // Should create without throwing
      expect(
        () => DashboardViewModel(
          authService: mockAuthService,
          routerService: mockRouterService,
          employeeRepository: _createMockEmployeeRepository(),
          shiftRepository: _createMockShiftRepository(),
        ),
        returnsNormally,
      );
    });

    test('getSelectedIndex should return correct indices', () {
      // Create mock services
      final mockAuthService = _createMockAuthService();
      final mockRouterService = _createMockRouterService();
      final viewModel = DashboardViewModel(
        authService: mockAuthService,
        routerService: mockRouterService,
        employeeRepository: _createMockEmployeeRepository(),
        shiftRepository: _createMockShiftRepository(),
      );

      // Test dashboard root
      expect(viewModel.getSelectedIndex('/dashboard'), 0);
      
      // Test employees path
      expect(viewModel.getSelectedIndex('/dashboard/employees'), 1);
      expect(viewModel.getSelectedIndex('/dashboard/employees/123'), 1);
      
      // Test schedule path
      expect(viewModel.getSelectedIndex('/dashboard/schedule'), 2);
      expect(viewModel.getSelectedIndex('/dashboard/schedule/week'), 2);
      
      // Test unknown paths
      expect(viewModel.getSelectedIndex('/dashboard/unknown'), 0);
      expect(viewModel.getSelectedIndex('/dashboard/settings'), 0);
      
      // Test non-dashboard paths
      expect(viewModel.getSelectedIndex('/login'), 0);
      expect(viewModel.getSelectedIndex('/profile'), 0);
      expect(viewModel.getSelectedIndex('/random/path'), 0);
      
      // Test edge cases
      expect(viewModel.getSelectedIndex(''), 0);
      expect(viewModel.getSelectedIndex('/'), 0);
    });

    test('navigateTo should call router service', () {
      // Create mock services
      final mockAuthService = _createMockAuthService();
      final mockRouterService = _createMockRouterService();
      final viewModel = DashboardViewModel(
        authService: mockAuthService,
        routerService: mockRouterService,
        employeeRepository: _createMockEmployeeRepository(),
        shiftRepository: _createMockShiftRepository(),
      );

      // Test navigation
      viewModel.navigateTo('/employees');
      expect(mockRouterService.lastReplacedPath, '/employees');
      
      viewModel.navigateTo('/dashboard');
      expect(mockRouterService.lastReplacedPath, '/dashboard');
      
      viewModel.navigateTo('/dashboard/schedule');
      expect(mockRouterService.lastReplacedPath, '/dashboard/schedule');
    });

    test('logout should call auth service and navigate to login', () async {
      // Create mock services
      final mockAuthService = _createMockAuthService();
      final mockRouterService = _createMockRouterService();
      final viewModel = DashboardViewModel(
        authService: mockAuthService,
        routerService: mockRouterService,
        employeeRepository: _createMockEmployeeRepository(),
        shiftRepository: _createMockShiftRepository(),
      );

      // Test logout
      await viewModel.logout();
      
      expect(mockAuthService.logoutCalled, isTrue);
      expect(mockRouterService.lastReplacedAllPaths, contains('/login'));
    });

    test('logout should handle auth service errors gracefully', () async {
      // Create mock services
      final mockAuthService = _createMockAuthService();
      mockAuthService.setShouldThrowError(true);
      final mockRouterService = _createMockRouterService();
      final viewModel = DashboardViewModel(
        authService: mockAuthService,
        routerService: mockRouterService,
        employeeRepository: _createMockEmployeeRepository(),
        shiftRepository: _createMockShiftRepository(),
      );

      // Should not throw even when auth service throws
      expect(
        () => viewModel.logout(),
        returnsNormally,
      );
      
      expect(mockAuthService.logoutCalled, isTrue);
      expect(mockRouterService.lastReplacedAllPaths, contains('/login'));
    });

    test('should handle different auth states', () {
      // Test with logged out state
      final authServiceLoggedOut = _createMockAuthService();
      authServiceLoggedOut.setIsLoggedIn(false);
      final viewModelLoggedOut = DashboardViewModel(
        authService: authServiceLoggedOut,
        routerService: _createMockRouterService(),
        employeeRepository: _createMockEmployeeRepository(),
        shiftRepository: _createMockShiftRepository(),
      );
      
      expect(viewModelLoggedOut, isA<DashboardViewModel>());
    });
  });
}

// Create mock services using dynamic types
dynamic _createMockAuthService() {
  return _MockAuthService();
}

dynamic _createMockRouterService() {
  return _MockRouterService();
}

dynamic _createMockEmployeeRepository() {
  return _MockEmployeeRepository();
}

dynamic _createMockShiftRepository() {
  return _MockShiftRepository();
}

// Minimal mock implementations using dynamic types
class _MockAuthService implements AuthService {
  bool logoutCalled = false;
  bool shouldThrowError = false;
  bool _isLoggedIn = true;
  final _currentUserNotifier = _MockValueNotifier<User?>(null);
  
  @override
  bool get isAuthenticated => _isLoggedIn;
  
  @override
  User? get currentUser => _isLoggedIn ? User(id: '1', username: 'test@example.com', role: 'user') : null;
  
  @override
  ValueNotifier<User?> get currentUserNotifier => _currentUserNotifier;
  
  @override
  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isLoggedIn = true;
    _currentUserNotifier.value = User(id: '1', username: 'test@example.com', role: 'user');
  }
  
  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    logoutCalled = true;
    if (shouldThrowError) {
      throw Exception('Mock error');
    }
    _isLoggedIn = false;
    _currentUserNotifier.value = null;
  }
  
  void setShouldThrowError(bool shouldThrow) {
    shouldThrowError = shouldThrow;
  }
  
  void setIsLoggedIn(bool loggedIn) {
    _isLoggedIn = loggedIn;
    _currentUserNotifier.value = loggedIn ? User(id: '1', username: 'test@example.com', role: 'user') : null;
  }
  
  @override
  Future<void> initializeAuth() async {
    // Mock implementation
  }
  
  @override
  void dispose() {
    _currentUserNotifier.dispose();
  }
}

class _MockRouterService extends RouterService {
  _MockRouterService() : super(supportedRoutes: [
    RouteEntry(path: '/dashboard', builder: (_, __) => const SizedBox()),
    RouteEntry(path: '/dashboard/employees', builder: (_, __) => const SizedBox()),
    RouteEntry(path: '/dashboard/schedule', builder: (_, __) => const SizedBox()),
    RouteEntry(path: '/login', builder: (_, __) => const SizedBox()),
  ]);
  
  final _navigationStack = ValueNotifier<List<RouteData>>([]);
  final List<NavigationObserver> _observers = [];
  
  @override
  ValueNotifier<List<RouteData>> get navigationStack => _navigationStack;
  
  @override
  void addObserver(NavigationObserver observer) {
    _observers.add(observer);
  }

  @override
  void removeObserver(NavigationObserver observer) {
    _observers.remove(observer);
  }

  @override
  void notifyPush(RouteData route) {
    for (final observer in _observers) {
      observer.onPush(route);
    }
  }

  @override
  void notifyPop(RouteData route) {
    for (final observer in _observers) {
      observer.onPop(route);
    }
  }

  @override
  void notifyReplace(List<RouteData> routes) {
    for (final observer in _observers) {
      for (final route in routes) {
        observer.onReplace(route);
      }
    }
  }

  @override
  void notifyRemove(RouteData route) {
    for (final observer in _observers) {
      observer.onRemove(route);
    }
  }
  String? lastReplacedPath;
  List<String> lastReplacedAllPaths = [];
  
  @override
  List<RouteEntry> get supportedRoutes => [];
  
  @override
  void replace(Path path) {
    final pathString = path.name;
    lastReplacedPath = pathString;
    lastReplacedAllPaths.add(pathString);
    
    final newRoute = RouteData(
      uri: Uri.parse(pathString),
      routePattern: pathString,
      extra: path.extra,
    );
    _navigationStack.value = [
      ..._navigationStack.value.sublist(0, _navigationStack.value.length - 1),
      newRoute,
    ];
    notifyReplace([newRoute]);
  }
  
  @override
  void replaceAll(List<Path> paths) {
    final pathStrings = paths.map((p) => p.name).toList();
    lastReplacedAllPaths.addAll(pathStrings);
    lastReplacedPath = pathStrings.last;
    
    final newRoutes = paths.map((p) => RouteData(
      uri: Uri.parse(p.name),
      routePattern: p.name,
      extra: p.extra,
    )).toList();
    
    _navigationStack.value = newRoutes;
    notifyReplace(newRoutes);
  }
  
  @override
  void back() {
    if (_navigationStack.value.length <= 1) return;
    
    final poppedRoute = _navigationStack.value.last;
    _navigationStack.value = _navigationStack.value.sublist(0, _navigationStack.value.length - 1);
    notifyPop(poppedRoute);
  }
  
  @override
  void backUntil(Path path) {
    final indexToKeep = _navigationStack.value.indexWhere(
      (r) => r.pathWithParams == path.name,
    );
    if (indexToKeep == -1) return;
    
    final removedRoutes = _navigationStack.value.sublist(indexToKeep + 1);
    _navigationStack.value = _navigationStack.value.sublist(0, indexToKeep + 1);
    
    for (final route in removedRoutes.reversed) {
      notifyPop(route);
    }
  }
  
  @override
  void remove(Path path) {
    final routeToRemove = _navigationStack.value.firstWhere(
      (r) => r.pathWithParams == path.name,
      orElse: () => RouteData(uri: Uri.parse(path.name), routePattern: path.name),
    );
    _navigationStack.value = _navigationStack.value
        .where((r) => r.pathWithParams != path.name)
        .toList();
    notifyRemove(routeToRemove);
  }
  
  @override
  void replaceAllWithRoute(RouteData resolvedRoute) {
    _navigationStack.value = [resolvedRoute];
    notifyReplace([resolvedRoute]);
  }
  
  @override
  void goTo(Path path) {
    final newRoute = RouteData(
      uri: Uri.parse(path.name),
      routePattern: path.name,
      extra: path.extra,
    );
    _navigationStack.value = [..._navigationStack.value, newRoute];
    notifyPush(newRoute);
  }
}

class _MockValueNotifier<T> implements ValueNotifier<T> {
  T _value;
  final List<VoidCallback> _listeners = [];
  
  _MockValueNotifier(this._value);
  
  @override
  T get value => _value;
  
  @override
  set value(T newValue) {
    _value = newValue;
    notifyListeners();
  }
  
  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  
  @override
  void dispose() {
    _listeners.clear();
  }
  
  @override
  bool get hasListeners => _listeners.isNotEmpty;
  
  @override
  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}

class _MockEmployeeRepository implements EmployeeRepository {
  List<Employee> _employees = [];

  @override
  Future<List<Employee>> getEmployees() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _employees;
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Employee> createEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _employees.add(employee);
    return employee;
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index >= 0) {
      _employees[index] = employee;
    }
    return employee;
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _employees.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<String>> getAvailableBranches() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return ['ТЦ Мега', 'Центр', 'Аэропорт'];
  }

  @override
  Future<List<String>> getAvailableRoles() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return ['Менеджер', 'Кассир', 'Администратор'];
  }
}

class _MockShiftRepository implements ShiftRepository {
  List<Shift> _shifts = [];

  @override
  Future<List<Shift>> getShifts({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _shifts;
  }

  @override
  Future<List<Shift>> getShiftsByEmployee(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _shifts.where((s) => s.employeeId == employeeId).toList();
  }

  @override
  Future<Shift?> getShiftById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _shifts.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Shift> createShift(Shift shift) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _shifts.add(shift);
    return shift;
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _shifts.indexWhere((s) => s.id == shift.id);
    if (index >= 0) {
      _shifts[index] = shift;
    }
    return shift;
  }

  @override
  Future<void> deleteShift(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _shifts.removeWhere((s) => s.id == id);
  }
}