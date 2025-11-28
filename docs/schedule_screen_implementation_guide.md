# 📅 Schedule Screen - Syncfusion Calendar Implementation Guide

## 🎯 Задача

Реализовать экран "График смен" (Schedule Screen) в режиме Timeline с использованием Syncfusion Calendar.

---

## 📚 Входные данные

### 1. Референс UI

- **Файл**: `Grafik-smen.jpeg`
- **Стиль**: Resource View (Сотрудники слева, дни сверху)
- **Особенности**: Кастомные карточки смен с цветными бордерами

### 2. Пакет

- **Syncfusion Calendar**: https://pub.dev/packages/syncfusion_flutter_calendar
- **Документация**: https://help.syncfusion.com/flutter/calendar/overview

### 3. Архитектура

- **Pattern**: MVVM
- **State Management**: ChangeNotifier

---

## 🏗️ Архитектура (MVVM)

### 1. Model (`lib/schedule/models/shift_model.dart`)

```dart
import 'package:flutter/material.dart';

class ShiftModel {
  final String id;
  final String employeeId;
  final DateTime startTime;
  final DateTime endTime;
  final String roleTitle;
  final String location;
  final Color color;

  const ShiftModel({
    required this.id,
    required this.employeeId,
    required this.startTime,
    required this.endTime,
    required this.roleTitle,
    required this.location,
    required this.color,
  });

  // Длительность смены в часах
  double get durationInHours {
    return endTime.difference(startTime).inMinutes / 60.0;
  }

  // Форматированное время
  String get timeRange {
    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  // Генерация моковых данных
  factory ShiftModel.mock({
    required int index,
    required String employeeId,
    required DateTime baseDate,
  }) {
    final roles = [
      'Администратор',
      'Повар',
      'Официант',
      'Бармен',
      'Уборщик',
      'Охранник',
    ];

    final locations = ['ТЦ Мега', 'Центр', 'Аэропорт'];

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    // Разные типы смен
    final shiftTypes = [
      {'start': 9, 'duration': 9}, // Дневная смена 09:00-18:00
      {'start': 12, 'duration': 8}, // Дневная смена 12:00-20:00
      {'start': 18, 'duration': 6}, // Вечерняя смена 18:00-00:00
      {'start': 0, 'duration': 8}, // Ночная смена 00:00-08:00
    ];

    final shiftType = shiftTypes[index % shiftTypes.length];
    final startHour = shiftType['start'] as int;
    final duration = shiftType['duration'] as int;

    final startTime = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      startHour,
    );

    final endTime = startTime.add(Duration(hours: duration));

    return ShiftModel(
      id: 'shift_${index.toString().padLeft(3, '0')}',
      employeeId: employeeId,
      startTime: startTime,
      endTime: endTime,
      roleTitle: roles[index % roles.length],
      location: locations[index % locations.length],
      color: colors[index % colors.length],
    );
  }

  // Копирование с изменениями
  ShiftModel copyWith({
    String? id,
    String? employeeId,
    DateTime? startTime,
    DateTime? endTime,
    String? roleTitle,
    String? location,
    Color? color,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roleTitle: roleTitle ?? this.roleTitle,
      location: location ?? this.location,
      color: color ?? this.color,
    );
  }
}
```

---

### 2. DataSource (`lib/schedule/viewmodels/shift_data_source.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:my_app/schedule/models/shift_model.dart';

class ShiftDataSource extends CalendarDataSource {
  ShiftDataSource(List<ShiftModel> shifts, List<CalendarResource> resources) {
    appointments = shifts;
    this.resources = resources;
  }

  @override
  DateTime getStartTime(int index) {
    final shift = appointments![index] as ShiftModel;
    return shift.startTime;
  }

  @override
  DateTime getEndTime(int index) {
    final shift = appointments![index] as ShiftModel;
    return shift.endTime;
  }

  @override
  String getSubject(int index) {
    final shift = appointments![index] as ShiftModel;
    return shift.roleTitle;
  }

  @override
  Color getColor(int index) {
    final shift = appointments![index] as ShiftModel;
    return shift.color;
  }

  @override
  List<Object> getResourceIds(int index) {
    final shift = appointments![index] as ShiftModel;
    return [shift.employeeId];
  }

  @override
  String? getNotes(int index) {
    final shift = appointments![index] as ShiftModel;
    return shift.location;
  }

