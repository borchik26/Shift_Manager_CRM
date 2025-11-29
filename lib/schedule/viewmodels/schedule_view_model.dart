import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/viewmodels/shift_data_source.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';

class ScheduleViewModel extends ChangeNotifier {
  final EmployeeRepository _employeeRepository;
  final ShiftRepository _shiftRepository;

  List<ShiftModel> _shifts = [];
  List<Employee> _employees = [];
  String? _searchQuery;
  String? _employeeFilter;
  String? _locationFilter;
  DateTime? _dateFilter;

  ScheduleViewModel({
    required EmployeeRepository employeeRepository,
    required ShiftRepository shiftRepository,
  }) : _employeeRepository = employeeRepository,
       _shiftRepository = shiftRepository {
    _loadData();
  }

  final state = ValueNotifier<AsyncValue<List<ShiftModel>>>(
    const AsyncLoading(),
  );
  final employeesState = ValueNotifier<AsyncValue<List<Employee>>>(
    const AsyncLoading(),
  );

  ShiftDataSource? dataSource;

  Future<void> _loadData() async {
    state.value = const AsyncLoading();
    employeesState.value = const AsyncLoading();

    try {
      final shifts = await _shiftRepository.getShifts();
      final employees = await _employeeRepository.getEmployees();

      _shifts = shifts.map(ShiftModel.fromShift).toList();
      _employees = employees;

      _updateFilteredList();
      dataSource = ShiftDataSource(_shifts);
      employeesState.value = AsyncData(_employees);
    } catch (e, s) {
      state.value = AsyncError(e.toString(), e, s);
      employeesState.value = AsyncError(e.toString(), e, s);
      // Notify user about error
      locator<NotifyService>().setToastEvent(
        ToastEventError(
          message: 'Failed to load schedule data: ${e.toString()}',
        ),
      );
    }
  }

  void _updateFilteredList() {
    var filtered = _shifts;

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filtered = filtered
          .where(
            (s) =>
                s.roleTitle.toLowerCase().contains(
                  _searchQuery!.toLowerCase(),
                ) ||
                s.location.toLowerCase().contains(_searchQuery!.toLowerCase()),
          )
          .toList();
    }

    if (_employeeFilter != null) {
      filtered = filtered
          .where((s) => s.employeeId == _employeeFilter)
          .toList();
    }

    if (_locationFilter != null) {
      filtered = filtered.where((s) => s.location == _locationFilter).toList();
    }

    if (_dateFilter != null) {
      filtered = filtered.where((s) {
        final shiftDate = DateTime(
          s.startTime.year,
          s.startTime.month,
          s.startTime.day,
        );
        final filterDate = DateTime(
          _dateFilter!.year,
          _dateFilter!.month,
          _dateFilter!.day,
        );
        return shiftDate.isAtSameMomentAs(filterDate);
      }).toList();
    }

    state.value = AsyncData(filtered);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _updateFilteredList();
  }

  void setEmployeeFilter(String? employeeId) {
    _employeeFilter = employeeId;
    _updateFilteredList();
  }

  void setLocationFilter(String? location) {
    _locationFilter = location;
    _updateFilteredList();
  }

  void setDateFilter(DateTime? date) {
    _dateFilter = date;
    _updateFilteredList();
  }

  void clearFilters() {
    _searchQuery = null;
    _employeeFilter = null;
    _locationFilter = null;
    _dateFilter = null;
    _updateFilteredList();
  }

  List<String> getEmployeeNames() {
    return _employees.map((e) => '${e.firstName} ${e.lastName}').toList();
  }

  List<String> getLocations() {
    return ['ТЦ Мега', 'Центр', 'Аэропорт'];
  }

  Future<void> refreshShifts() async {
    await _loadData();
  }

  @override
  void dispose() {
    state.dispose();
    employeesState.dispose();
    super.dispose();
  }
}
