import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/models/user.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/data/services/api_service.dart';

class MockApiService implements ApiService {
  List<Shift> _shifts = [];
  List<String> _branches = ['Центр', 'ТЦ Мега', 'Аэропорт'];

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
    return [];
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return null;
  }

  @override
  Future<Employee> createEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return employee;
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return employee;
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
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
    return ['Уборщица', 'Кассир', 'Повар', 'Менеджер'];
  }
}

void main() {
  group('ShiftRepository', () {
    late ShiftRepository repository;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      repository = ShiftRepository(apiService: mockApiService);
    });

    test('getShifts returns list of shifts', () async {
      // Arrange
      final shifts = [
        Shift(
          id: '1',
          employeeId: '1',
          location: 'Центр',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 8)),
          status: 'completed',
          hourlyRate: 840.0,
        ),
        Shift(
          id: '2',
          employeeId: '2',
          location: 'ТЦ Мега',
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().add(const Duration(hours: 4)),
          status: 'completed',
          hourlyRate: 600.0,
        ),
      ];
      mockApiService.setShifts(shifts);

      // Act
      final result = await repository.getShifts();

      // Assert
      expect(result.length, 2);
      expect(result.first.id, '1');
      expect(result.first.location, 'Центр');
      expect(result.last.hourlyRate, 600.0);
    });

    test('getShifts with date range filters correctly', () async {
      // Arrange
      final shift1 = Shift(
        id: '1',
        employeeId: '1',
        location: 'Центр',
        startTime: DateTime(2023, 1, 1),
        endTime: DateTime(2023, 1, 1, 9),
        status: 'completed',
        hourlyRate: 840.0,
      );
      final shift2 = Shift(
        id: '2',
        employeeId: '2',
        location: 'ТЦ Мега',
        startTime: DateTime(2023, 2, 1),
        endTime: DateTime(2023, 2, 1, 9),
        status: 'completed',
        hourlyRate: 600.0,
      );
      final shift3 = Shift(
        id: '3',
        employeeId: '3',
        location: 'Аэропорт',
        startTime: DateTime(2023, 1, 15),
        endTime: DateTime(2023, 1, 15, 23),
        status: 'completed',
        hourlyRate: 750.0,
      );
      final allShifts = [shift1, shift2, shift3];
      mockApiService.setShifts(allShifts);

      // Act
      final result = await repository.getShifts(
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 1, 31),
      );

      // Assert
      expect(result.length, 3);
      expect(result, contains(shift1));
      expect(result, contains(shift2));
      expect(result, isNot(contains(shift3)));    });

    test('getShiftsByEmployee returns shifts for employee', () async {
      // Arrange
      final shift1 = Shift(
        id: '1',
        employeeId: '1',
        location: 'Центр',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 8)),
        status: 'completed',
        hourlyRate: 840.0,
      );
      final shift2 = Shift(
        id: '2',
        employeeId: '2',
        location: 'ТЦ Мега',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 8)),
        status: 'completed',
        hourlyRate: 600.0,
      );
      final shift3 = Shift(
        id: '3',
        employeeId: '3',
        location: 'Аэропорт',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 8)),
        status: 'completed',
        hourlyRate: 750.0,
      );
      final allShifts = [shift1, shift2, shift3];
      mockApiService.setShifts(allShifts);

      // Act
      final result = await repository.getShiftsByEmployee('2');

      // Assert
      expect(result.length, 1);
      expect(result.first.id, '2');
      expect(result.first.location, 'ТЦ Мега');
      expect(result.first.hourlyRate, 600.0);
    });

    test('getShiftById returns shift when found', () async {
      // Arrange
      final shift = Shift(
        id: '1',
        employeeId: '1',
        location: 'Центр',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 8)),
        status: 'completed',
        hourlyRate: 840.0,
      );
      mockApiService.setShifts([shift]);

      // Act
      final result = await repository.getShiftById('1');

      // Assert
      expect(result, isNotNull);
      expect(result?.id, '1');
      expect(result?.location, 'Центр');
      expect(result?.hourlyRate, 840.0);
    });

    test('getShiftById returns null when not found', () async {
      // Arrange
      mockApiService.setShifts([]);

      // Act
      final result = await repository.getShiftById('999');

      // Assert
      expect(result, isNull);
    });

    test('createShift adds new shift', () async {
      // Arrange
      final newShift = Shift(
        id: '4',
        employeeId: '1',
        location: 'Центр',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 8)),
        status: 'scheduled',
        hourlyRate: 840.0,
      );
      mockApiService.setShifts([]);

      // Act
      final result = await repository.createShift(newShift);

      // Assert
      expect(result.id, '4');
      expect(result.location, 'Центр');
      expect(result.status, 'scheduled');
      
      // Verify shift was added to the list
      final shifts = await repository.getShifts();
      expect(shifts.length, 1);
      expect(shifts.first.id, '4');
    });

    test('updateShift modifies existing shift', () async {
      // Arrange
      final existingShift = Shift(
        id: '1',
        employeeId: '1',
        location: 'Центр',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 8)),
        status: 'scheduled',
        hourlyRate: 840.0,
      );
      mockApiService.setShifts([existingShift]);

      final updatedShift = Shift(
        id: '1',
        employeeId: '1',
        location: 'ТЦ Мега',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 8)),
        status: 'completed',
        hourlyRate: 850.0,
      );

      // Act
      final result = await repository.updateShift(updatedShift);

      // Assert
      expect(result.id, '1');
      expect(result.location, 'ТЦ Мега');
      expect(result.status, 'completed');
      expect(result.hourlyRate, 850.0);
      
      // Verify shift was updated in the list
      final shifts = await repository.getShifts();
      expect(shifts.length, 1);
      expect(shifts.first.location, 'ТЦ Мега');
    });

    test('deleteShift removes shift', () async {
      // Arrange
      final shift1 = Shift(
        id: '1',
        employeeId: '1',
        location: 'Центр',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 8)),
        status: 'completed',
        hourlyRate: 840.0,
      );
      final shift2 = Shift(
        id: '2',
        employeeId: '2',
        location: 'ТЦ Мега',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 8)),
        status: 'completed',
        hourlyRate: 600.0,
      );
      mockApiService.setShifts([shift1, shift2]);

      // Act
      await repository.deleteShift('1');

      // Assert
      final shifts = await repository.getShifts();
      expect(shifts.length, 1);
      expect(shifts.first.id, '2');
      expect(shifts.any((s) => s.id == '1'), isFalse);
    });

    test('repository methods handle errors gracefully', () async {
      // Arrange
      mockApiService.setShifts([]);

      // Act & Assert - getShiftById with non-existent ID
      final result = await repository.getShiftById('999');
      expect(result, isNull);

      // Act & Assert - createShift with error simulation
      // Note: In a real scenario, this would throw an exception
      // but we can test the behavior by checking if the shift is added
      final newShift = Shift(
        id: 'error-test',
        employeeId: '1',
        location: 'Центр',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 8)),
        status: 'scheduled',
        hourlyRate: 840.0,
      );
      
      try {
        await repository.createShift(newShift);
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });
}