  @override
  String? getId(int index) {
    final shift = appointments![index] as ShiftModel;
    return shift.id;
  }
}
```

---

### 3. ViewModel (`lib/schedule/viewmodels/schedule_view_model.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/viewmodels/shift_data_source.dart';
import 'package:my_app/data/models/employee_model.dart';

class ScheduleViewModel extends ChangeNotifier {
  List<ShiftModel> _shifts = [];
  List<CalendarResource> _resources = [];
  late ShiftDataSource _dataSource;

  List<ShiftModel> get shifts => _shifts;
  List<CalendarResource> get resources => _resources;
  ShiftDataSource get dataSource => _dataSource;

  ScheduleViewModel() {
    _loadMockData();
  }

  void _loadMockData() {
    // Генерация моковых сотрудников для ресурсов
    final employees = _generateMockEmployees();
  
    // Преобразование в CalendarResource
    _resources = employees.map((employee) {
      return CalendarResource(
        id: employee.id,
        displayName: employee.name,
        color: _getEmployeeColor(employee.id),
        image: NetworkImage(employee.avatarUrl),
      );
    }).toList();

    // Генерация моковых смен
    _shifts = _generateMockShifts(employees);

    // Создание DataSource
    _dataSource = ShiftDataSource(_shifts, _resources);
  
    notifyListeners();
  }

  List<EmployeeModel> _generateMockEmployees() {
    return List.generate(5, (index) {
      final names = [
        'Иван Петров',
        'Мария Сидорова',
        'Алексей Иванов',
        'Елена Смирнова',
        'Дмитрий Козлов',
      ];

      final id = 'emp_${index.toString().padLeft(3, '0')}';

      return EmployeeModel(
        id: id,
        name: names[index],
        role: 'Сотрудник',
        branch: 'ТЦ Мега',
        status: EmployeeStatus.onShift,
        workedHours: 160,
        avatarUrl: 'https://i.pravatar.cc/150?u=$id',
      );
    });
  }

  List<ShiftModel> _generateMockShifts(List<EmployeeModel> employees) {
    final shifts = <ShiftModel>[];
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Генерируем смены на неделю для каждого сотрудника
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = startOfWeek.add(Duration(days: dayOffset));

      for (var empIndex = 0; empIndex < employees.length; empIndex++) {
        final employee = employees[empIndex];
      
        // Не все сотрудники работают каждый день
        if ((dayOffset + empIndex) % 3 == 0) continue;

        final shiftIndex = shifts.length;
        final shift = ShiftModel.mock(
          index: shiftIndex,
          employeeId: employee.id,
          baseDate: date,
        );

        shifts.add(shift);
      }
    }

