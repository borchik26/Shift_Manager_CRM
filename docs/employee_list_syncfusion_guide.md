# 📋 Employee List - Syncfusion DataGrid Implementation Guide

## 🎯 Задача
Создать альтернативную реализацию экрана "Список сотрудников" с использованием Syncfusion DataGrid для сравнения с PlutoGrid.

---

## 📚 Входные данные

### 1. Документация
- **Syncfusion DataGrid**: https://help.syncfusion.com/flutter/datagrid/overview
- **Best Practices**: Использовать лучшие практики Syncfusion

### 2. Референс UI
- **Файл**: `Baza-sotrudnikov.jpeg`
- **Стиль**: Clean SaaS
- **Особенности**: Минималистичный дизайн, четкая типографика, цветные статусы

### 3. Стек технологий
- **Framework**: Flutter
- **State Management**: ChangeNotifier
- **Table**: `syncfusion_flutter_datagrid` + `syncfusion_flutter_core`
- **Architecture**: MVVM

---

## 🏗️ Архитектура (MVVM)

### 1. Model (`lib/employees/models/employee_syncfusion_model.dart`)

```dart
import 'package:flutter/material.dart';

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

class EmployeeSyncfusionModel {
  final String id;
  final String name;
  final String role;
  final String branch;
  final EmployeeStatus status;
  final int workedHours;
  final String avatarUrl;
  
  const EmployeeSyncfusionModel({
    required this.id,
    required this.name,
    required this.role,
    required this.branch,
    required this.status,
    required this.workedHours,
    required this.avatarUrl,
  });
  
  // Генерация моковых данных
  factory EmployeeSyncfusionModel.mock(int index) {
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
    
    return EmployeeSyncfusionModel(
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
  static List<EmployeeSyncfusionModel> generateMockList() {
    return List.generate(50, (index) => EmployeeSyncfusionModel.mock(index));
  }
}
```

---

### 2. DataSource (`lib/employees/viewmodels/employee_data_source.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:my_app/employees/models/employee_syncfusion_model.dart';

class EmployeeDataSource extends DataGridSource {
  EmployeeDataSource({required List<EmployeeSyncfusionModel> employees}) {
    _employees = employees;
    _buildDataGridRows();
  }

  List<EmployeeSyncfusionModel> _employees = [];
  List<DataGridRow> _dataGridRows = [];

  @override
  List<DataGridRow> get rows => _dataGridRows;

  void _buildDataGridRows() {
    _dataGridRows = _employees.map<DataGridRow>((employee) {
      return DataGridRow(cells: [
        DataGridCell<String>(columnName: 'id', value: employee.id),
        DataGridCell<String>(columnName: 'name', value: employee.name),
        DataGridCell<String>(columnName: 'role', value: employee.role),
        DataGridCell<String>(columnName: 'branch', value: employee.branch),
        DataGridCell<String>(columnName: 'status', value: employee.status.name),
        DataGridCell<int>(columnName: 'hours', value: employee.workedHours),
        DataGridCell<String>(columnName: 'actions', value: 'История'),
        DataGridCell<String>(columnName: 'avatarUrl', value: employee.avatarUrl),
      ]);
    }).toList();
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final String name = row.getCells()[1].value;
    final String role = row.getCells()[2].value;
    final String branch = row.getCells()[3].value;
    final String statusName = row.getCells()[4].value;
    final int hours = row.getCells()[5].value;
    final String avatarUrl = row.getCells()[7].value;
    final String employeeId = row.getCells()[0].value;

    final status = EmployeeStatus.values.firstWhere((e) => e.name == statusName);

    return DataGridRowAdapter(
      cells: [
        // ID (скрытая колонка)
        Container(),
        
        // Name с аватаром
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Row(
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
          ),
        ),
        
        // Role
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            role,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        
        // Branch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            branch,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        
        // Status с цветным бейджем
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: status.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              status.displayName,
              style: TextStyle(
                color: status.color.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        // Hours
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            hours.toString(),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        
        // Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: ElevatedButton(
            onPressed: () {
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
        ),
        
        // Avatar URL (скрытая колонка)
        Container(),
      ],
    );
  }

  void _onHistoryPressed(String employeeId) {
    debugPrint('История для сотрудника: $employeeId');
    // TODO: Навигация на страницу истории
  }

