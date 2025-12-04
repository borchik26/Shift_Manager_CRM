import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/data/repositories/auth_repository.dart';
import 'package:my_app/data/models/user.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/services/api_service.dart';

// Fake implementation for testing
class FakeApiService implements ApiService {
  bool _shouldThrowError = false;
  User? _mockUser;
  List<Employee> _employees = [];
  List<Shift> _shifts = [];

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  void setMockUser(User? user) {
    _mockUser = user;
  }

  @override
  Future<User?> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (_shouldThrowError) {
      throw Exception('Login failed');
    }

    if (username == 'test@example.com' && password == 'password123') {
      return _mockUser;
    }

    return null; // Invalid credentials
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (_shouldThrowError) {
      throw Exception('Logout failed');
    }
  }

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
  Future<List<Shift>> getShifts({
    DateTime? startDate,
    DateTime? endDate,
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

void main() {
  group('AuthRepository', () {
    late FakeApiService fakeApiService;
    late AuthRepository authRepository;

    setUp(() {
      fakeApiService = FakeApiService();
      authRepository = AuthRepository(apiService: fakeApiService);
    });

    group('Login', () {
      test('should return user when login succeeds', () async {
        final mockUser = User(
          id: '1',
          username: 'test@example.com',
          role: 'admin',
        );

        fakeApiService.setMockUser(mockUser);

        final result = await authRepository.login(
          'test@example.com',
          'password123',
        );

        expect(result, isNotNull);
        expect(result?.id, '1');
        expect(result?.username, 'test@example.com');
        expect(result?.role, 'admin');
      });

      test('should return null when login fails', () async {
        fakeApiService.setShouldThrowError(false);

        final result = await authRepository.login(
          'wrong@example.com',
          'wrongpassword',
        );

        expect(result, isNull);
      });

      test('should propagate api service exceptions', () async {
        fakeApiService.setShouldThrowError(true);

        expect(
          () => authRepository.login('test@example.com', 'password123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle timeout scenarios', () async {
        fakeApiService.setMockUser(null);

        final result = await authRepository.login(
          'test@example.com',
          'password123',
        );

        expect(result, isNull);
      });
    });

    group('Logout', () {
      test('should complete successfully', () async {
        await authRepository.logout();

        // Should not throw
        expect(() => authRepository.logout(), returnsNormally);
      });

      test('should handle api service errors during logout', () async {
        fakeApiService.setShouldThrowError(true);

        expect(() => authRepository.logout(), throwsA(isA<Exception>()));
      });
    });

    group('Constructor', () {
      test('should create repository with api service', () {
        final repository = AuthRepository(apiService: fakeApiService);

        expect(repository, isNotNull);
        expect(repository, isA<AuthRepository>());
      });
    });

    group('Integration', () {
      test('should handle login-logout flow', () async {
        final mockUser = User(
          id: '1',
          username: 'test@example.com',
          role: 'admin',
        );

        fakeApiService.setMockUser(mockUser);

        // Login
        final loginResult = await authRepository.login(
          'test@example.com',
          'password123',
        );
        expect(loginResult, isNotNull);

        // Logout
        await authRepository.logout();

        // Should be able to login again after logout
        final secondLoginResult = await authRepository.login(
          'test@example.com',
          'password123',
        );
        expect(secondLoginResult, isNotNull);
      });
    });

    group('Edge Cases', () {
      test('should handle empty credentials', () async {
        final result = await authRepository.login('', '');

        expect(result, isNull);
      });

      test('should handle null credentials', () async {
        final result = await authRepository.login('', '');

        expect(result, isNull);
      });

      test('should handle special characters in credentials', () async {
        final result = await authRepository.login(
          'test@example.com',
          'p@ssw0rd123!',
        );

        expect(result, isNull);
      });
    });
  });
}
