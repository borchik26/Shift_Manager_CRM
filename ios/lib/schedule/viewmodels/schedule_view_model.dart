import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/viewmodels/shift_data_source.dart';
import 'package:my_app/schedule/utils/shift_conflict_checker.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';
import 'package:my_app/core/utils/debouncer.dart';

class ScheduleViewModel extends ChangeNotifier {
  final EmployeeRepository _employeeRepository;
  final ShiftRepository _shiftRepository;

  // Debouncer for search input (300ms delay)
  final _searchDebouncer = Debouncer(milliseconds: 300);

  // Cache for CalendarResource objects to avoid recreating them
  final Map<String, CalendarResource> _resourceCache = {};

  List<ShiftModel> _shifts = [];
  List<Employee> _employees = [];
  String? _searchQuery;
  String? _employeeFilter;
  String? _locationFilter;
  DateTime? _dateFilter;

  String? get locationFilter => _locationFilter;

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

  /// Helper method to update DataSource without recreating it
  /// This preserves the calendar's internal state and prevents appointments from disappearing
  void _updateDataSource() {
    final filteredShifts = _getFilteredShifts();
    final filteredEmployees = _getFilteredEmployees();

    // Prepare resources list - create FRESH resources every time
    final resources = filteredEmployees.map((employee) {
      return CalendarResource(
        id: employee.id,
        displayName: employee.fullName,
        color: Colors.blue,
        image: employee.avatarUrl != null ? NetworkImage(employee.avatarUrl!) : null,
      );
    }).toList();

    // Add "Open Shifts" resource if needed
    if (_searchQuery == null ||
        _searchQuery!.isEmpty ||
        'open shifts'.contains(_searchQuery!.toLowerCase())) {
      resources.insert(
        0,
        CalendarResource(
          id: 'unassigned',
          displayName: 'Open Shifts',
          color: Colors.grey,
        ),
      );
    }

    // COMPLETELY RECREATE DataSource - this is the safest approach
    dataSource = ShiftDataSource(filteredShifts, resources: resources);

    // Update state for other listeners
    state.value = AsyncData(filteredShifts);
  }

  // Get or create cached resource for an employee
  CalendarResource _getCachedResource(Employee employee) {
    if (_resourceCache.containsKey(employee.id)) {
      return _resourceCache[employee.id]!;
    }

    final resource = CalendarResource(
      id: employee.id,
      displayName: employee.fullName,
      color: Colors.blue,
      image: employee.avatarUrl != null ? NetworkImage(employee.avatarUrl!) : null,
    );

    _resourceCache[employee.id] = resource;
    return resource;
  }

