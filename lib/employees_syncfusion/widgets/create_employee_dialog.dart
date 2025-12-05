import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/validators.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/employees_syncfusion/models/profile_model.dart';
import 'package:uuid/uuid.dart';

class CreateEmployeeDialog extends StatefulWidget {
  const CreateEmployeeDialog({super.key});

  @override
  State<CreateEmployeeDialog> createState() => _CreateEmployeeDialogState();
}

class _CreateEmployeeDialogState extends State<CreateEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _saveState = ValueNotifier<AsyncValue<void>>(const AsyncData(null));
  final _branchesState = ValueNotifier<AsyncValue<List<String>>>(
    const AsyncLoading(),
  );
  final _employeeRepository = locator<EmployeeRepository>();

  // Form fields
  String _firstName = '';
  String _lastName = '';
  String? _selectedPosition;
  String? _selectedBranch;
  DateTime _selectedHireDate = DateTime.now();
  String? _email;
  String? _phone;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await _employeeRepository.getAvailableBranches();
      _branchesState.value = AsyncData(branches);
    } catch (e, s) {
      _branchesState.value = AsyncError(e.toString(), e, s);
    }
  }

  Future<void> _selectHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedHireDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedHireDate = picked);
    }
  }

  double get _currentRate {
    return EmployeeProfile.positionRates[_selectedPosition] ?? 400.0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      locator<NotifyService>().setToastEvent(
        ToastEventWarning(
          message: 'Пожалуйста, заполните все обязательные поля',
        ),
      );
      return;
    }

    _saveState.value = const AsyncLoading();

    try {
      final newEmployee = Employee(
        id: const Uuid().v4(),
        firstName: _firstName.trim(),
        lastName: _lastName.trim(),
        position: _selectedPosition!,
        branch: _selectedBranch!,
        status: 'active',
        hireDate: _selectedHireDate,
        email: _email?.trim(),
        phone: _phone?.trim(),
        avatarUrl: _avatarUrl?.trim().isNotEmpty == true ? _avatarUrl : null,
        desiredDaysOff: const [],
      );

      await _employeeRepository.createEmployee(newEmployee);

      if (!mounted) return;

      locator<NotifyService>().setToastEvent(
        ToastEventSuccess(message: 'Сотрудник успешно добавлен'),
      );
      Navigator.pop(context, true);
    } catch (e, s) {
      _saveState.value = AsyncError(e.toString(), e, s);
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Ошибка создания: ${e.toString()}'),
      );
    }
  }

  @override
  void dispose() {
    _saveState.dispose();
    _branchesState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Добавить сотрудника',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Закрыть',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Секция 1: Основная информация
                  Text(
                    'Основная информация',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Имя',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) => _firstName = value,
                    validator: (value) =>
                        Validators.required(value, fieldName: 'Имя'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Фамилия',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) => _lastName = value,
                    validator: (value) =>
                        Validators.required(value, fieldName: 'Фамилия'),
                  ),
                  const SizedBox(height: 24),

                  // Секция 2: Рабочая информация
                  Text(
                    'Рабочая информация',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedPosition,
                    decoration: InputDecoration(
                      labelText: 'Должность',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: EmployeeProfile.positionRates.keys.map((position) {
                      final rate = EmployeeProfile.positionRates[position]!;
                      return DropdownMenuItem(
                        value: position,
                        child: Text(
                          '$position ($rate ₽/ч)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPosition = value);
                    },
                    validator: (value) =>
                        value == null ? 'Выберите должность' : null,
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<AsyncValue<List<String>>>(
                    valueListenable: _branchesState,
                    builder: (context, state, child) {
                      final branches = state.dataOrNull ?? [];
                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedBranch,
                        decoration: InputDecoration(
                          labelText: 'Филиал',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: branches
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(
                                  b,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedBranch = value),
                        validator: (value) =>
                            value == null ? 'Выберите филиал' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectHireDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Дата приёма на работу',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd.MM.yyyy').format(_selectedHireDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Секция 3: Контакты
                  Text(
                    'Контакты',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => _email = value,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Телефон',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixIcon: const Icon(Icons.phone_outlined),
                      hintText: '+7 (999) 000-00-00',
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) => _phone = value,
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 24),

                  // Секция 4: Дополнительно
                  Text(
                    'Дополнительно',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'URL аватара (опционально)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      prefixIcon: const Icon(Icons.image_outlined),
                      hintText: 'https://example.com/avatar.jpg',
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (value) => _avatarUrl = value,
                  ),
                  const SizedBox(height: 24),

                  // Предпросмотр ставки
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Часовая ставка: ${_currentRate.toInt()} ₽/ч',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Кнопки действий
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Отмена'),
                      ),
                      const SizedBox(width: 16),
                      ValueListenableBuilder<AsyncValue<void>>(
                        valueListenable: _saveState,
                        builder: (context, state, child) {
                          return FilledButton(
                            onPressed: state.isLoading ? null : _save,
                            child: state.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Создать'),
                          );
                        },
                      ),
                    ],
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
