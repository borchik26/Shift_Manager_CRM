import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/employees/models/employee_list_model.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';

class EmployeeListViewModel extends ChangeNotifier {
  final EmployeeRepository _employeeRepository;
  
  List<EmployeeListModel> _employees = [];
  String? _searchQuery;
  String? _branchFilter;
  EmployeeStatus? _statusFilter;

  EmployeeListViewModel({required EmployeeRepository employeeRepository})
      : _employeeRepository = employeeRepository {
    _loadEmployees();
  }

  final state = ValueNotifier<AsyncValue<List<EmployeeListModel>>>(const AsyncLoading());

  Future<void> _loadEmployees() async {
    state.value = const AsyncLoading();
    try {
      final employees = await _employeeRepository.getEmployees();
      _employees = employees.map(EmployeeListModel.fromEmployee).toList();
      _updateFilteredList();
    } catch (e, s) {
      state.value = AsyncError(e.toString(), e, s);
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Ошибка загрузки сотрудников: ${e.toString()}'),
      );
    }
  }

  void _updateFilteredList() {
    var filtered = _employees;

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filtered = filtered.where((e) => 
        e.name.toLowerCase().contains(_searchQuery!.toLowerCase())
      ).toList();
    }

    if (_branchFilter != null) {
      filtered = filtered.where((e) => e.branch == _branchFilter).toList();
    }

    if (_statusFilter != null) {
      filtered = filtered.where((e) => e.status == _statusFilter).toList();
    }

    state.value = AsyncData(filtered);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _updateFilteredList();
  }

  void setBranchFilter(String? branch) {
    _branchFilter = branch;
    _updateFilteredList();
  }

  void setStatusFilter(EmployeeStatus? status) {
    _statusFilter = status;
    _updateFilteredList();
  }

  List<PlutoRow> getPlutoRows(List<EmployeeListModel> employees) {
    return employees.map((e) {
      return PlutoRow(
        cells: {
          'id': PlutoCell(value: e.id),
          'avatar': PlutoCell(value: e.avatarUrl),
          'name': PlutoCell(value: e.name),
          'role': PlutoCell(value: e.role),
          'branch': PlutoCell(value: e.branch),
          'status': PlutoCell(value: e.status),
          'hours': PlutoCell(value: e.hours),
          'actions': PlutoCell(value: 'actions'),
        },
      );
    }).toList();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }
}