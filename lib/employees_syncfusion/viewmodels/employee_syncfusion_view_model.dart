import 'package:flutter/material.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/data/repositories/branch_repository.dart';
import 'package:my_app/data/repositories/position_repository.dart';
import 'package:my_app/data/models/position.dart';
import 'package:my_app/employees_syncfusion/models/employee_syncfusion_model.dart';
import 'package:my_app/employees_syncfusion/viewmodels/employee_data_source.dart';

class EmployeeSyncfusionViewModel extends ChangeNotifier {
  final EmployeeRepository _employeeRepository;
  final ShiftRepository _shiftRepository;
  final BranchRepository _branchRepository;
  final PositionRepository _positionRepository;

  List<EmployeeSyncfusionModel> _employees = [];
  late final EmployeeDataSource _dataSource;
  String _searchQuery = '';
  String? _selectedBranch;
  String? _selectedRole;
  EmployeeStatus? _selectedStatus;
  Function(String)? _onDeleteEmployee;

  // Filter options loaded from repository
  List<String> _availableBranches = [];
  List<String> _availableRoles = [];
  Map<String, double> _positionRates = {};

  List<EmployeeSyncfusionModel> get employees => _employees;
  EmployeeDataSource get dataSource => _dataSource;
  String get searchQuery => _searchQuery;
  String? get selectedBranch => _selectedBranch;
  String? get selectedRole => _selectedRole;
  EmployeeStatus? get selectedStatus => _selectedStatus;
  int get filteredCount => _dataSource.rows.length;
  int get totalCount => _employees.length;
  List<String> get availableBranches => _availableBranches;
  List<String> get availableRoles => _availableRoles;
  Map<String, double> get positionRates => _positionRates;

  // Get filtered employees list (for mobile cards view)
  List<EmployeeSyncfusionModel> get filteredEmployees {
    List<EmployeeSyncfusionModel> filtered = List.from(_employees);

    // Apply branch filter
    if (_selectedBranch != null && _selectedBranch!.isNotEmpty) {
      filtered = filtered.where((e) => e.branch.trim() == _selectedBranch!.trim()).toList();
    }

    // Apply role filter
    if (_selectedRole != null && _selectedRole!.isNotEmpty) {
      filtered = filtered.where((e) => e.role.trim() == _selectedRole!.trim()).toList();
    }

    // Apply status filter
    if (_selectedStatus != null) {
      filtered = filtered.where((e) => e.status == _selectedStatus).toList();
    }

    // Apply name search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return filtered;
  }

  EmployeeSyncfusionViewModel({
    required EmployeeRepository employeeRepository,
    required ShiftRepository shiftRepository,
    required BranchRepository branchRepository,
    required PositionRepository positionRepository,
    required BuildContext context,
  })  : _employeeRepository = employeeRepository,
        _shiftRepository = shiftRepository,
        _branchRepository = branchRepository,
        _positionRepository = positionRepository {
    // Initialize data source once with a wrapper for the callback
    _dataSource = EmployeeDataSource(
      employees: [],
      onDeleteEmployee: (id) => _onDeleteEmployee?.call(id),
      context: context,
    );

    // Load data
    _loadEmployees();
    _loadFilterOptions();
  }

  Future<void> deleteEmployee(String employeeId) async {
    try {
      // Call repository to delete employee (backend-ready)
      await _employeeRepository.deleteEmployee(employeeId);

      // Remove from local list
      _employees.removeWhere((e) => e.id == employeeId);

      // Reapply filters to update the view
      _applyFilters();
    } catch (e) {
      // Rethrow to let the View handle the error
      rethrow;
    }
  }

  Future<void> createEmployee(Employee employee) async {
    try {
      // Call repository to create employee
      await _employeeRepository.createEmployee(employee);

      // Reload employees to include the new one
      await _loadEmployees();
    } catch (e) {
      // Rethrow to let the View handle the error
      rethrow;
    }
  }

  // Public method to reload employees (e.g., after external changes)
  Future<void> reloadEmployees() async {
    await _loadEmployees();
  }

