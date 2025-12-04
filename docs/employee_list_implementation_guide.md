# 📋 Employee List Implementation Guide

## 🎯 Задача
Создать экран "Список сотрудников" (Employee Directory) с полной реализацией таблицы PlutoGrid.

---

## 📚 Входные данные

### 1. Документация
- **PlutoGrid**: https://pluto.weblaze.dev/series/pluto-grid
- **Best Practices**: Использовать лучшие практики из официальной документации

### 2. Референс UI
- **Файл**: `Baza-sotrudnikov.jpeg`
- **Стиль**: Clean SaaS
- **Особенности**: Минималистичный дизайн, четкая типографика, цветные статусы

### 3. Стек технологий
- **Framework**: Flutter
- **State Management**: ChangeNotifier (для этого экрана)
- **Table**: PlutoGrid
- **Architecture**: MVVM

---

## 🏗️ Архитектура (MVVM)

### 1. Model (`lib/employees/models/employee_list_model.dart`)

```dart
enum EmployeeStatus {
  onShift,
  dayOff,
  vacation;
  
  String get displayName {
    switch (this) {
      case EmployeeStatus.onShift:
        return 'На смене';
      case EmployeeStatus.dayOff:
        return 'Выходной';
      case EmployeeStatus.vacation:
        return 'Отпуск';
    }
  }
  
  Color get color {
    switch (this) {
      case EmployeeStatus.onShift:
        return Colors.green;
      case EmployeeStatus.dayOff:
        return Colors.grey;
      case EmployeeStatus.vacation:
        return Colors.orange;
    }
  }
}

class EmployeeListModel {
  final String id;
  final String name;
  final String role;
  final String branch;
  final EmployeeStatus status;
  final int workedHours;
  final String avatarUrl;
  
  const EmployeeListModel({
    required this.id,
    required this.name,
    required this.role,
    required this.branch,
    required this.status,
    required this.workedHours,
    required this.avatarUrl,
  });
  
  // Генерация моковых данных
  factory EmployeeListModel.mock(int index) {
    final names = [
      'Иван Петров', 'Мария Сидорова', 'Алексей Иванов', 'Елена Смирнова',
      'Дмитрий Козлов', 'Анна Новикова', 'Сергей Морозов', 'Ольга Волкова',
      'Андрей Соколов', 'Татьяна Лебедева', 'Николай Егоров', 'Екатерина Павлова',
      'Владимир Семенов', 'Наталья Федорова', 'Михаил Голубев', 'Светлана Виноградова',
    ];
    
    final roles = [
      'Менеджер', 'Кассир', 'Администратор', 'Продавец-консультант',
      'Старший продавец', 'Охранник', 'Уборщик', 'Товаровед',
    ];
    
    final branches = ['ТЦ Мега', 'Центр', 'Аэропорт'];
    
    final statuses = EmployeeStatus.values;
    
    final id = 'emp_${index.toString().padLeft(3, '0')}';
    
    return EmployeeListModel(
      id: id,
      name: names[index % names.length],
      role: roles[index % roles.length],
      branch: branches[index % branches.length],
      status: statuses[index % statuses.length],
      workedHours: 120 + (index * 7) % 80,
      avatarUrl: 'https://i.pravatar.cc/150?u=$id',
    );
  }
  
  // Генерация списка из 50 сотрудников
  static List<EmployeeListModel> generateMockList() {
    return List.generate(50, (index) => EmployeeListModel.mock(index));
  }
}
```

---

### 2. ViewModel (`lib/employees/viewmodels/employee_list_view_model.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:my_app/employees/models/employee_list_model.dart';

class EmployeeListViewModel extends ChangeNotifier {
  List<EmployeeListModel> _employees = [];
  PlutoGridStateManager? _stateManager;
  
  List<EmployeeListModel> get employees => _employees;
  PlutoGridStateManager? get stateManager => _stateManager;
  
  EmployeeListViewModel() {
    _loadEmployees();
  }
  
  void _loadEmployees() {
    _employees = EmployeeListModel.generateMockList();
    notifyListeners();
  }
  
  void setStateManager(PlutoGridStateManager manager) {
    _stateManager = manager;
  }
  
