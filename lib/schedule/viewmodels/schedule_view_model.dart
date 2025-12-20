import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/data/repositories/branch_repository.dart';
import 'package:my_app/data/repositories/position_repository.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/models/date_range_filter.dart';
import 'package:my_app/schedule/models/shift_status_filter.dart';
import 'package:my_app/schedule/viewmodels/shift_data_source.dart';
import 'package:my_app/schedule/utils/shift_conflict_checker.dart';
import 'package:my_app/schedule/constants/schedule_view_type.dart';
import 'package:my_app/schedule/utils/schedule_statistics.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';
import 'package:my_app/core/utils/debouncer.dart';

class ScheduleViewModel extends ChangeNotifier {
  final AuthService _authService;
  final EmployeeRepository _employeeRepository;
  final ShiftRepository _shiftRepository;
  final BranchRepository _branchRepository;
  final PositionRepository _positionRepository;

  // Debouncer for search input (300ms delay)
  final _searchDebouncer = Debouncer(milliseconds: 300);

  // Cache for CalendarResource objects to avoid recreating them
  final Map<String, CalendarResource> _resourceCache = {};

  // Track if disposed
  bool _disposed = false;

  List<ShiftModel> _shifts = [];
  List<Employee> _employees = [];
  List<String> _branchOptions = [];
  List<String> _roleOptions = [];
  String? _searchQuery;
  String? _employeeFilter;
  String? _locationFilter;
  String? _roleFilter;
  DateTime? _dateFilter;
  DateRangeFilter _dateRangeFilter = DateRangeFilter.all;
  ShiftStatusFilter _statusFilter = ShiftStatusFilter.all;
  ScheduleViewType _currentViewType = ScheduleViewType.week; // Default view

  String? get locationFilter => _locationFilter;
  String? get roleFilter => _roleFilter;
  String? get employeeFilter => _employeeFilter;
  DateRangeFilter get dateRangeFilter => _dateRangeFilter;
  ShiftStatusFilter get statusFilter => _statusFilter;
  ScheduleViewType get currentViewType => _currentViewType;

  /// Check if current user is a manager (for conditional UI rendering)
  bool get isManager => _authService.isManager;

  /// Количество активных фильтров (для Badge)
  int get activeFiltersCount {
    int count = 0;
    if (_searchQuery != null && _searchQuery!.isNotEmpty) count++;
    if (_employeeFilter != null) count++;
    if (_locationFilter != null) count++;
    if (_roleFilter != null) count++;
    if (_dateFilter != null) count++;
    if (_dateRangeFilter != DateRangeFilter.all) count++;
    if (_statusFilter != ShiftStatusFilter.all) count++;
    return count;
  }

  /// Calculate statistics from filtered shifts
  ScheduleStatistics get statistics {
    final filteredShifts = _getFilteredShifts();
    return ScheduleStatistics.calculate(filteredShifts);
  }

  ScheduleViewModel({
    required AuthService authService,
    required EmployeeRepository employeeRepository,
    required ShiftRepository shiftRepository,
    required BranchRepository branchRepository,
    required PositionRepository positionRepository,
  }) : _authService = authService,
       _employeeRepository = employeeRepository,
       _shiftRepository = shiftRepository,
       _branchRepository = branchRepository,
       _positionRepository = positionRepository {
    _loadData();
    // Preload reference data; UI will refresh on each dropdown tap
    refreshBranches();
    refreshRoles();
  }

  final state = ValueNotifier<AsyncValue<List<ShiftModel>>>(
    const AsyncLoading(),
  );
  final employeesState = ValueNotifier<AsyncValue<List<Employee>>>(
    const AsyncLoading(),
  );
  final branchesState = ValueNotifier<AsyncValue<List<String>>>(
    const AsyncLoading(),
  );
  final rolesState = ValueNotifier<AsyncValue<List<String>>>(
    const AsyncLoading(),
  );

  ShiftDataSource? dataSource;

