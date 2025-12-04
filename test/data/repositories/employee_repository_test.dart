import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/models/user.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/services/api_service.dart';

class MockApiService implements ApiService {
  List<Employee> _employees = [];
  List<Shift> _shifts = [];
  List<String> _branches = ['Центр', 'ТЦ Мега', 'Аэропорт'];
  List<String> _roles = ['Уборщица', 'Кассир', 'Повар', 'Менеджер'];

  void setEmployees(List<Employee> employees) => _employees = employees;
  void setShifts(List<Shift> shifts) => _shifts = shifts;

  @override
  Future<User?> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
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
    await Future.delayed(const Duration(milliseconds: 50));
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
    await Future.delayed(const Duration(milliseconds: 200));
    _employees.add(employee);
    return employee;
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index >= 0) {
      _employees[index] = employee;
    }
    return employee;
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _employees.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<Shift>> getShifts({DateTime? startDate, DateTime? endDate}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _shifts;
  }

  @override
  Future<List<Shift>> getShiftsByEmployee(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 100));
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
    await Future.delayed(const Duration(milliseconds: 200));
    _shifts.add(shift);
    return shift;
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _shifts.indexWhere((s) => s.id == shift.id);
    if (index >= 0) {
      _shifts[index] = shift;
    }
    return shift;
  }

  @override
  Future<void> deleteShift(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _shifts.removeWhere((s) => s.id == id);
  }

  @override
  Future<List<String>> getAvailableBranches() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _branches;
  }

  @override
  Future<List<String>> getAvailableRoles() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _roles;
  }
}

void main() {
  group('EmployeeRepository', () {
    late EmployeeRepository repository;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      repository = EmployeeRepository(apiService: mockApiService);
    });

    test('getEmployees returns list of employees', () async {
      // Arrange
      final employees = [
        Employee(
          id: '1',
          firstName: 'Иван',
          lastName: 'Иванов',
          position: 'Менеджер',
          branch: 'Центр',
          status: 'active',
          hireDate: DateTime.now(),
        ),
        Employee(
          id: '2',
          firstName: 'Петр',
          lastName: 'Петров',
          position: 'Кассир',
          branch: 'ТЦ Мега',
          status: 'active',
          hireDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ];
      mockApiService.setEmployees(employees);

      // Act
      final result = await repository.getEmployees();

      // Assert
      expect(result.length, 2);
      expect(result.first.id, '1');
      expect(result.first.firstName, 'Иван');
      expect(result.last.position, 'Кассир');
    });

    test('getEmployeeById returns employee when found', () async {
      // Arrange
      final employee = Employee(
        id: '1',
        firstName: 'Анна',
        lastName: 'Смирнова',
        position: 'Уборщица',
        branch: 'Центр',
        status: 'active',
        hireDate: DateTime.now(),
      );
      mockApiService.setEmployees([employee]);

      // Act
      final result = await repository.getEmployeeById('1');

      // Assert
      expect(result, isNotNull);
      expect(result?.id, '1');
      expect(result?.firstName, 'Анна');
      expect(result?.position, 'Уборщица');
    });

    test('getEmployeeById returns null when not found', () async {
      // Arrange
      mockApiService.setEmployees([]);

      // Act
      final result = await repository.getEmployeeById('999');

      // Assert
      expect(result, isNull);
    });

    test('createEmployee adds new employee', () async {
      // Arrange
      final newEmployee = Employee(
        id: '3',
        firstName: 'Мария',
        lastName: 'Козлова',
        position: 'Повар',
        branch: 'Аэропорт',
        status: 'active',
        hireDate: DateTime.now(),
      );
      mockApiService.setEmployees([]);

      // Act
      final result = await repository.createEmployee(newEmployee);

      // Assert
      expect(result.id, '3');
      expect(result.firstName, 'Мария');
      expect(result.position, 'Повар');
      
      // Verify employee was added to the list
      final employees = await repository.getEmployees();
      expect(employees.length, 1);
      expect(employees.first.id, '3');
    });

    test('updateEmployee modifies existing employee', () async {
      // Arrange
      final existingEmployee = Employee(
        id: '1',
        firstName: 'Иван',
        lastName: 'Иванов',
        position: 'Менеджер',
        branch: 'Центр',
        status: 'active',
        hireDate: DateTime.now(),
      );
      mockApiService.setEmployees([existingEmployee]);

      final updatedEmployee = Employee(
        id: '1',
        firstName: 'Иван',
        lastName: 'Петров',
        position: 'Старший менеджер',
        branch: 'Центр',
        status: 'active',
        hireDate: DateTime.now(),
      );

      // Act
      final result = await repository.updateEmployee(updatedEmployee);

      // Assert
      expect(result.id, '1');
      expect(result.lastName, 'Петров');
      expect(result.position, 'Старший менеджер');
      
      // Verify employee was updated in the list
      final employees = await repository.getEmployees();
      expect(employees.length, 1);
      expect(employees.first.lastName, 'Петров');
    });

    test('deleteEmployee removes employee', () async {
      // Arrange
      final employee1 = Employee(
        id: '1',
        firstName: 'Иван',
        lastName: 'Иванов',
        position: 'Менеджер',
        branch: 'Центр',
        status: 'active',
        hireDate: DateTime.now(),
      );
      final employee2 = Employee(
        id: '2',
        firstName: 'Петр',
        lastName: 'Петров',
        position: 'Кассир',
        branch: 'ТЦ Мега',
        status: 'active',
        hireDate: DateTime.now(),
      );
      mockApiService.setEmployees([employee1, employee2]);

      // Act
      await repository.deleteEmployee('1');

      // Assert
      final employees = await repository.getEmployees();
      expect(employees.length, 1);
      expect(employees.first.id, '2');
      expect(employees.any((e) => e.id == '1'), isFalse);
    });

    test('getAvailableBranches returns list of branches', () async {
      // Act
      final result = await repository.getAvailableBranches();

      // Assert
      expect(result.length, 3);
      expect(result, contains('Центр'));
      expect(result, contains('ТЦ Мега'));
      expect(result, contains('Аэропорт'));
    });

    test('getAvailableRoles returns list of roles', () async {
      // Act
      final result = await repository.getAvailableRoles();

      // Assert
      expect(result.length, 4);
      expect(result, contains('Уборщица'));
      expect(result, contains('Кассир'));
      expect(result, contains('Повар'));
      expect(result, contains('Менеджер'));
    });

    test('repository methods handle errors gracefully', () async {
      // Arrange
      mockApiService.setEmployees([]);

      // Act & Assert - getEmployeeById with non-existent ID
      final result = await repository.getEmployeeById('999');
      expect(result, isNull);

      // Act & Assert - createEmployee with error simulation
      // Note: In a real scenario, this would throw an exception
      // but we can test the behavior by checking if the employee is added
      final newEmployee = Employee(
        id: 'error-test',
        firstName: 'Ошибка',
        lastName: 'Тест',
        position: 'Тест',
        branch: 'Тест',
        status: 'active',
        hireDate: DateTime.now(),
      );
      
      try {
        await repository.createEmployee(newEmployee);
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });
}