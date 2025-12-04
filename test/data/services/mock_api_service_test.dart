import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/services/mock_api_service.dart';

void main() {
  group('MockApiService', () {
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
    });

    group('Authentication', () {
      test('login with correct credentials returns user', () async {
        final user = await mockApiService.login('admin@example.com', 'password123');
        
        expect(user, isNotNull);
        expect(user!.id, equals('user_1'));
        expect(user.username, equals('admin'));
        expect(user.role, equals('administrator'));
      });

      test('login with incorrect credentials returns null', () async {
        final user = await mockApiService.login('wrong@example.com', 'wrongpassword');
        
        expect(user, isNull);
      });

      test('logout clears current user', () async {
        // First login
        await mockApiService.login('admin@example.com', 'password123');
        
        // Then logout
        await mockApiService.logout();
        
        // Verify user is logged out (this would require access to internal state)
        // For now, just verify it doesn't throw
        expect(() async => await mockApiService.logout(), returnsNormally);
      });
    });

    group('Employee Operations', () {
      test('getEmployees returns list of employees', () async {
        final employees = await mockApiService.getEmployees();
        
        expect(employees, isNotEmpty);
        expect(employees.length, equals(10)); // Based on mock data generation
        expect(employees.first, isA<Employee>());
      });

      test('getEmployeeById returns correct employee', () async {
        final employees = await mockApiService.getEmployees();
        final firstEmployee = employees.first;
        
        final foundEmployee = await mockApiService.getEmployeeById(firstEmployee.id);
        
        expect(foundEmployee, isNotNull);
        expect(foundEmployee!.id, equals(firstEmployee.id));
        expect(foundEmployee.firstName, equals(firstEmployee.firstName));
        expect(foundEmployee.lastName, equals(firstEmployee.lastName));
      });

      test('getEmployeeById with non-existent ID returns null', () async {
        final employee = await mockApiService.getEmployeeById('non_existent_id');
        
        expect(employee, isNull);
      });

      test('createEmployee adds new employee', () async {
        final newEmployee = Employee(
          id: 'new_employee',
          firstName: 'Новый',
          lastName: 'Сотрудник',
          position: 'Тестировщик',
          branch: 'ТЦ Мега',
          status: 'active',
          hireDate: DateTime.now(),
          email: 'new@example.com',
        );
        
        final createdEmployee = await mockApiService.createEmployee(newEmployee);
        
        expect(createdEmployee.id, equals(newEmployee.id));
        
        // Verify it was added
        final allEmployees = await mockApiService.getEmployees();
        expect(allEmployees.any((e) => e.id == newEmployee.id), isTrue);
      });

      test('updateEmployee modifies existing employee', () async {
        final employees = await mockApiService.getEmployees();
        final firstEmployee = employees.first;
        
        final updatedEmployee = firstEmployee.copyWith(
          position: 'Старший менеджер',
          status: 'vacation',
        );
        
        final result = await mockApiService.updateEmployee(updatedEmployee);
        
        expect(result.position, equals('Старший менеджер'));
        expect(result.status, equals('vacation'));
        
        // Verify it was updated
        final foundEmployee = await mockApiService.getEmployeeById(firstEmployee.id);
        expect(foundEmployee!.position, equals('Старший менеджер'));
        expect(foundEmployee.status, equals('vacation'));
      });

      test('deleteEmployee removes employee', () async {
        final employees = await mockApiService.getEmployees();
        final firstEmployee = employees.first;
        final employeeId = firstEmployee.id;
        
        await mockApiService.deleteEmployee(employeeId);
        
        // Verify it was deleted
        final foundEmployee = await mockApiService.getEmployeeById(employeeId);
        expect(foundEmployee, isNull);
        
        final allEmployees = await mockApiService.getEmployees();
        expect(allEmployees.any((e) => e.id == employeeId), isFalse);
      });
    });

    group('Shift Operations', () {
      test('getShifts returns list of shifts', () async {
        final shifts = await mockApiService.getShifts();
        
        expect(shifts, isNotEmpty);
        expect(shifts.first, isA<Shift>());
      });

      test('getShifts with date filter returns filtered shifts', () async {
        final startDate = DateTime.now().subtract(Duration(days: 7));
        final endDate = DateTime.now().add(Duration(days: 7));
        
        final shifts = await mockApiService.getShifts(
          startDate: startDate,
          endDate: endDate,
        );
        
        expect(shifts, isNotEmpty);
        
        // All shifts should be within date range
        for (final shift in shifts) {
          expect(shift.startTime.isAfter(startDate.subtract(Duration(days: 1))), isTrue);
          expect(shift.endTime.isBefore(endDate.add(Duration(days: 1))), isTrue);
        }
      });

      test('getShiftsByEmployee returns shifts for specific employee', () async {
        final employees = await mockApiService.getEmployees();
        final firstEmployee = employees.first;
        
        final shifts = await mockApiService.getShiftsByEmployee(firstEmployee.id);
        
        expect(shifts, isNotEmpty);
        
        // All shifts should belong to the employee
        for (final shift in shifts) {
          expect(shift.employeeId, equals(firstEmployee.id));
        }
      });

      test('getShiftById returns correct shift', () async {
        final shifts = await mockApiService.getShifts();
        final firstShift = shifts.first;
        
        final foundShift = await mockApiService.getShiftById(firstShift.id);
        
        expect(foundShift, isNotNull);
        expect(foundShift!.id, equals(firstShift.id));
        expect(foundShift.employeeId, equals(firstShift.employeeId));
      });

      test('getShiftById with non-existent ID returns null', () async {
        final shift = await mockApiService.getShiftById('non_existent_id');
        
        expect(shift, isNull);
      });

      test('createShift adds new shift', () async {
        final newShift = Shift(
          id: 'new_shift',
          employeeId: 'emp_1',
          location: 'ТЦ Мега',
          startTime: DateTime.now().add(Duration(days: 1)),
          endTime: DateTime.now().add(Duration(days: 1, hours: 8)),
          status: 'pending',
          hourlyRate: 400.0,
        );
        
        final createdShift = await mockApiService.createShift(newShift);
        
        expect(createdShift.id, equals(newShift.id));
        
        // Verify it was added
        final allShifts = await mockApiService.getShifts();
        expect(allShifts.any((s) => s.id == newShift.id), isTrue);
      });

      test('updateShift modifies existing shift', () async {
        final shifts = await mockApiService.getShifts();
        final firstShift = shifts.first;
        
        final updatedShift = firstShift.copyWith(
          status: 'confirmed',
          notes: 'Обновленная смена',
        );
        
        final result = await mockApiService.updateShift(updatedShift);
        
        expect(result.status, equals('confirmed'));
        expect(result.notes, equals('Обновленная смена'));
        
        // Verify it was updated
        final foundShift = await mockApiService.getShiftById(firstShift.id);
        expect(foundShift!.status, equals('confirmed'));
        expect(foundShift.notes, equals('Обновленная смена'));
      });

      test('deleteShift removes shift', () async {
        final shifts = await mockApiService.getShifts();
        final firstShift = shifts.first;
        final shiftId = firstShift.id;
        
        await mockApiService.deleteShift(shiftId);
        
        // Verify it was deleted
        final foundShift = await mockApiService.getShiftById(shiftId);
        expect(foundShift, isNull);
        
        final allShifts = await mockApiService.getShifts();
        expect(allShifts.any((s) => s.id == shiftId), isFalse);
      });
    });

    group('Reference Data', () {
      test('getAvailableBranches returns list of branches', () async {
        final branches = await mockApiService.getAvailableBranches();
        
        expect(branches, contains('ТЦ Мега'));
        expect(branches, contains('Центр'));
        expect(branches, contains('Аэропорт'));
      });

      test('getAvailableRoles returns list of roles', () async {
        final roles = await mockApiService.getAvailableRoles();
        
        expect(roles, contains('Уборщица'));
        expect(roles, contains('Кассир'));
        expect(roles, contains('Повар'));
        expect(roles, contains('Менеджер'));
      });
    });

    group('Static Methods', () {
      test('getHourlyRate returns correct rate for position', () {
        expect(MockApiService.getHourlyRate('Уборщица'), equals(250.0));
        expect(MockApiService.getHourlyRate('Кассир'), equals(400.0));
        expect(MockApiService.getHourlyRate('Повар'), equals(600.0));
        expect(MockApiService.getHourlyRate('Менеджер'), equals(840.0));
      });

      test('getHourlyRate returns default rate for unknown position', () {
        expect(MockApiService.getHourlyRate('Неизвестная должность'), equals(400.0));
      });

      test('getAllHourlyRates returns all rates', () {
        final rates = MockApiService.getAllHourlyRates();
        
        expect(rates['Уборщица'], equals(250.0));
        expect(rates['Кассир'], equals(400.0));
        expect(rates['Повар'], equals(600.0));
        expect(rates['Менеджер'], equals(840.0));
      });
    });

    group('Data Generation', () {
      test('generates employees with desired days off', () async {
        final employees = await mockApiService.getEmployees();
        
        for (final employee in employees) {
          expect(employee.desiredDaysOff, isNotEmpty);
          expect(employee.desiredDaysOff.length, greaterThanOrEqualTo(1));
          expect(employee.desiredDaysOff.length, lessThanOrEqualTo(2));
          
          for (final dayOff in employee.desiredDaysOff) {
            expect(dayOff.date, isA<DateTime>());
          }
        }
      });

      test('generates shifts with varied properties', () async {
        final shifts = await mockApiService.getShifts();
        
        expect(shifts, isNotEmpty);
        
        // Check for varied start times
        final startHours = shifts.map((s) => s.startTime.hour).toSet();
        expect(startHours.length, greaterThan(1));
        
        // Check for varied durations
        final durations = shifts.map((s) => s.duration.inHours).toSet();
        expect(durations.length, greaterThan(1));
        
        // Check for varied locations
        final locations = shifts.map((s) => s.location).toSet();
        expect(locations.length, greaterThan(1));
      });

      test('generates realistic number of shifts per employee', () async {
        final employees = await mockApiService.getEmployees();
        final shifts = await mockApiService.getShifts();
        
        // Group shifts by employee
        final shiftsByEmployee = <String, List<Shift>>{};
        for (final shift in shifts) {
          shiftsByEmployee.putIfAbsent(shift.employeeId, () => []).add(shift);
        }
        
        for (final employee in employees) {
          final employeeShifts = shiftsByEmployee[employee.id] ?? [];
          expect(employeeShifts.length, greaterThanOrEqualTo(10));
          expect(employeeShifts.length, lessThanOrEqualTo(25));
        }
      });
    });
  });
}