  // Преобразование модели Employee в PlutoRow
  List<PlutoRow> getPlutoRows() {
    return _employees.map((employee) {
      return PlutoRow(
        cells: {
          'name_field': PlutoCell(value: employee.name),
          'role_field': PlutoCell(value: employee.role),
          'branch_field': PlutoCell(value: employee.branch),
          'status_field': PlutoCell(value: employee.status.name),
          'hours_field': PlutoCell(value: employee.workedHours),
          'actions_field': PlutoCell(value: 'История'),
          'avatar_url_field': PlutoCell(value: employee.avatarUrl), // Скрытая ячейка
          'id_field': PlutoCell(value: employee.id), // Скрытая ячейка для ID
        },
      );
    }).toList();
  }
  
  // Колонки для PlutoGrid
  List<PlutoColumn> getPlutoColumns() {
    return [
      // 1. Сотрудник (Name) с аватаром
      PlutoColumn(
        title: 'Сотрудник',
        field: 'name_field',
        type: PlutoColumnType.text(),
        width: 250,
        renderer: (rendererContext) {
          final avatarUrl = rendererContext.row.cells['avatar_url_field']!.value as String;
          final name = rendererContext.cell.value as String;
          
          return Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatarUrl),
                onBackgroundImageError: (_, __) {},
                child: const Icon(Icons.person, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
      
      // 2. Должность (Role)
      PlutoColumn(
        title: 'Должность',
        field: 'role_field',
        type: PlutoColumnType.text(),
        width: 180,
      ),
      
      // 3. Филиал (Branch) с фильтрацией
      PlutoColumn(
        title: 'Филиал',
        field: 'branch_field',
        type: PlutoColumnType.select(['ТЦ Мега', 'Центр', 'Аэропорт']),
        width: 150,
      ),
      
      // 4. Статус (Status) с цветными бейджами
      PlutoColumn(
        title: 'Статус',
        field: 'status_field',
        type: PlutoColumnType.select(['onShift', 'dayOff', 'vacation']),
        width: 150,
        renderer: (rendererContext) {
          final statusName = rendererContext.cell.value as String;
          final status = EmployeeStatus.values.firstWhere(
            (e) => e.name == statusName,
          );
          
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: status.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                status.displayName,
                style: TextStyle(
                  color: status.color.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
      
      // 5. Часы (Hours)
      PlutoColumn(
        title: 'Часы',
        field: 'hours_field',
        type: PlutoColumnType.number(),
        width: 100,
        textAlign: PlutoColumnTextAlign.center,
      ),
      
      // 6. Действия (Actions)
      PlutoColumn(
        title: 'Действия',
        field: 'actions_field',
        type: PlutoColumnType.text(),
        width: 120,
        enableSorting: false,
        enableColumnDrag: false,
        enableContextMenu: false,
        enableDropToResize: false,
        renderer: (rendererContext) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                final employeeId = rendererContext.row.cells['id_field']!.value;
                _onHistoryPressed(employeeId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'История',
                style: TextStyle(fontSize: 12),
              ),
            ),
          );
        },
      ),
      
      // Скрытые колонки для данных
      PlutoColumn(
        title: 'Avatar URL',
        field: 'avatar_url_field',
        type: PlutoColumnType.text(),
        hide: true,
      ),
      PlutoColumn(
        title: 'ID',
        field: 'id_field',
        type: PlutoColumnType.text(),
        hide: true,
      ),
    ];
  }
  
  void _onHistoryPressed(String employeeId) {
    // TODO: Навигация на страницу истории сотрудника
    debugPrint('История для сотрудника: $employeeId');
  }
  
  // Поиск по имени
  void searchByName(String query) {
    if (_stateManager == null) return;
    
    _stateManager!.setShowColumnFilter(true);
    _stateManager!.setFilterWithFilterRows([
      FilterHelper.createFilterRow(
        columnField: 'name_field',
        filterType: PlutoFilterType.contains,
        filterValue: query,
      ),
    ]);
  }
  
  // Сброс фильтров
  void clearFilters() {
    if (_stateManager == null) return;
    _stateManager!.setShowColumnFilter(false);
  }
}
```

---

### 3. View (`lib/employees/views/employee_list_view.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:my_app/employees/viewmodels/employee_list_view_model.dart';

class EmployeeListView extends StatefulWidget {
  const EmployeeListView({super.key});

  @override
  State<EmployeeListView> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends State<EmployeeListView> {
  late final EmployeeListViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = EmployeeListViewModel();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('База сотрудников'),
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
      ),
      body: Column(
        children: [
          // Панель поиска и фильтров
          _buildSearchBar(),
          
          // Таблица PlutoGrid
          Expanded(
            child: AnimatedBuilder(
              animation: _viewModel,
              builder: (context, _) {
                return PlutoGrid(
                  columns: _viewModel.getPlutoColumns(),
                  rows: _viewModel.getPlutoRows(),
                  onLoaded: (PlutoGridOnLoadedEvent event) {
                    _viewModel.setStateManager(event.stateManager);
                    
                    // Настройка пагинации
                    event.stateManager.setPageSize(20, notify: false);
                  },
                  onChanged: (PlutoGridOnChangedEvent event) {
                    debugPrint('Cell changed: ${event.value}');
                  },
                  configuration: PlutoGridConfiguration(
                    style: PlutoGridStyleConfig(
                      gridBackgroundColor: Colors.white,
                      rowHeight: 60,
                      columnHeight: 50,
                      borderColor: Colors.transparent,
                      gridBorderColor: Colors.transparent,
                      activatedBorderColor: Colors.blue,
                      activatedColor: Colors.blue.withOpacity(0.05),
                      cellTextStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      columnTextStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      gridBorderRadius: BorderRadius.circular(8),
                      enableColumnBorderVertical: false,
                      enableColumnBorderHorizontal: false,
                      enableCellBorderVertical: false,
                      enableCellBorderHorizontal: true,
                      borderColor: Colors.grey.shade200,
                      oddRowColor: Colors.grey.shade50,
                      evenRowColor: Colors.white,
                    ),
                    columnSize: const PlutoGridColumnSizeConfig(
                      autoSizeMode: PlutoAutoSizeMode.none,
                      resizeMode: PlutoResizeMode.normal,
                    ),
                  ),
                  createFooter: (stateManager) {
                    return PlutoPagination(stateManager);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Поле поиска
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по имени...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _viewModel.clearFilters();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                _viewModel.searchByName(value);
                setState(() {});
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Кнопка "Добавить сотрудника"
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Навигация на форму создания сотрудника
              debugPrint('Добавить сотрудника');
            },
            icon: const Icon(Icons.add),
            label: const Text('Добавить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 📝 Checklist для реализации

### Подготовка:
- [ ] Убедиться, что `pluto_grid` добавлен в `pubspec.yaml`
- [ ] Создать папку `lib/employees/` с подпапками `models/`, `viewmodels/`, `views/`
- [ ] Добавить роут `/dashboard/employees` в `route_config.dart`

### Реализация:
- [ ] Создать `employee_list_model.dart` с enum `EmployeeStatus` и классом `EmployeeListModel`
- [ ] Создать `employee_list_view_model.dart` с `ChangeNotifier`
- [ ] Создать `employee_list_view.dart` с `PlutoGrid`
- [ ] Настроить колонки с кастомными рендерерами
- [ ] Добавить пагинацию через `createFooter`
- [ ] Добавить поиск по имени
- [ ] Протестировать на 50 сотрудниках

### Стилизация:
- [ ] Настроить `PlutoGridStyleConfig` согласно референсу
- [ ] Добавить цветные бейджи для статусов
- [ ] Настроить аватары с fallback
- [ ] Добавить hover эффекты для кнопок

---

## 🎯 Ожидаемый результат

### Функциональность:
- ✅ Таблица с 50 сотрудниками
- ✅ Пагинация по 20 строк на страницу
- ✅ Поиск по имени
- ✅ Фильтрация по филиалу и статусу
- ✅ Сортировка по всем колонкам (кроме Actions)
- ✅ Цветные статусы
- ✅ Аватары сотрудников
- ✅ Кнопка "История" для каждого сотрудника

### UI/UX:
- ✅ Clean SaaS стиль
- ✅ Адаптивная высота строк (60px)
- ✅ Четкая типографика
- ✅ Минималистичный дизайн
- ✅ Hover эффекты

---

**Последнее обновление**: 2025-11-28  
**Статус**: Готов к реализации