  /// Helper method to update DataSource without recreating it
  /// This preserves the calendar's internal state and prevents appointments from disappearing
  void _updateDataSource() {
    final filteredEmployees = _getFilteredEmployees();

    // Prepare resources list - create FRESH resources every time
    final resources = filteredEmployees.map((employee) {
      return CalendarResource(
        id: employee.id,
        displayName: employee.fullName,
        color: Colors.blue,
        image: employee.avatarUrl != null
            ? NetworkImage(employee.avatarUrl!)
            : null,
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
          displayName: 'Свободные смены',
          color: Colors.grey,
        ),
      );
    }

    // Create a Set of valid resource IDs for fast lookup
    final validResourceIds = resources.map((r) => r.id).toSet();

    // Get filtered shifts
    final filteredShifts = _getFilteredShifts();

    // IMPORTANT: Filter shifts to only show those with valid resource IDs
    // This prevents IndexOutOfRange errors in Syncfusion Calendar
    final shiftsWithValidResources = filteredShifts.where((shift) {
      final employeeId = shift.employeeId ?? 'unassigned';
      return validResourceIds.contains(employeeId);
    }).toList();

    // COMPLETELY RECREATE DataSource - this is the safest approach
    dataSource = ShiftDataSource(shiftsWithValidResources, resources: resources);

    // Update state for other listeners (only if not disposed)
    if (!_disposed) {
      state.value = AsyncData(shiftsWithValidResources);
      // Notify listeners to trigger UI rebuild with new dataSource
      notifyListeners();
    }
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
      image: employee.avatarUrl != null
          ? NetworkImage(employee.avatarUrl!)
          : null,
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
          displayName: 'Свободные смены',
          color: Colors.grey,
        );
      }

      _updateFilteredList();

      // Use cached resources instead of recreating them
      final resources = _employees.map(_getCachedResource).toList();
      resources.insert(0, _resourceCache['unassigned']!);

      dataSource = ShiftDataSource(_shifts, resources: resources);
      if (!_disposed) {
        employeesState.value = AsyncData(_employees);
      }
    } catch (e, s) {
      if (!_disposed) {
        state.value = AsyncError(e.toString(), e, s);
        employeesState.value = AsyncError(e.toString(), e, s);
      }
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

    // FIRST: Apply role-based filtering for employees
    if (_authService.isEmployee) {
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId != null) {
        filteredShifts = filteredShifts
            .where((s) => s.employeeId == currentUserId)
            .toList();
      }
    }

    // Filter by search query
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      final filteredEmployees = _getFilteredEmployees();

      // Filter shifts by role/location OR if they belong to filtered employees
      filteredShifts = filteredShifts.where((s) {
        final matchesShift =
            s.roleTitle.toLowerCase().contains(query) ||
            s.location.toLowerCase().contains(query);
        final matchesEmployee = filteredEmployees.any(
          (e) => e.id == s.employeeId,
        );
        return matchesShift || matchesEmployee;
      }).toList();
    }

    if (_employeeFilter != null) {
      filteredShifts = filteredShifts
          .where((s) => s.employeeId == _employeeFilter)
          .toList();
    }

    if (_locationFilter != null) {
      filteredShifts = filteredShifts
          .where((s) => s.location == _locationFilter)
          .toList();
    }

    if (_roleFilter != null) {
      filteredShifts = filteredShifts
          .where((s) => s.roleTitle == _roleFilter)
          .toList();
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

    // Filter by date range (Сегодня/Неделя/Месяц)
    if (_dateRangeFilter != DateRangeFilter.all) {
      final startDate = _dateRangeFilter.getStartDate();
      final endDate = _dateRangeFilter.getEndDate();

      if (startDate != null && endDate != null) {
        filteredShifts = filteredShifts.where((s) {
          return s.startTime.isAfter(startDate) &&
              s.startTime.isBefore(endDate);
        }).toList();
      }
    }

    // Filter by status (С конфликтами/Предупреждениями)
    if (_statusFilter != ShiftStatusFilter.all) {
      filteredShifts = filteredShifts.where((s) {
        final conflicts = ShiftConflictChecker.checkConflicts(
          newShift: s,
          existingShifts: _shifts,
          excludeShiftId: s.id,
        );

        switch (_statusFilter) {
          case ShiftStatusFilter.withConflicts:
            return ShiftConflictChecker.hasHardErrors(conflicts);
          case ShiftStatusFilter.withWarnings:
            return ShiftConflictChecker.hasWarnings(conflicts);
          case ShiftStatusFilter.normal:
            return !ShiftConflictChecker.hasHardErrors(conflicts) &&
                !ShiftConflictChecker.hasWarnings(conflicts);
          case ShiftStatusFilter.all:
            return true;
        }
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

  void setRoleFilter(String? role) {
    _roleFilter = role;
    _updateFilteredList();
  }

  void setDateFilter(DateTime? date) {
    _dateFilter = date;
    _updateFilteredList();
  }

  void setDateRangeFilter(DateRangeFilter filter) {
    _dateRangeFilter = filter;
    _updateFilteredList();
  }

  void setStatusFilter(ShiftStatusFilter filter) {
    _statusFilter = filter;
    _updateFilteredList();
  }

  void clearFilters() {
    _searchQuery = null;
    _employeeFilter = null;
    _locationFilter = null;
    _roleFilter = null;
    _dateFilter = null;
    _dateRangeFilter = DateRangeFilter.all;
    _statusFilter = ShiftStatusFilter.all;
    _updateFilteredList();
  }

  void clearEmployeeFilter() {
    _employeeFilter = null;
    _updateFilteredList();
  }

  /// Load fresh branches from repository (Supabase)
  Future<void> refreshBranches() async {
    branchesState.value = const AsyncLoading();
    try {
      final branches = await _branchRepository.getBranches();
      _branchOptions = branches.map((b) => b.name).toList();
      _branchOptions.sort();
      branchesState.value = AsyncData(_branchOptions);
    } catch (e, s) {
      branchesState.value = AsyncError(e.toString(), e, s);
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Не удалось загрузить филиалы: $e'),
      );
    }
  }

  /// Load fresh roles from repository (Supabase)
  Future<void> refreshRoles() async {
    rolesState.value = const AsyncLoading();
    try {
      final positions = await _positionRepository.getPositions();
      _roleOptions = positions.map((p) => p.name).toList();
      _roleOptions.sort();
      rolesState.value = AsyncData(_roleOptions);
    } catch (e, s) {
      rolesState.value = AsyncError(e.toString(), e, s);
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Не удалось загрузить должности: $e'),
      );
    }
  }

  /// Change calendar view type (Day/Week/Month)
  void changeViewType(ScheduleViewType newViewType) {
    if (_currentViewType != newViewType) {
      _currentViewType = newViewType;
      notifyListeners();
    }
  }

  void sortEmployees(String sortBy) {
    // Create a mutable copy of the list before sorting
    _employees = List<Employee>.from(_employees);

    switch (sortBy) {
      case 'name_asc':
        _employees.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'name_desc':
        _employees.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
      case 'role':
        _employees.sort(
          (a, b) => a.position.compareTo(b.position),
        );
        break;
      case 'branch':
        _employees.sort(
          (a, b) => a.branch.compareTo(b.branch),
        );
        break;
    }
    // _updateFilteredList() already calls notifyListeners() via _updateDataSource()
    _updateFilteredList();
  }

  List<String> getEmployeeNames() {
    return _employees.map((e) => '${e.firstName} ${e.lastName}').toList();
  }

  List<String> getLocations() {
    return _branchOptions;
  }

  List<String> getRoles() {
    return _roleOptions;
  }

  List<String> getBranches() {
    return _branchOptions;
  }

  /// Get list of unique professions from current shifts (for mobile grid view)
  /// Returns professions sorted alphabetically
  List<String> getUniqueProfessions() {
    final professions = <String>{};
    for (final shift in _getFilteredShifts()) {
      professions.add(shift.roleTitle);
    }

    // Alphabetical sort
    return professions.toList()..sort();
  }

  /// Get unique professions WITH "Open Shifts" row for mobile grid
  /// Adds "Свободные смены" as first row if there are unassigned shifts
  List<String> getUniqueProfessionsWithOpenShifts() {
    final professions = getUniqueProfessions();

    // Check if there are any unassigned shifts
    final hasUnassignedShifts = _getFilteredShifts()
        .any((shift) => shift.employeeId == 'unassigned');

    if (hasUnassignedShifts) {
      return ['Свободные смены', ...professions];
    }

    return professions;
  }

  /// Get shifts for specific profession and date (for mobile grid cells)
  /// Filters by both profession (roleTitle) and same calendar day
  /// Special case: "Свободные смены" returns unassigned shifts
  List<ShiftModel> getShiftsForProfessionAndDate(
    String profession,
    DateTime date,
  ) {
    final filteredShifts = _getFilteredShifts();

    return filteredShifts.where((shift) {
      final sameDay = shift.startTime.year == date.year &&
                      shift.startTime.month == date.month &&
                      shift.startTime.day == date.day;

      // Special case: "Свободные смены" row shows unassigned shifts
      if (profession == 'Свободные смены') {
        return shift.employeeId == 'unassigned' && sameDay;
      }

      return shift.roleTitle == profession && sameDay;
    }).toList();
  }

  /// Get employee full name by ID (for shift cards in mobile grid)
  /// Returns null if employee not found or if employeeId is 'unassigned'
  String? getEmployeeNameById(String employeeId) {
    // Handle unassigned shifts explicitly
    if (employeeId == 'unassigned') {
      return null;
    }

    try {
      return _employees.firstWhere((e) => e.id == employeeId).fullName;
    } catch (_) {
      return null;
    }
  }

  /// Get list of dates for horizontal scroll (mobile grid header)
  /// Returns 7 consecutive days starting from today at midnight
  List<DateTime> getDateRange() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      return DateTime(today.year, today.month, today.day + i);
    });
  }

  /// Check if current user can edit the shift
  bool _canEditShift(ShiftModel shift) {
    if (_authService.isManager) return true;

    if (_authService.isEmployee) {
      final currentUserId = _authService.currentUser?.id;
      return shift.employeeId == currentUserId;
    }

    return false;
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

      // Check permissions
      if (!_canEditShift(oldShift)) {
        locator<NotifyService>().setToastEvent(
          ToastEventError(message: 'У вас нет прав на редактирование этой смены'),
        );
        return;
      }

      // Handle 'unassigned' resource: convert to null for database
      final String? finalEmployeeId = newResourceId == 'unassigned'
          ? null
          : (newResourceId ?? oldShift.employeeId);

      final updatedShift = oldShift.copyWith(
        startTime: newStartTime,
        endTime: newEndTime,
        employeeId: finalEmployeeId,
      );

      // Check for conflicts before updating
      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: updatedShift,
        existingShifts: _shifts,
        excludeShiftId: shiftId, // Exclude the shift being updated
      );

      // If there are hard errors, reject the update
      if (ShiftConflictChecker.hasHardErrors(conflicts)) {
        final errorMessages = ShiftConflictChecker.getHardErrors(
          conflicts,
        ).map((c) => c.message).join('\n');

        locator<NotifyService>().setToastEvent(
          ToastEventError(
            message: 'Невозможно переместить смену:\n$errorMessages',
          ),
        );
        return; // Don't update
      }

      // If there are warnings, show them but allow update
      if (ShiftConflictChecker.hasWarnings(conflicts)) {
        final warningMessages = ShiftConflictChecker.getWarnings(
          conflicts,
        ).map((c) => c.message).join('\n');

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

      // Convert ShiftModel to Shift and save to database
      final shiftToSave = Shift(
        id: updatedShift.id,
        employeeId: updatedShift.employeeId,
        location: updatedShift.location,
        startTime: updatedShift.startTime,
        endTime: updatedShift.endTime,
        status: 'scheduled',
        employeePreferences: updatedShift.employeePreferences,
        roleTitle: updatedShift.roleTitle,
        hourlyRate: updatedShift.hourlyRate,
      );
      await _shiftRepository.updateShift(shiftToSave);
    } catch (e) {
      // Revert on error
      await _loadData();
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Ошибка при сохранении смены: ${e.toString()}'),
      );
    }
  }

  Future<void> deleteShift(String shiftId) async {
    try {
      // Find the shift to check permissions
      final shiftToDelete = _shifts.firstWhere(
        (s) => s.id == shiftId,
        orElse: () => throw Exception('Смена не найдена'),
      );

      // Check permissions
      if (!_canEditShift(shiftToDelete)) {
        locator<NotifyService>().setToastEvent(
          ToastEventError(message: 'У вас нет прав на удаление этой смены'),
        );
        return;
      }

      _shifts.removeWhere((s) => s.id == shiftId);

      // Update DataSource correctly without recreating it
      _updateDataSource();

      // Trigger UI rebuild
      notifyListeners();

      // Save deletion to database
      await _shiftRepository.deleteShift(shiftId);

      locator<NotifyService>().setToastEvent(
        ToastEventInfo(message: 'Смена удалена'),
      );
    } catch (e) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Ошибка при удалении смены: ${e.toString()}'),
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

      // Save new shift to database
      final shiftToSave = Shift(
        id: newShift.id,
        employeeId: newShift.employeeId,
        location: newShift.location,
        startTime: newShift.startTime,
        endTime: newShift.endTime,
        status: 'scheduled',
        employeePreferences: newShift.employeePreferences,
        roleTitle: newShift.roleTitle,
        hourlyRate: newShift.hourlyRate,
      );
      await _shiftRepository.createShift(shiftToSave);

      locator<NotifyService>().setToastEvent(
        ToastEventInfo(message: 'Смена скопирована на следующий день'),
      );
    } catch (e) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Ошибка при копировании смены: ${e.toString()}'),
      );
    }
  }

  /// Get a DataSource for Month view without resources
  /// Month view in Syncfusion Calendar doesn't work well with resources
  ShiftDataSource? getMonthDataSource() {
    final filteredShifts = _getFilteredShifts();
    // Return data source WITHOUT resources for month view
    return ShiftDataSource(filteredShifts, resources: []);
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebouncer.dispose();
    state.dispose();
    employeesState.dispose();
    branchesState.dispose();
    rolesState.dispose();
    super.dispose();
  }
}