  Future<void> _loadData() async {
    state.value = const AsyncLoading();
    employeesState.value = const AsyncLoading();

    try {
      final shifts = await _shiftRepository.getShifts();
      final employees = await _employeeRepository.getEmployees();

      _shifts = shifts.map(ShiftModel.fromShift).toList();
      _employees = employees;

      // Add "Open Shifts" resource to cache BEFORE calling _updateFilteredList
      if (!_resourceCache.containsKey('unassigned')) {
        _resourceCache['unassigned'] = CalendarResource(
          id: 'unassigned',
          displayName: 'Open Shifts',
          color: Colors.grey,
        );
      }

      _updateFilteredList();

      // Use cached resources instead of recreating them
      final resources = _employees.map(_getCachedResource).toList();
      resources.insert(0, _resourceCache['unassigned']!);

      dataSource = ShiftDataSource(_shifts, resources: resources);
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
    // Simply call the helper method that handles DataSource update
    _updateDataSource();
  }

  // Helper method to get filtered shifts based on current filters
  List<ShiftModel> _getFilteredShifts() {
    var filteredShifts = _shifts;

    // Filter by search query
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      final filteredEmployees = _getFilteredEmployees();

      // Filter shifts by role/location OR if they belong to filtered employees
      filteredShifts = filteredShifts.where((s) {
        final matchesShift = s.roleTitle.toLowerCase().contains(query) ||
            s.location.toLowerCase().contains(query);
        final matchesEmployee = filteredEmployees.any((e) => e.id == s.employeeId);
        return matchesShift || matchesEmployee;
      }).toList();
    }

    if (_employeeFilter != null) {
      filteredShifts = filteredShifts
          .where((s) => s.employeeId == _employeeFilter)
          .toList();
    }

    if (_locationFilter != null) {
      filteredShifts = filteredShifts.where((s) => s.location == _locationFilter).toList();
    }

    if (_dateFilter != null) {
      filteredShifts = filteredShifts.where((s) {
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

    return filteredShifts;
  }

  // Helper method to get filtered employees based on current filters
  List<Employee> _getFilteredEmployees() {
    var filteredEmployees = _employees;

    // Filter by search query (Employee Name)
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filteredEmployees = filteredEmployees.where((e) {
        return e.fullName.toLowerCase().contains(query);
      }).toList();
    }

    return filteredEmployees;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    // Debounce the search to avoid excessive filtering
    _searchDebouncer.run(() {
      _updateFilteredList();
    });
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

  void clearEmployeeFilter() {
    _employeeFilter = null;
    _updateFilteredList();
  }

  void sortEmployees(String sortBy) {
    switch (sortBy) {
      case 'name_asc':
        _employees.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'name_desc':
        _employees.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
      case 'role':
        _employees.sort((a, b) => (a.position ?? '').compareTo(b.position ?? ''));
        break;
      case 'branch':
        _employees.sort((a, b) => (a.branch ?? '').compareTo(b.branch ?? ''));
        break;
    }
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

  Future<void> updateShiftTime(
    String shiftId,
    DateTime newStartTime,
    DateTime newEndTime, {
    String? newResourceId,
  }) async {
    try {
      final shiftIndex = _shifts.indexWhere((s) => s.id == shiftId);
      if (shiftIndex == -1) return;

      final oldShift = _shifts[shiftIndex];
      final updatedShift = oldShift.copyWith(
        startTime: newStartTime,
        endTime: newEndTime,
        employeeId: newResourceId ?? oldShift.employeeId,
      );

      // Check for conflicts before updating
      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: updatedShift,
        existingShifts: _shifts,
        excludeShiftId: shiftId, // Exclude the shift being updated
      );

      // If there are hard errors, reject the update
      if (ShiftConflictChecker.hasHardErrors(conflicts)) {
        final errorMessages = ShiftConflictChecker.getHardErrors(conflicts)
            .map((c) => c.message)
            .join('\n');

        locator<NotifyService>().setToastEvent(
          ToastEventError(
            message: 'Невозможно переместить смену:\n$errorMessages',
          ),
        );
        return; // Don't update
      }

      // If there are warnings, show them but allow update
      if (ShiftConflictChecker.hasWarnings(conflicts)) {
        final warningMessages = ShiftConflictChecker.getWarnings(conflicts)
            .map((c) => c.message)
            .join('\n');

        locator<NotifyService>().setToastEvent(
          ToastEventWarning(
            message: 'Предупреждение:\n$warningMessages',
          ),
        );
      }

      // Optimistic update - update in-place to maintain reference
      _shifts[shiftIndex] = updatedShift;

      // Update DataSource correctly without recreating it
      _updateDataSource();

      // Trigger UI rebuild by notifying listeners
      notifyListeners();

      // Show success message if no warnings
      if (!ShiftConflictChecker.hasWarnings(conflicts)) {
        locator<NotifyService>().setToastEvent(
          ToastEventSuccess(message: 'Смена обновлена'),
        );
      }

      // Call repository
      // await _shiftRepository.updateShift(updatedShift);
    } catch (e) {
      // Revert on error
      await _loadData();
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Failed to update shift: ${e.toString()}'),
      );
    }
  }

  Future<void> deleteShift(String shiftId) async {
    try {
      final shift = _shifts.firstWhere((s) => s.id == shiftId);
      _shifts.removeWhere((s) => s.id == shiftId);

      // Update DataSource correctly without recreating it
      _updateDataSource();

      // Trigger UI rebuild
      notifyListeners();

      // await _shiftRepository.deleteShift(shiftId);

      locator<NotifyService>().setToastEvent(
        ToastEventInfo(message: 'Смена удалена'),
      );
    } catch (e) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Failed to delete shift: ${e.toString()}'),
      );
    }
  }

  Future<void> copyShift(ShiftModel shift) async {
    try {
      // Copy to next day same time
      final newStartTime = shift.startTime.add(const Duration(days: 1));
      final newEndTime = shift.endTime.add(const Duration(days: 1));

      final newShift = shift.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
        startTime: newStartTime,
        endTime: newEndTime,
      );

      _shifts.add(newShift);

      // Update DataSource correctly without recreating it
      _updateDataSource();

      // Trigger UI rebuild
      notifyListeners();

      // await _shiftRepository.createShift(newShift);

      locator<NotifyService>().setToastEvent(
        ToastEventInfo(message: 'Смена скопирована на следующий день'),
      );
    } catch (e) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Failed to copy shift: ${e.toString()}'),
      );
    }
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    state.dispose();
    employeesState.dispose();
    super.dispose();
  }
}
