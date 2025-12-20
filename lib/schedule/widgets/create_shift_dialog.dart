import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/data/models/branch.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/models/position.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/data/repositories/branch_repository.dart';
import 'package:my_app/data/repositories/position_repository.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/utils/shift_conflict_checker.dart';
import 'package:my_app/schedule/widgets/conflict_warning_box.dart';
import 'package:my_app/schedule/widgets/shift_form_employee_section.dart';
import 'package:my_app/schedule/widgets/shift_form_datetime_section.dart';
import 'package:my_app/schedule/widgets/shift_form_location_section.dart';
import 'package:uuid/uuid.dart';

class CreateShiftDialog extends StatefulWidget {
  final ShiftModel? existingShift;
  final DateTime? initialDate; // Pre-fill date when creating from mobile grid
  final String?
  initialProfession; // Pre-fill profession when creating from mobile grid

  const CreateShiftDialog({
    super.key,
    this.existingShift,
    this.initialDate,
    this.initialProfession,
  });

  @override
  State<CreateShiftDialog> createState() => _CreateShiftDialogState();
}

class _CreateShiftDialogState extends State<CreateShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _shiftRepository = locator<ShiftRepository>();
  final _employeeRepository = locator<EmployeeRepository>();
  final _branchRepository = locator<BranchRepository>();
  final _positionRepository = locator<PositionRepository>();

  final _state = ValueNotifier<AsyncValue<void>>(const AsyncData(null));
  final _employeesState = ValueNotifier<AsyncValue<List<Employee>>>(
    const AsyncLoading(),
  );
  final _shiftsState = ValueNotifier<AsyncValue<List<Shift>>>(
    const AsyncLoading(),
  );
  final _branchesState = ValueNotifier<AsyncValue<List<Branch>>>(
    const AsyncLoading(),
  );
  final _positionsState = ValueNotifier<AsyncValue<List<Position>>>(
    const AsyncLoading(),
  );

  String? _selectedEmployeeId;
  String? _selectedRole;
  String? _selectedBranch;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _ignoreWarning = false;
  final _preferencesController = TextEditingController();

  List<ShiftConflict> _currentConflicts = [];

  Map<String, double> _positionRates = {};
  String? _resolveBranch(String? desired) {
    final branches = _branchesState.value.dataOrNull ?? const <Branch>[];
    final names = branches.map((b) => b.name).toList();
    if (desired != null && names.contains(desired)) return desired;
    if (names.isNotEmpty) return names.first;
    return null;
  }

  void _syncSelectionWithEmployee() {
    if (_selectedEmployeeId == null) return;
    final employees = _employeesState.value.dataOrNull ?? [];

    // Use where().firstOrNull instead of firstWhere to avoid exception
    final employee = employees
        .where((e) => e.id == _selectedEmployeeId)
        .firstOrNull;

    if (employee == null) {
      // Employee not found - clear selection
      setState(() => _selectedEmployeeId = null);
      return;
    }

    final resolvedBranch = _resolveBranch(employee.branch);
    setState(() {
      _selectedRole = employee.position;
      _selectedBranch = resolvedBranch;
    });
  }

  /// Build map of employee ID -> desired days off for conflict checking
  Map<String, List<DesiredDayOff>> _getDesiredDaysOffMap() {
    final employees = _employeesState.value.dataOrNull ?? [];
    return {
      for (final employee in employees)
        if (employee.desiredDaysOff.isNotEmpty)
          employee.id: employee.desiredDaysOff,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _loadShifts();
    _loadBranches();
    _loadPositions();

    // Pre-fill form if editing existing shift
    if (widget.existingShift != null) {
      final shift = widget.existingShift!;
      // Don't set employeeId if it's 'unassigned' (free shift)
      _selectedEmployeeId = shift.employeeId != 'unassigned'
          ? shift.employeeId
          : null;
      _selectedRole = shift.roleTitle.isNotEmpty == true
          ? shift.roleTitle
          : null;
      _selectedBranch = shift.location;
      _selectedDate = DateTime(
        shift.startTime.year,
        shift.startTime.month,
        shift.startTime.day,
      );
      _startTime = TimeOfDay(
        hour: shift.startTime.hour,
        minute: shift.startTime.minute,
      );
      _endTime = TimeOfDay(
        hour: shift.endTime.hour,
        minute: shift.endTime.minute,
      );
      if (shift.employeePreferences != null) {
        _preferencesController.text = shift.employeePreferences!;
      }
    } else {
      // Pre-fill from mobile grid tap (if provided)
      if (widget.initialDate != null) {
        _selectedDate = widget.initialDate!;
      }
      if (widget.initialProfession != null &&
          _positionsState.value.dataOrNull?.any(
                (p) => p.name == widget.initialProfession,
              ) ==
              true) {
        _selectedRole = widget.initialProfession;
      }
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _employeeRepository.getEmployees();
      _employeesState.value = AsyncData(employees);
      _syncSelectionWithEmployee();
      // If no employees, keep optional selection but allow free shifts
    } catch (e, s) {
      _employeesState.value = AsyncError(e.toString(), e, s);
    }
  }

  Future<void> _loadShifts() async {
    try {
      final shifts = await _shiftRepository.getShifts();
      _shiftsState.value = AsyncData(shifts);
    } catch (e, s) {
      _shiftsState.value = AsyncError(e.toString(), e, s);
    }
  }

  Future<void> _loadBranches() async {
    _branchesState.value = const AsyncLoading();
    try {
      final branches = await _branchRepository.getBranches();
      // Sort by name
      final sortedBranches = List<Branch>.from(branches)
        ..sort((a, b) => a.name.compareTo(b.name));
      _branchesState.value = AsyncData(sortedBranches);
      _syncSelectionWithEmployee();
      final names = sortedBranches.map((b) => b.name).toList();
      if (_selectedBranch == null && names.isNotEmpty) {
        setState(() => _selectedBranch = names.first);
      } else if (_selectedBranch != null &&
          names.isNotEmpty &&
          !names.contains(_selectedBranch)) {
        setState(() => _selectedBranch = names.first);
      } else if (names.isEmpty) {
        setState(() => _selectedBranch = null);
      }
    } catch (e, s) {
      _branchesState.value = AsyncError(e.toString(), e, s);
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Не удалось загрузить филиалы: $e'),
      );
    }
  }

  Future<void> _loadPositions() async {
    _positionsState.value = const AsyncLoading();
    try {
      final positions = await _positionRepository.getPositions();
      // Sort by name for consistent display
      final sortedPositions = List<Position>.from(positions)
        ..sort((a, b) => a.name.compareTo(b.name));

      _positionRates = {for (final p in sortedPositions) p.name: p.hourlyRate};
      _positionsState.value = AsyncData(sortedPositions);

      final names = sortedPositions.map((p) => p.name).toList();

      // Apply initial profession if provided and not yet set
      if (_selectedRole == null &&
          widget.initialProfession != null &&
          names.contains(widget.initialProfession)) {
        setState(() => _selectedRole = widget.initialProfession);
      } else if (_selectedEmployeeId == null) {
        // When no employee selected, manage position selection
        if (_selectedRole == null && names.isNotEmpty) {
          setState(() => _selectedRole = names.first);
        } else if (_selectedRole != null &&
            names.isNotEmpty &&
            !names.contains(_selectedRole)) {
          setState(() => _selectedRole = names.first);
        } else if (names.isEmpty) {
          setState(() => _selectedRole = null);
        }
      } else {
        // When employee is selected, validate their position still exists
        if (_selectedRole != null &&
            names.isNotEmpty &&
            !names.contains(_selectedRole)) {
          setState(() => _selectedRole = names.first);
        } else if (_selectedRole != null && names.isEmpty) {
          setState(() => _selectedRole = null);
        }
      }
    } catch (e, s) {
      _positionsState.value = AsyncError(e.toString(), e, s);
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Не удалось загрузить должности: $e'),
      );
    }
  }

  @override
  void dispose() {
    _state.dispose();
    _employeesState.dispose();
    _shiftsState.dispose();
    _branchesState.dispose();
    _positionsState.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _checkConflicts();
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
      _checkConflicts();
    }
  }

  double get _duration {
    final start = _startTime.hour + _startTime.minute / 60.0;
    final end = _endTime.hour + _endTime.minute / 60.0;
    if (end < start) return (24 - start) + end;
    return end - start;
  }

  double get _currentRate {
    if (_selectedRole == null) return 0.0;
    return _positionRates[_selectedRole] ?? 0.0;
  }

  void _onEmployeeSelected(String? employeeId) {
    setState(() {
      _selectedEmployeeId = employeeId;
      _ignoreWarning = false;
    });

    if ((_positionsState.value.dataOrNull?.isEmpty ?? true) &&
        !_positionsState.value.isLoading) {
      _loadPositions();
    }

    if (employeeId == null) {
      _checkConflicts();
      return;
    }

    final employees = _employeesState.value.dataOrNull ?? [];

    // Use where().firstOrNull instead of firstWhere to avoid exception
    final employee = employees
        .where((e) => e.id == employeeId)
        .firstOrNull;

    if (employee != null) {
      final resolvedBranch = _resolveBranch(employee.branch);
      setState(() {
        _selectedRole = employee.position;
        _selectedBranch = resolvedBranch;
      });
    }

    _checkConflicts();
  }

  /// Check conflicts for the current shift configuration
  void _checkConflicts() {
    // Skip conflict checking for unassigned shifts or if employee not selected
    if (_selectedEmployeeId == null || _selectedBranch == null) {
      setState(() => _currentConflicts = []);
      return;
    }

    final shifts = _shiftsState.value.dataOrNull ?? [];

    // Create temporary ShiftModel for conflict checking
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    var endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    final tempShift = ShiftModel(
      id: 'temp',
      employeeId: _selectedEmployeeId!,
      startTime: startDateTime,
      endTime: endDateTime,
      roleTitle: _selectedRole ?? '',
      location: _selectedBranch!,
      color: Colors.blue,
      hourlyRate: _currentRate,
    );

    // Convert Shift to ShiftModel for conflict checking
    final existingShifts = shifts.map(ShiftModel.fromShift).toList();

    final conflicts = ShiftConflictChecker.checkConflicts(
      newShift: tempShift,
      existingShifts: existingShifts,
      employeeDesiredDaysOff: _getDesiredDaysOffMap(),
      excludeShiftId:
          widget.existingShift?.id, // Exclude current shift when editing
    );

    setState(() {
      _currentConflicts = conflicts;
      // Reset ignore warning when conflicts change
      if (ShiftConflictChecker.hasHardErrors(conflicts)) {
        _ignoreWarning = false;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final hasBranches = _branchesState.value.dataOrNull?.isNotEmpty ?? false;
    final hasPositions = _positionsState.value.dataOrNull?.isNotEmpty ?? false;
    final hasEmployees = _employeesState.value.dataOrNull?.isNotEmpty ?? false;

    if (!hasBranches || !hasPositions) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(
          message: 'Добавьте должность и филиал перед созданием смены',
        ),
      );
      return;
    }

    if (_selectedEmployeeId != null && !hasEmployees) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(
          message: 'Нет сотрудников для назначения смены',
        ),
      );
      return;
    }

    if (_selectedEmployeeId != null && _selectedRole == null) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(
          message: 'У выбранного сотрудника нет должности',
        ),
      );
      return;
    }

    if (_selectedEmployeeId == null && _selectedRole == null) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(
          message: 'Для свободной смены выберите должность',
        ),
      );
      return;
    }

    // Check for hard errors
    final hasHardErrors = ShiftConflictChecker.hasHardErrors(_currentConflicts);
    if (hasHardErrors) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(
          message: widget.existingShift != null
              ? 'Невозможно обновить смену из-за конфликтов'
              : 'Невозможно создать смену из-за конфликтов',
        ),
      );
      return;
    }

    // Check if user needs to acknowledge warnings
    final hasWarnings = ShiftConflictChecker.hasWarnings(_currentConflicts);
    if (hasWarnings && !_ignoreWarning) {
      locator<NotifyService>().setToastEvent(
        ToastEventWarning(
          message: 'Подтвердите предупреждение для продолжения',
        ),
      );
      return;
    }

    _state.value = const AsyncLoading();

    try {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      var endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      final shift = Shift(
        id: widget.existingShift?.id ?? const Uuid().v4(),
        employeeId: _selectedEmployeeId, // null if no employee selected
        location: _selectedBranch!,
        startTime: startDateTime,
        endTime: endDateTime,
        status: 'scheduled',
        employeePreferences: _preferencesController.text.trim().isNotEmpty
            ? _preferencesController.text.trim()
            : null,
        roleTitle: _selectedRole, // Save selected role
        hourlyRate: _currentRate,
      );

      // Call create or update based on whether we're editing
      if (widget.existingShift != null) {
        await _shiftRepository.updateShift(shift);
      } else {
        await _shiftRepository.createShift(shift);
      }

      if (!mounted) return;

      locator<NotifyService>().setToastEvent(
        ToastEventSuccess(
          message: widget.existingShift != null
              ? 'Смена обновлена. Уведомление отправлено'
              : 'Смена создана. Уведомление отправлено',
        ),
      );
      Navigator.pop(context, true);
    } catch (e, s) {
      _state.value = AsyncError(e.toString(), e, s);
      locator<NotifyService>().setToastEvent(
        ToastEventError(
          message: widget.existingShift != null
              ? 'Ошибка при обновлении смены: ${e.toString()}'
              : 'Ошибка при создании смены: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.existingShift != null
                            ? 'Редактировать смену'
                            : 'Создать смену',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ShiftFormEmployeeSection(
                    employeesState: _employeesState,
                    selectedEmployeeId: _selectedEmployeeId,
                    onEmployeeSelected: _onEmployeeSelected,
                  ),
                  const SizedBox(height: 16),
                  ShiftFormLocationSection(
                    positionsState: _positionsState,
                    branchesState: _branchesState,
                    selectedRole: _selectedRole,
                    selectedBranch: _selectedBranch,
                    selectedEmployeeId: _selectedEmployeeId,
                    onRoleChanged: (value) {
                      setState(() => _selectedRole = value);
                      _checkConflicts();
                    },
                    onBranchChanged: (value) {
                      setState(() => _selectedBranch = value);
                      _checkConflicts();
                    },
                    onLoadPositions: _loadPositions,
                    onLoadBranches: _loadBranches,
                  ),
                  const SizedBox(height: 16),
                  ShiftFormDateTimeSection(
                    selectedDate: _selectedDate,
                    startTime: _startTime,
                    endTime: _endTime,
                    duration: _duration,
                    onSelectDate: _selectDate,
                    onSelectTime: _selectTime,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _preferencesController,
                    decoration: const InputDecoration(
                      labelText: 'Пожелания сотрудника',
                      hintText: 'Напр: предпочитает утренние смены',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.comment_outlined),
                      helperText: 'Необязательное поле',
                    ),
                    maxLines: 2,
                    maxLength: 100,
                  ),
                  if (_currentConflicts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ConflictWarningBox(
                      conflicts: _currentConflicts,
                      showIgnoreOption: true,
                      ignoreWarning: _ignoreWarning,
                      onIgnoreChanged: (value) {
                        setState(() => _ignoreWarning = value);
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  ValueListenableBuilder<AsyncValue<void>>(
                    valueListenable: _state,
                    builder: (context, state, child) {
                      if (state.hasError) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Ошибка: ${state.errorOrNull}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final hasBranches =
                          _branchesState.value.dataOrNull?.isNotEmpty ?? false;
                      final hasPositions =
                          _positionsState.value.dataOrNull?.isNotEmpty ?? false;

                      final shouldDisable =
                          state.isLoading ||
                          (ShiftConflictChecker.hasHardErrors(
                            _currentConflicts,
                          )) ||
                          (ShiftConflictChecker.hasWarnings(
                                _currentConflicts,
                              ) &&
                              !_ignoreWarning) ||
                          !hasBranches ||
                          !hasPositions;

                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: shouldDisable ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: state.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Сохранить'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
