import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/employees_syncfusion/viewmodels/employee_syncfusion_view_model.dart';

// Fake implementations for testing
class FakeEmployeeRepository implements EmployeeRepository {
  List<Employee> _employees = [];
  List<String> _branches = ['ТЦ Мега', 'Центр', 'Аэропорт'];
  List<String> _roles = ['Менеджер', 'Кассир', 'Администратор'];

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
  Future<void> deleteEmployee(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _employees.removeWhere((e) => e.id == employeeId);
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

  // Helper methods for testing
  void setEmployees(List<Employee> employees) {
    _employees = employees;
  }

  void setBranches(List<String> branches) {
    _branches = branches;
  }

  void setRoles(List<String> roles) {
    _roles = roles;
  }

  void setDeleteError(String employeeId, [String? message]) {
    _employees = _employees.where((e) => e.id != employeeId).toList();
    throw Exception(message ?? 'Delete failed');
  }
}

class FakeShiftRepository implements ShiftRepository {
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

  // Helper method for testing
  void setShifts(List<Shift> shifts) {
    _shifts = shifts;
  }
}

void main() {
  group('EmployeeSyncfusionViewModel', () {
    late FakeEmployeeRepository fakeEmployeeRepository;
    late FakeShiftRepository fakeShiftRepository;
    late EmployeeSyncfusionViewModel viewModel;

    setUp(() {
      fakeEmployeeRepository = FakeEmployeeRepository();
      fakeShiftRepository = FakeShiftRepository();
      viewModel = EmployeeSyncfusionViewModel(
        employeeRepository: fakeEmployeeRepository,
        shiftRepository: fakeShiftRepository,
      );
    });

    final mockEmployees = [
      Employee(
        id: 'emp1',
        firstName: 'Иван',
        lastName: 'Петров',
        position: 'Менеджер',
        branch: 'ТЦ Мега',
        status: 'active',
        hireDate: DateTime(2023, 1, 1),
        email: 'ivan@example.com',
        phone: '+1234567890',
      ),
      Employee(
        id: 'emp2',
        firstName: 'Мария',
        lastName: 'Сидорова',
        position: 'Кассир',
        branch: 'Центр',
        status: 'vacation',
        hireDate: DateTime(2023, 2, 1),
        email: 'maria@example.com',
        phone: '+0987654321',
      ),
      Employee(
        id: 'emp3',
        firstName: 'Алексей',
        lastName: 'Иванов',
        position: 'Администратор',
        branch: 'Аэропорт',
        status: 'sick_leave',
        hireDate: DateTime(2023, 3, 1),
        email: 'alex@example.com',
        phone: '+1122334455',
      ),
    ];

    final mockShifts = [
      Shift(
        id: 'shift1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Менеджер',
        location: 'ТЦ Мега',
        status: 'scheduled',
        hourlyRate: 840.0,
      ),
      Shift(
        id: 'shift2',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 2, 9, 0),
        endTime: DateTime(2025, 1, 2, 17, 0),
        roleTitle: 'Менеджер',
        location: 'ТЦ Мега',
        status: 'scheduled',
        hourlyRate: 840.0,
      ),
      Shift(
        id: 'shift3',
        employeeId: 'emp2',
        startTime: DateTime(2025, 1, 1, 10, 0),
        endTime: DateTime(2025, 1, 1, 18, 0),
        roleTitle: 'Кассир',
        location: 'Центр',
        status: 'scheduled',
        hourlyRate: 400.0,
      ),
    ];

    group('Initial State', () {
      test('initial state should have empty search and filters', () {
        expect(viewModel.searchQuery, isEmpty);
        expect(viewModel.selectedBranch, isNull);
        expect(viewModel.selectedRole, isNull);
        expect(viewModel.selectedStatus, isNull);
        expect(viewModel.totalCount, 0); // Initially empty until loaded
        expect(viewModel.filteredCount, 0);
      });
    });

    group('Search by Name', () {
      setUp(() async {
        fakeEmployeeRepository.setEmployees(mockEmployees);
        fakeShiftRepository.setShifts(mockShifts);
        
        // Wait for async loading
        await Future.delayed(const Duration(milliseconds: 150));
      });

      test('searchByName should filter employees by name', () async {
        // Initially all employees should be loaded
        expect(viewModel.totalCount, 3);

        // Search for specific name
        viewModel.searchByName('Иван');
        await Future.delayed(const Duration(milliseconds: 50)); // Wait for async operation
        expect(viewModel.filteredCount, 2); // Иван Петров, Алексей Иванов
        expect(viewModel.searchQuery, 'Иван');

        // Search for exact match
        viewModel.searchByName('Мария');
        await Future.delayed(const Duration(milliseconds: 50)); // Wait for async operation
        expect(viewModel.filteredCount, 1); // Мария Сидорова

        // Search with no results
        viewModel.searchByName('Неизвестный');
        await Future.delayed(const Duration(milliseconds: 50)); // Wait for async operation
        expect(viewModel.filteredCount, 0);
      });

      test('searchByName should be case insensitive', () {
        viewModel.searchByName('иван');
        expect(viewModel.filteredCount, 2); // Иван Петров, Алексей Иванов

        viewModel.searchByName('МАРИЯ');
        expect(viewModel.filteredCount, 1); // Мария Сидорова
      });

      test('searchByName should work with partial matches', () {
        viewModel.searchByName('Пет');
        expect(viewModel.filteredCount, 1); // Петров

        viewModel.searchByName('ов');
        expect(viewModel.filteredCount, 2); // Петров, Иванов
      });
    });

    group('Filter by Branch', () {
      setUp(() async {
        fakeEmployeeRepository.setEmployees(mockEmployees);
        fakeShiftRepository.setShifts(mockShifts);
        
        await Future.delayed(const Duration(milliseconds: 150));
      });

      test('filterByBranch should filter employees by branch', () async {
        expect(viewModel.totalCount, 3);

        // Filter by specific branch
        viewModel.filterByBranch('ТЦ Мега');
        await Future.delayed(const Duration(milliseconds: 50)); // Wait for async operation
        expect(viewModel.filteredCount, 1); // Иван Петров
        expect(viewModel.selectedBranch, 'ТЦ Мега');

        // Filter by another branch
        viewModel.filterByBranch('Центр');
        await Future.delayed(const Duration(milliseconds: 50)); // Wait for async operation
        expect(viewModel.filteredCount, 1); // Мария Сидорова

        // Filter by third branch
        viewModel.filterByBranch('Аэропорт');
        await Future.delayed(const Duration(milliseconds: 50)); // Wait for async operation
        expect(viewModel.filteredCount, 1); // Алексей Иванов
      });

      test('filterByBranch with null should show all employees', () {
        // First filter
        viewModel.filterByBranch('ТЦ Мега');
        expect(viewModel.filteredCount, 1);

        // Clear filter
        viewModel.filterByBranch(null);
        expect(viewModel.filteredCount, 3);
        expect(viewModel.selectedBranch, isNull);
      });

      test('filterByBranch with empty string should show all employees', () {
        // First filter
        viewModel.filterByBranch('ТЦ Мега');
        expect(viewModel.filteredCount, 1);

        // Clear filter with empty string
        viewModel.filterByBranch('');
        expect(viewModel.filteredCount, 3);
        expect(viewModel.selectedBranch, '');
      });
    });

    group('Filter by Role', () {
      setUp(() async {
        fakeEmployeeRepository.setEmployees(mockEmployees);
        fakeShiftRepository.setShifts(mockShifts);
        
        await Future.delayed(const Duration(milliseconds: 150));
      });

      test('filterByRole should filter employees by role', () {
        expect(viewModel.totalCount, 3);

        // Filter by specific role
        viewModel.filterByRole('Менеджер');
        expect(viewModel.filteredCount, 1); // Иван Петров
        expect(viewModel.selectedRole, 'Менеджер');

        // Filter by another role
        viewModel.filterByRole('Кассир');
        expect(viewModel.filteredCount, 1); // Мария Сидорова

        // Filter by third role
        viewModel.filterByRole('Администратор');
        expect(viewModel.filteredCount, 1); // Алексей Иванов
      });

      test('filterByRole with null should show all employees', () {
        // First filter
        viewModel.filterByRole('Менеджер');
        expect(viewModel.filteredCount, 1);

        // Clear filter
        viewModel.filterByRole(null);
        expect(viewModel.filteredCount, 3);
        expect(viewModel.selectedRole, isNull);
      });
    });

    group('Combined Filters', () {
      setUp(() async {
        fakeEmployeeRepository.setEmployees(mockEmployees);
        fakeShiftRepository.setShifts(mockShifts);
        
        await Future.delayed(const Duration(milliseconds: 150));
      });

      test('should apply multiple filters together', () {
        // Apply branch filter
        viewModel.filterByBranch('ТЦ Мега');
        expect(viewModel.filteredCount, 1);

        // Apply role filter (should be 0 - no manager in other branches)
        viewModel.filterByRole('Кассир');
        expect(viewModel.filteredCount, 0);

        // Clear role filter
        viewModel.filterByRole(null);
        expect(viewModel.filteredCount, 1); // Back to Иван Петров

        // Apply search
        viewModel.searchByName('Иван');
        expect(viewModel.filteredCount, 1); // Still Иван Петров

        // Apply search that doesn't match
        viewModel.searchByName('Мария');
        expect(viewModel.filteredCount, 0); // No Мария in ТЦ Мега
      });
    });

    group('Clear Filters', () {
      setUp(() async {
        fakeEmployeeRepository.setEmployees(mockEmployees);
        fakeShiftRepository.setShifts(mockShifts);
        
        await Future.delayed(const Duration(milliseconds: 150));
      });

      test('clearFilters should reset all filters', () {
        // Apply all filters
        viewModel.searchByName('Иван');
        viewModel.filterByBranch('ТЦ Мега');
        viewModel.filterByRole('Менеджер');
        expect(viewModel.filteredCount, 1);

        // Clear all filters
        viewModel.clearFilters();
        
        expect(viewModel.searchQuery, isEmpty);
        expect(viewModel.selectedBranch, isNull);
        expect(viewModel.selectedRole, isNull);
        expect(viewModel.selectedStatus, isNull);
        expect(viewModel.filteredCount, 3); // All employees visible
      });
    });

    group('Delete Employee', () {
      setUp(() async {
        fakeEmployeeRepository.setEmployees(mockEmployees);
        fakeShiftRepository.setShifts(mockShifts);
        
        await Future.delayed(const Duration(milliseconds: 150));
      });

      test('deleteEmployee should remove employee from list', () async {
        expect(viewModel.totalCount, 3);

        // Delete employee
        await viewModel.deleteEmployee('emp1');
        await Future.delayed(const Duration(milliseconds: 50)); // Wait for async operation

        // Employee should be removed from local list
        expect(viewModel.totalCount, 2);
      });

      test('deleteEmployee should rethrow errors', () async {
        // Setup delete error
        fakeEmployeeRepository.setDeleteError('emp1', 'Delete failed');

        // Should rethrow error
        expect(
          () => viewModel.deleteEmployee('emp1'),
          throwsException,
        );
      });
    });

    group('Load Filter Options', () {
      test('should load available branches and roles', () async {
        final mockBranches = ['ТЦ Мега', 'Центр', 'Аэропорт'];
        final mockRoles = ['Менеджер', 'Кассир', 'Администратор'];

        fakeEmployeeRepository.setBranches(mockBranches);
        fakeEmployeeRepository.setRoles(mockRoles);

        // Create new viewModel to trigger loading
        final newViewModel = EmployeeSyncfusionViewModel(
          employeeRepository: fakeEmployeeRepository,
          shiftRepository: fakeShiftRepository,
        );

        // Wait for async loading
        await Future.delayed(const Duration(milliseconds: 150));

        expect(newViewModel.availableBranches, mockBranches);
        expect(newViewModel.availableRoles, mockRoles);
      });

      test('should handle errors when loading filter options', () async {
        // Set empty lists to simulate error
        fakeEmployeeRepository.setBranches([]);
        fakeEmployeeRepository.setRoles([]);

        // Create new viewModel to trigger loading
        final newViewModel = EmployeeSyncfusionViewModel(
          employeeRepository: fakeEmployeeRepository,
          shiftRepository: fakeShiftRepository,
        );

        // Wait for async loading
        await Future.delayed(const Duration(milliseconds: 150));

        // Should have empty lists on error
        expect(newViewModel.availableBranches, isEmpty);
        expect(newViewModel.availableRoles, isEmpty);
      });
    });
  });
}