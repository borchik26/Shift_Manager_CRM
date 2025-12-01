import 'package:flutter/material.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/employees_syncfusion/models/employee_syncfusion_model.dart';
import 'package:my_app/employees_syncfusion/viewmodels/employee_data_source.dart';

class EmployeeSyncfusionViewModel extends ChangeNotifier {
  final EmployeeRepository _employeeRepository;

  List<EmployeeSyncfusionModel> _employees = [];
  late EmployeeDataSource _dataSource;
  String _searchQuery = '';
  String? _selectedBranch;
  String? _selectedRole;
  EmployeeStatus? _selectedStatus;

  // Filter options loaded from repository
  List<String> _availableBranches = [];
  List<String> _availableRoles = [];

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

  EmployeeSyncfusionViewModel({required EmployeeRepository employeeRepository})
    : _employeeRepository = employeeRepository {
    _loadEmployees();
    _loadFilterOptions();
  }

  void _loadEmployees() {
    _employees = EmployeeSyncfusionModel.generateMockList();
    _dataSource = EmployeeDataSource(employees: _employees);
    notifyListeners();
  }

  // Load filter options from repository
  Future<void> _loadFilterOptions() async {
    try {
      _availableBranches = await _employeeRepository.getAvailableBranches();
      _availableRoles = await _employeeRepository.getAvailableRoles();
      notifyListeners();
    } catch (e) {
      // В случае ошибки используем пустые списки
      _availableBranches = [];
      _availableRoles = [];
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
      filtered = filtered.where((e) => e.branch == _selectedBranch).toList();
    }

    // Применяем фильтр по должности
    if (_selectedRole != null && _selectedRole!.isNotEmpty) {
      filtered = filtered.where((e) => e.role == _selectedRole).toList();
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