  // Сортировка
  @override
  Future<void> handleSort(String columnName, DataGridSortDirection direction) async {
    if (columnName == 'name') {
      _employees.sort((a, b) {
        final result = a.name.compareTo(b.name);
        return direction == DataGridSortDirection.ascending ? result : -result;
      });
    } else if (columnName == 'role') {
      _employees.sort((a, b) {
        final result = a.role.compareTo(b.role);
        return direction == DataGridSortDirection.ascending ? result : -result;
      });
    } else if (columnName == 'branch') {
      _employees.sort((a, b) {
        final result = a.branch.compareTo(b.branch);
        return direction == DataGridSortDirection.ascending ? result : -result;
      });
    } else if (columnName == 'hours') {
      _employees.sort((a, b) {
        final result = a.workedHours.compareTo(b.workedHours);
        return direction == DataGridSortDirection.ascending ? result : -result;
      });
    }

    _buildDataGridRows();
    notifyListeners();
  }

  // Обновление данных
  void updateDataSource(List<EmployeeSyncfusionModel> employees) {
    _employees = employees;
    _buildDataGridRows();
    notifyListeners();
  }
}
```

---

### 3. ViewModel (`lib/employees/viewmodels/employee_syncfusion_view_model.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:my_app/employees/models/employee_syncfusion_model.dart';
import 'package:my_app/employees/viewmodels/employee_data_source.dart';

class EmployeeSyncfusionViewModel extends ChangeNotifier {
  List<EmployeeSyncfusionModel> _employees = [];
  late EmployeeDataSource _dataSource;
  String _searchQuery = '';

  List<EmployeeSyncfusionModel> get employees => _employees;
  EmployeeDataSource get dataSource => _dataSource;
  String get searchQuery => _searchQuery;

  EmployeeSyncfusionViewModel() {
    _loadEmployees();
  }

  void _loadEmployees() {
    _employees = EmployeeSyncfusionModel.generateMockList();
    _dataSource = EmployeeDataSource(employees: _employees);
    notifyListeners();
  }

  // Поиск по имени
  void searchByName(String query) {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _dataSource.updateDataSource(_employees);
    } else {
      final filtered = _employees.where((employee) {
        return employee.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
      _dataSource.updateDataSource(filtered);
    }
    
    notifyListeners();
  }

  // Фильтр по филиалу
  void filterByBranch(String? branch) {
    if (branch == null || branch.isEmpty) {
      _dataSource.updateDataSource(_employees);
    } else {
      final filtered = _employees.where((employee) {
        return employee.branch == branch;
      }).toList();
      _dataSource.updateDataSource(filtered);
    }
    
    notifyListeners();
  }

  // Фильтр по статусу
  void filterByStatus(EmployeeStatus? status) {
    if (status == null) {
      _dataSource.updateDataSource(_employees);
    } else {
      final filtered = _employees.where((employee) {
        return employee.status == status;
      }).toList();
      _dataSource.updateDataSource(filtered);
    }
    
    notifyListeners();
  }

  // Сброс фильтров
  void clearFilters() {
    _searchQuery = '';
    _dataSource.updateDataSource(_employees);
    notifyListeners();
  }
}
```

---

### 4. View (`lib/employees/views/employee_syncfusion_view.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:my_app/employees/viewmodels/employee_syncfusion_view_model.dart';

class EmployeeSyncfusionView extends StatefulWidget {
  const EmployeeSyncfusionView({super.key});

  @override
  State<EmployeeSyncfusionView> createState() => _EmployeeSyncfusionViewState();
}

class _EmployeeSyncfusionViewState extends State<EmployeeSyncfusionView> {
  late final EmployeeSyncfusionViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final int _rowsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _viewModel = EmployeeSyncfusionViewModel();
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
        title: const Text('База сотрудников (Syncfusion)'),
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
          