  void setDeleteCallback(Function(String) callback) {
    _onDeleteEmployee = callback;
    // No need to rebuild dataSource, the wrapper handles it
  }

  Future<void> _loadEmployees() async {
    try {
      // Load employees from repository (backend-ready)
      final employeesFromRepo = await _employeeRepository.getEmployees();

      // Get current month date range for calculating worked hours
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Load all shifts for current month
      final allShifts = await _shiftRepository.getShifts(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      // Convert Employee models to EmployeeSyncfusionModel for UI
      _employees = employeesFromRepo.map((employee) {
        // Map status from string to EmployeeStatus enum
        EmployeeStatus status;
        switch (employee.status) {
          case 'active':
            status = EmployeeStatus.onShift;
            break;
          case 'vacation':
            status = EmployeeStatus.vacation;
            break;
          case 'sick_leave':
            status = EmployeeStatus.dayOff;
            break;
          default:
            status = EmployeeStatus.onShift;
        }

        // Calculate worked hours for this employee
        final employeeShifts = allShifts.where((s) => s.employeeId == employee.id);
        final workedHours = employeeShifts.fold<double>(
          0.0,
          (sum, shift) {
            final duration = shift.endTime.difference(shift.startTime);
            return sum + duration.inHours;
          },
        );

        return EmployeeSyncfusionModel(
          id: employee.id,
          name: '${employee.firstName} ${employee.lastName}',
          role: employee.position,
          branch: employee.branch,
          status: status,
          workedHours: workedHours.toInt(),
          avatarUrl:
              employee.avatarUrl ??
              'https://i.pravatar.cc/150?u=${employee.id}',
        );
      }).toList();

      // Apply filters to show data
      _applyFilters();
    } catch (e) {
      // On error, use empty list or fallback to mock data
      _employees = [];
      _applyFilters();
    }
  }

  // Load filter options from repository
  Future<void> _loadFilterOptions() async {
    try {
      // Branches from branches table
      _availableBranches = await _branchRepository
          .getBranches()
          .then((list) => list.map((b) => b.name).toList());

      // Positions from positions table (names + rates)
      final positions = await _positionRepository.getPositions();
      _availableRoles = positions.map((p) => p.name).toList();
      _positionRates = {
        for (final p in positions) p.name: p.hourlyRate,
      };
      notifyListeners();
    } catch (e) {
      // В случае ошибки используем пустые списки
      _availableBranches = [];
      _availableRoles = [];
      _positionRates = {};
      notifyListeners();
    }
  }

  // Поиск по имени
  void searchByName(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Фильтр по филиалу
  void filterByBranch(String? branch) {
    _selectedBranch = branch;
    _applyFilters();
  }

  // Фильтр по должности
  void filterByRole(String? role) {
    _selectedRole = role;
    _applyFilters();
  }

  // Фильтр по статусу
  void filterByStatus(EmployeeStatus? status) {
    _selectedStatus = status;
    _applyFilters();
  }

  // Применение всех фильтров одновременно (комбинированная фильтрация)
  void _applyFilters() {
    List<EmployeeSyncfusionModel> filtered = List.from(_employees);

    // Применяем фильтр по филиалу
    if (_selectedBranch != null && _selectedBranch!.isNotEmpty) {
      filtered = filtered.where((e) => e.branch.trim() == _selectedBranch!.trim()).toList();
    }

    // Применяем фильтр по должности
    if (_selectedRole != null && _selectedRole!.isNotEmpty) {
      filtered = filtered.where((e) => e.role.trim() == _selectedRole!.trim()).toList();
    }

    // Применяем фильтр по статусу
    if (_selectedStatus != null) {
      filtered = filtered.where((e) => e.status == _selectedStatus).toList();
    }

    // Применяем поиск по имени (поверх отфильтрованных данных)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Update the existing data source instead of creating a new one
    // This ensures the Grid updates correctly and maintains state
    _dataSource.updateDataSource(filtered);
    notifyListeners();
  }

  // Сброс всех фильтров
  void clearFilters() {
    _searchQuery = '';
    _selectedBranch = null;
    _selectedRole = null;
    _selectedStatus = null;
    _applyFilters();
  }
}
