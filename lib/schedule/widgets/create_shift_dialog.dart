import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/utils/shift_conflict_checker.dart';
import 'package:my_app/schedule/widgets/conflict_warning_box.dart';
import 'package:my_app/schedule/constants/schedule_constants.dart';
import 'package:uuid/uuid.dart';

class CreateShiftDialog extends StatefulWidget {
  final ShiftModel? existingShift;

  const CreateShiftDialog({super.key, this.existingShift});

  @override
  State<CreateShiftDialog> createState() => _CreateShiftDialogState();
}

class _CreateShiftDialogState extends State<CreateShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _shiftRepository = locator<ShiftRepository>();
  final _employeeRepository = locator<EmployeeRepository>();

  final _state = ValueNotifier<AsyncValue<void>>(const AsyncData(null));
  final _employeesState = ValueNotifier<AsyncValue<List<Employee>>>(
    const AsyncLoading(),
  );
  final _shiftsState = ValueNotifier<AsyncValue<List<Shift>>>(
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

  // Use constants from ScheduleConstants
  final List<String> _roles = ScheduleConstants.roles;
  final List<String> _branches = ScheduleConstants.branches;

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

    // Pre-fill form if editing existing shift
    if (widget.existingShift != null) {
      final shift = widget.existingShift!;
      // Don't set employeeId if it's 'unassigned' (free shift)
      _selectedEmployeeId = shift.employeeId != 'unassigned'
          ? shift.employeeId
          : null;
      // Only set role if it exists in the roles list
      _selectedRole = _roles.contains(shift.roleTitle) ? shift.roleTitle : null;
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
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _employeeRepository.getEmployees();
      _employeesState.value = AsyncData(employees);
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

  @override
  void dispose() {
    _state.dispose();
    _employeesState.dispose();
    _shiftsState.dispose();
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

  /// Get hourly rate for a role
  double _getHourlyRateForRole(String? role) {
    const hourlyRates = {
      'Уборщица': 250.0,
      'Кассир': 400.0,
      'Повар': 600.0,
      'Менеджер': 840.0,
    };
    return hourlyRates[role] ?? 400.0;
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
      hourlyRate: _getHourlyRateForRole(_selectedRole),
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
        employeeId:
            _selectedEmployeeId ??
            'unassigned', // Use 'unassigned' if no employee selected
        location: _selectedBranch ?? 'Центр',
        startTime: startDateTime,
        endTime: endDateTime,
        status: 'scheduled',
        employeePreferences: _preferencesController.text.trim().isNotEmpty
            ? _preferencesController.text.trim()
            : null,
        roleTitle: _selectedRole, // Save selected role
        hourlyRate: _getHourlyRateForRole(_selectedRole),
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
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
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
                ValueListenableBuilder<AsyncValue<List<Employee>>>(
                  valueListenable: _employeesState,
                  builder: (context, state, child) {
                    if (state.isLoading) {
                      return const LinearProgressIndicator();
                    }

                    final employees = state.dataOrNull ?? [];

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedEmployeeId,
                      decoration: const InputDecoration(
                        labelText: 'Сотрудник',
                        hintText: 'Оставьте пустым для свободной смены',
                        border: OutlineInputBorder(),
                      ),
                      items: employees.map((e) {
                        return DropdownMenuItem(
                          value: e.id,
                          child: Text('${e.firstName} ${e.lastName}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEmployeeId = value;
                          _ignoreWarning = false;
                        });
                        _checkConflicts();
                      },
                      // Employee is optional - can be null for unassigned shifts
                      validator: null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Должность',
                          border: OutlineInputBorder(),
                        ),
                        items: _roles.map((r) {
                          return DropdownMenuItem(value: r, child: Text(r));
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedRole = value),
                        validator: (value) =>
                            value == null ? 'Выберите должность' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedBranch,
                        decoration: const InputDecoration(
                          labelText: 'Филиал',
                          border: OutlineInputBorder(),
                        ),
                        items: _branches.map((b) {
                          return DropdownMenuItem(value: b, child: Text(b));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedBranch = value);
                          _checkConflicts();
                        },
                        validator: (value) =>
                            value == null ? 'Выберите филиал' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Дата',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Начало',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(_startTime.format(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Конец',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(_endTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Длительность: ${_duration.toStringAsFixed(1)} ч',
                  style: TextStyle(
                    color: _duration < 2 ? Colors.red : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                // Employee Preferences field
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

                // Show conflicts using new ConflictWarningBox component
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

                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            state.isLoading ||
                                (ShiftConflictChecker.hasHardErrors(
                                  _currentConflicts,
                                )) ||
                                (ShiftConflictChecker.hasWarnings(
                                      _currentConflicts,
                                    ) &&
                                    !_ignoreWarning)
                            ? null
                            : _save,
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
    );
  }
}
