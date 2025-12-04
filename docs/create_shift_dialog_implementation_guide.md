# ➕ Create Shift Dialog - Implementation Guide

## 🎯 Задача
Реализовать модальное окно "Создать смену" с валидацией, проверкой конфликтов и интеграцией в Schedule Screen.

---

## 📚 Входные данные

### 1. Референс UI
- **Файл**: `Sozdanie-smeny.jpeg`
- **Стиль**: Модальное окно с формой
- **Особенности**: Warning box для конфликтов

### 2. Связанный экран
- **ScheduleScreen**: График смен с Syncfusion Calendar

### 3. Стек технологий
- **Flutter**: Последняя версия
- **State Management**: Local State (StatefulWidget)
- **UI**: Material 3

---

## 🏗️ Реализация

### ЧАСТЬ 1: Модальное окно (`lib/schedule/widgets/create_shift_dialog.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateShiftDialog extends StatefulWidget {
  const CreateShiftDialog({super.key});

  @override
  State<CreateShiftDialog> createState() => _CreateShiftDialogState();
}

class _CreateShiftDialogState extends State<CreateShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  String? _selectedEmployeeId;
  String? _selectedRole;
  String? _selectedBranch;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _ignoreWarning = false;

  // Mock data
  final List<Map<String, String>> _employees = [
    {'id': '1', 'name': 'Иван Иванов'},
    {'id': '2', 'name': 'Мария Петрова'},
    {'id': '3', 'name': 'Алексей Сидоров'},
  ];

  final List<String> _roles = [
    'Администратор',
    'Повар',
    'Официант',
    'Бармен',
  ];

  final List<String> _branches = [
    'ТЦ Мега',
    'Центр',
    'Аэропорт',
  ];

  bool get _hasConflict => _selectedEmployeeId == '1'; // Иван Иванов
  bool get _canSave => !_hasConflict || _ignoreWarning;

  double get _duration {
    final start = _startTime.hour + _startTime.minute / 60.0;
    final end = _endTime.hour + _endTime.minute / 60.0;
    return end > start ? end - start : (24 - start) + end;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Заголовок
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Создать смену',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Dropdown: Сотрудник
                  DropdownButtonFormField<String>(
                    value: _selectedEmployeeId,
                    decoration: InputDecoration(
                      labelText: 'Сотрудник',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _employees.map((employee) {
                      return DropdownMenuItem(
                        value: employee['id'],
                        child: Text(employee['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEmployeeId = value;
                        _ignoreWarning = false; // Сброс при смене сотрудника
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Выберите сотрудника';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dropdown: Должность
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Должность',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Выберите должность';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Дата
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Дата',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd.MM.yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Время начала и конца
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Начало',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: const Icon(Icons.access_time),
                            ),
                            child: Text(_startTime.format(context)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Конец',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: const Icon(Icons.access_time),
                            ),
                            child: Text(_endTime.format(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Длительность
                  Text(
                    'Длительность: ${_duration.toStringAsFixed(1)} ч',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown: Филиал
                  DropdownButtonFormField<String>(
                    value: _selectedBranch,
                    decoration: InputDecoration(
                      labelText: 'Филиал',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _branches.map((branch) {
                      return DropdownMenuItem(
                        value: branch,
                        child: Text(branch),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBranch = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Выберите филиал';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Warning Box (если конфликт)
                  if (_hasConflict) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Сотрудник просил выходной',
                                  style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            value: _ignoreWarning,
                            onChanged: (value) {
                              setState(() {
                                _ignoreWarning = value ?? false;
                              });
                            },
                            title: const Text(
                              'Игнорировать предупреждение',
                              style: TextStyle(fontSize: 14),
                            ),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Кнопки
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Отмена'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _canSave ? _handleSave : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Сохранить'),
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

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
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
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Показать SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Смена создана. Уведомление отправлено'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Закрыть диалог с результатом true
    Navigator.of(context).pop(true);
  }
}
```

---

### ЧАСТЬ 2: Интеграция в Schedule Screen

#### Обновление `lib/schedule/views/schedule_view.dart`

Добавить метод для показа диалога:

```dart
// ДОБАВИТЬ ЭТОТ МЕТОД в _ScheduleViewState

Future<void> _showCreateShiftDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => const CreateShiftDialog(),
  );

  if (result == true && mounted) {
    // Обновить график смен через ViewModel
    // _viewModel.refreshShifts();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('График обновлен'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
```

#### Обновить кнопку в AppBar (строка 418-422 в schedule_view.dart):

```dart
actions: [
  IconButton(
    icon: const Icon(Icons.add),
    onPressed: () {
      _showCreateShiftDialog(context); // Изменить эту строку
    },
    tooltip: 'Добавить смену',
  ),
  // ... остальные actions
],
```

#### Не забудьте добавить импорт:

```dart
import 'package:my_app/schedule/widgets/create_shift_dialog.dart';
```

---

## 📝 Checklist для реализации

### Подготовка:
- [ ] Создать папку `lib/schedule/widgets/`
- [ ] Убедиться, что `intl` добавлен в `pubspec.yaml`

### Реализация Dialog:
- [ ] Создать `create_shift_dialog.dart`
- [ ] Добавить форму с 4 dropdown и 3 time pickers
- [ ] Реализовать валидацию полей
- [ ] Добавить вычисление длительности
- [ ] Реализовать Warning Box для конфликтов
- [ ] Добавить чекбокс "Игнорировать"
- [ ] Реализовать логику активации кнопки "Сохранить"
- [ ] Добавить SnackBar при сохранении

### Интеграция:
- [ ] Создать метод `_showCreateShiftDialog()` в Schedule Screen
- [ ] Обновить кнопку в AppBar для вызова диалога
- [ ] Обработать результат диалога (true/false)
- [ ] Показать SnackBar при успешном создании

### Стилизация:
- [ ] Dialog: maxWidth 500px, скругление 16px
- [ ] Поля: скругление 8px
- [ ] Warning Box: оранжевый фон, иконка
- [ ] Кнопка "Сохранить": синяя, disabled серая

---

## 🎯 Ожидаемый результат

### Функциональность:
- ✅ Модальное окно с формой создания смены
- ✅ Валидация всех полей
- ✅ Выбор даты через DatePicker
- ✅ Выбор времени через TimePicker
- ✅ Автоматический расчет длительности
- ✅ Warning Box для конфликтов
- ✅ Чекбокс "Игнорировать"
- ✅ Блокировка кнопки при конфликте
- ✅ SnackBar с подтверждением
- ✅ Интеграция с Schedule Screen (локальный state)

### UI особенности:
- ✅ Адаптивная ширина (maxWidth 500px)
- ✅ Скругленные углы
- ✅ Оранжевый Warning Box
- ✅ Синяя кнопка "Добавить смену"
- ✅ Disabled state для кнопки "Сохранить"

### Mock логика:
- ✅ Hardcoded конфликт для "Иван Иванов" (id=1)
- ✅ 3 сотрудника, 4 должности, 3 филиала
- ✅ Возврат `true` при успешном сохранении

---

**Последнее обновление**: 2025-11-28  
**Статус**: Готов к реализации  
**Время реализации**: 2-3 часа