    return shifts;
  }

  Color _getEmployeeColor(String employeeId) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    final hash = employeeId.hashCode;
    return colors[hash.abs() % colors.length];
  }

  // Добавление смены
  void addShift(ShiftModel shift) {
    _shifts.add(shift);
    _dataSource = ShiftDataSource(_shifts, _resources);
    notifyListeners();
  }

  // Удаление смены
  void deleteShift(String shiftId) {
    _shifts.removeWhere((shift) => shift.id == shiftId);
    _dataSource = ShiftDataSource(_shifts, _resources);
    notifyListeners();
  }

  // Обновление смены
  void updateShift(ShiftModel updatedShift) {
    final index = _shifts.indexWhere((shift) => shift.id == updatedShift.id);
    if (index != -1) {
      _shifts[index] = updatedShift;
      _dataSource = ShiftDataSource(_shifts, _resources);
      notifyListeners();
    }
  }

  // Получение смен для конкретного сотрудника
  List<ShiftModel> getShiftsForEmployee(String employeeId) {
    return _shifts.where((shift) => shift.employeeId == employeeId).toList();
  }

  // Проверка конфликтов смен
  bool hasConflict(ShiftModel newShift) {
    return _shifts.any((shift) {
      if (shift.employeeId != newShift.employeeId) return false;
      if (shift.id == newShift.id) return false;

      return (newShift.startTime.isBefore(shift.endTime) &&
          newShift.endTime.isAfter(shift.startTime));
    });
  }

  @override
  void dispose() {
    // Очистка ресурсов
    super.dispose();
  }
}
```

---

### 4. View (`lib/schedule/views/schedule_view.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:my_app/schedule/viewmodels/schedule_view_model.dart';
import 'package:my_app/schedule/models/shift_model.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  late final ScheduleViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ScheduleViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('График смен'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddShiftDialog(context);
            },
            tooltip: 'Добавить смену',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Фильтрация
            },
            tooltip: 'Фильтры',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, child) {
          return SfCalendar(
              view: CalendarView.timelineWeek,
              dataSource: viewModel.dataSource,
            
              // Настройки временных слотов
              timeSlotViewSettings: const TimeSlotViewSettings(
                timelineAppointmentHeight: 60,
                timeInterval: Duration(hours: 4),
                dateFormat: 'd',
                dayFormat: 'EEE',
                timeFormat: 'HH:mm',
                startHour: 0,
                endHour: 24,
              ),
            
              // Настройки ресурсов (сотрудники)
              resourceViewSettings: const ResourceViewSettings(
                visibleResourceCount: 5,
                showAvatar: true,
                size: 150,
                displayNameTextStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            
              // Заголовок даты
              headerStyle: const CalendarHeaderStyle(
                textAlign: TextAlign.center,
                backgroundColor: Colors.white,
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            
              // Стиль view header (дни недели)
              viewHeaderStyle: ViewHeaderStyle(
                backgroundColor: Colors.grey.shade50,
                dayTextStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                dateTextStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            
              // Кастомный рендер смены
              appointmentBuilder: (context, details) {
                final shift = details.appointments.first as ShiftModel;
                return _buildShiftCard(shift);
              },
            
              // Обработка тапа по смене
              onTap: (details) {
                if (details.appointments != null && details.appointments!.isNotEmpty) {
                  final shift = details.appointments!.first as ShiftModel;
                  _showShiftDetails(context, shift);
                }
              },
            
              // Первый день недели
              firstDayOfWeek: 1, // Понедельник
            
              // Показывать текущую линию времени
              showCurrentTimeIndicator: true,
            
              // Цвет линии текущего времени
            todayHighlightColor: Colors.blue,
          );
        },
      ),
    );
  }

  Widget _buildShiftCard(ShiftModel shift) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: shift.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: shift.color,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Время
            Text(
              shift.timeRange,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: shift.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Роль
            Text(
              shift.roleTitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Локация
            Text(
              shift.location,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showShiftDetails(BuildContext context, ShiftModel shift) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(shift.roleTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Время', shift.timeRange),
            _buildDetailRow('Локация', shift.location),
            _buildDetailRow('Длительность', '${shift.durationInHours.toStringAsFixed(1)} ч'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _viewModel.deleteShift(shift.id);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _showAddShiftDialog(BuildContext context) {
    // TODO: Реализовать диалог добавления смены
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция добавления смены в разработке')),
    );
  }
}
```

---

## 📝 Checklist для реализации

### Подготовка:

- [ ] Убедиться, что `syncfusion_flutter_calendar` добавлен в `pubspec.yaml`
- [ ] Создать папку `lib/schedule/` с подпапками (models, viewmodels, views)
- [ ] Добавить роут `/dashboard/schedule` в `route_config.dart`

### Реализация:

- [ ] Создать `shift_model.dart` с полями и методами
- [ ] Создать `shift_data_source.dart` (наследник `CalendarDataSource`)
- [ ] Создать `schedule_view_model.dart` с `ChangeNotifier`
- [ ] Создать `schedule_view.dart` с `SfCalendar`
- [ ] Настроить `timeSlotViewSettings` и `resourceViewSettings`
- [ ] Реализовать `appointmentBuilder` для кастомных карточек
- [ ] Добавить обработку тапов по сменам
- [ ] Реализовать методы добавления/удаления смен

### Тестирование:

- [ ] Проверить отображение 10 моковых смен
- [ ] Проверить Resource View (5 сотрудников слева)
- [ ] Проверить кастомные карточки с цветными бордерами
- [ ] Проверить тап по смене (открытие деталей)
- [ ] Проверить удаление смены

---

## 🎯 Ожидаемый результат

### Функциональность:

- ✅ Timeline View с неделей
- ✅ Resource View (сотрудники слева с аватарами)
- ✅ Кастомные карточки смен
- ✅ Цветные бордеры по статусу
- ✅ Детали смены по тапу
- ✅ Добавление/удаление смен

### UI особенности:

- ✅ Временные слоты по 4 часа
- ✅ Высота смены 60px
- ✅ Аватары сотрудников
- ✅ Закругленные углы карточек
- ✅ Линия текущего времени

---

**Последнее обновление**: 2025-11-28
**Статус**: Готов к реализации
**Время реализации**: 4-6 часов