          // Таблица SfDataGrid
          Expanded(
            child: AnimatedBuilder(
              animation: _viewModel,
              builder: (context, _) {
                return SfDataGridTheme(
                  data: SfDataGridThemeData(
                    headerColor: Colors.grey.shade50,
                    gridLineColor: Colors.grey.shade200,
                    gridLineStrokeWidth: 1,
                  ),
                  child: SfDataGrid(
                    source: _viewModel.dataSource,
                    columns: _buildColumns(),
                    columnWidthMode: ColumnWidthMode.fill,
                    rowHeight: 60,
                    headerRowHeight: 50,
                    allowSorting: true,
                    gridLinesVisibility: GridLinesVisibility.horizontal,
                    headerGridLinesVisibility: GridLinesVisibility.none,
                  ),
                );
              },
            ),
          ),
          
          // Пагинация
          AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              final pageCount = (_viewModel.dataSource.rows.length / _rowsPerPage).ceil();
              
              return Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: SfDataPager(
                  delegate: _viewModel.dataSource,
                  pageCount: pageCount.toDouble(),
                  direction: Axis.horizontal,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<GridColumn> _buildColumns() {
    return [
      // ID (скрытая колонка)
      GridColumn(
        columnName: 'id',
        label: Container(),
        visible: false,
      ),
      
      // Name
      GridColumn(
        columnName: 'name',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            'Сотрудник',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      
      // Role
      GridColumn(
        columnName: 'role',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            'Должность',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      
      // Branch
      GridColumn(
        columnName: 'branch',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            'Филиал',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      
      // Status
      GridColumn(
        columnName: 'status',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            'Статус',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        allowSorting: false,
      ),
      
      // Hours
      GridColumn(
        columnName: 'hours',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: const Text(
            'Часы',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      
      // Actions
      GridColumn(
        columnName: 'actions',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: const Text(
            'Действия',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        allowSorting: false,
      ),
      
      // Avatar URL (скрытая колонка)
      GridColumn(
        columnName: 'avatarUrl',
        label: Container(),
        visible: false,
      ),
    ];
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
- [ ] Убедиться, что `syncfusion_flutter_datagrid` и `syncfusion_flutter_core` добавлены в `pubspec.yaml`
- [ ] Создать папку `lib/employees_syncfusion/` с подпапками
- [ ] Добавить роут `/dashboard/employees-syncfusion` в `route_config.dart`

### Реализация:
- [ ] Создать `employee_syncfusion_model.dart` с enum и классом
- [ ] Создать `employee_data_source.dart` (наследник `DataGridSource`)
- [ ] Создать `employee_syncfusion_view_model.dart` с `ChangeNotifier`
- [ ] Создать `employee_syncfusion_view.dart` с `SfDataGrid`
- [ ] Настроить колонки с кастомными cell builders
- [ ] Добавить пагинацию через `SfDataPager`
- [ ] Добавить поиск и фильтрацию
- [ ] Реализовать сортировку в `handleSort`

### Стилизация:
- [ ] Настроить `SfDataGridTheme` согласно референсу
- [ ] Добавить цветные бейджи для статусов
- [ ] Настроить аватары с fallback
- [ ] Добавить hover эффекты

---

## 🎯 Ожидаемый результат

### Функциональность:
- ✅ Таблица с 50 сотрудниками
- ✅ Пагинация по 20 строк на страницу
- ✅ Поиск по имени
- ✅ Сортировка по колонкам
- ✅ Цветные статусы
- ✅ Аватары сотрудников
- ✅ Кнопка "История"

### Преимущества Syncfusion:
- ✅ Более плавная анимация
- ✅ Лучшая производительность на больших данных
- ✅ Встроенная пагинация
- ✅ Более гибкая кастомизация

---

## 🔄 Сравнение с PlutoGrid

| Аспект | PlutoGrid | Syncfusion DataGrid |
|--------|-----------|---------------------|
| **Лицензия** | MIT (бесплатно) | Community License (бесплатно <$1M) |
| **Производительность** | Хорошая | Отличная |
| **Кастомизация** | Средняя | Высокая |
| **Документация** | Хорошая | Отличная |
| **Пагинация** | Встроенная | Встроенная (SfDataPager) |
| **Сортировка** | Встроенная | Встроенная + кастомная |
| **Фильтрация** | Встроенная | Требует реализации |
| **Размер bundle** | Меньше | Больше |

---

**Рекомендация**: Реализовать обе версии и выбрать лучшую по критериям:
1. Производительность на 1000+ строк
2. Удобство кастомизации
3. Размер bundle
4. Простота поддержки

**Последнее обновление**: 2025-11-28  
**Статус**: Готов к реализации