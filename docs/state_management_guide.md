# Руководство по управлению состоянием (State Management Guide)

В этом проекте мы используем архитектуру MVVM. Для управления состоянием мы придерживаемся следующих подходов в зависимости от сложности экрана.

---

## 📋 Стратегия выбора подхода

| Сложность | Критерии | Подход | Пример экрана |
|-----------|----------|--------|---------------|
| **Простая** | 1-2 независимых состояния | `ValueNotifier` | Login, Employee Detail |
| **Средняя** | Множество зависимых полей | `ChangeNotifier` | Employee List с фильтрами |
| **Высокая** | Сложная логика, много полей | State Object Pattern | Schedule Calendar |

---

## 1. Простые экраны (Simple Screens)

Для экранов с одним или двумя независимыми состояниями (например, счетчик, форма входа) используем `ValueNotifier`.

### Базовый пример:
```dart
class LoginViewModel {
  final isLoading = ValueNotifier<bool>(false);
  final error = ValueNotifier<String?>(null);

  Future<void> login() async {
    isLoading.value = true;
    error.value = null;
    
    try {
      // logic...
      isLoading.value = false;
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false;
    }
  }
  
  void dispose() {
    isLoading.dispose();
    error.dispose();
  }
}
```

### ✅ С интеграцией AsyncValue (Рекомендуется):
```dart
import 'package:my_app/core/utils/async_value.dart';

class LoginViewModel {
  final AuthService _authService;
  final RouterService _routerService;
  
  LoginViewModel({
    required AuthService authService,
    required RouterService routerService,
  }) : _authService = authService,
       _routerService = routerService;

  final loginState = ValueNotifier<AsyncValue<void>>(
    const AsyncData(null)
  );

  Future<void> login(String email, String password) async {
    loginState.value = const AsyncLoading();
    
    try {
      await _authService.login(email, password);
      loginState.value = const AsyncData(null);
      _routerService.go('/dashboard');
    } catch (e) {
      loginState.value = AsyncError(e.toString());
    }
  }
  
  void dispose() {
    loginState.dispose();
  }
}
```

### Использование во View:
```dart
ValueListenableBuilder<AsyncValue<void>>(
  valueListenable: viewModel.loginState,
  builder: (context, asyncValue, _) {
    return asyncValue.when(
      loading: () => const CircularProgressIndicator(),
      data: (_) => ElevatedButton(
        onPressed: () => viewModel.login(email, password),
        child: const Text('Login'),
      ),
      error: (message) => Column(
        children: [
          Text('Error: $message', style: TextStyle(color: Colors.red)),
          ElevatedButton(
            onPressed: () => viewModel.login(email, password),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  },
)
```

---

## 2. Средняя сложность (Medium Complexity)

Для экранов со множеством зависимых полей или списков (например, Список сотрудников с фильтрами) использование множества `ValueNotifier` может привести к рассинхронизации и спагетти-коду.

### Подход: ChangeNotifier
`ChangeNotifier` позволяет уведомлять слушателей об изменении любого из полей.

```dart
class EmployeeListViewModel extends ChangeNotifier {
  final EmployeeRepository _repository;
  
  EmployeeListViewModel({required EmployeeRepository repository})
      : _repository = repository;

  List<Employee> _employees = [];
  bool _isLoading = false;
  String? _searchQuery;
  EmployeeStatus? _statusFilter;
  String? _error;

  // Getters
  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed property - фильтрованный список
  List<Employee> get filteredEmployees {
    var result = _employees;
    
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      result = result.where((e) => 
        e.firstName.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
        e.lastName.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
        e.email.toLowerCase().contains(_searchQuery!.toLowerCase())
      ).toList();
    }
    
    if (_statusFilter != null) {
      result = result.where((e) => e.status == _statusFilter).toList();
    }
    
    return result;
  }

  // Actions
  Future<void> loadEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Уведомляем UI о начале загрузки

    try {
      _employees = await _repository.getEmployees();
      _isLoading = false;
      notifyListeners(); // Уведомляем UI о новых данных
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners(); // filteredEmployees автоматически пересчитается
  }

  void setStatusFilter(EmployeeStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = null;
    _statusFilter = null;
    notifyListeners();
  }
}
```

### Использование во View:
```dart
class EmployeeListView extends StatefulWidget {
  const EmployeeListView({super.key});

  @override
  State<EmployeeListView> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends State<EmployeeListView> {
  late final EmployeeListViewModel _viewModel = EmployeeListViewModel(
    repository: locator<EmployeeRepository>(),
  );

  @override
  void initState() {
    super.initState();
    _viewModel.loadEmployees();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: AnimatedBuilder(
        animation: _viewModel, // ViewModel наследует ChangeNotifier
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.error != null) {
            return Center(
              child: Text('Error: ${_viewModel.error}'),
            );
          }

          return Column(
            children: [
              // Search bar
              TextField(
                onChanged: _viewModel.setSearchQuery,
                decoration: const InputDecoration(
                  hintText: 'Search employees...',
                ),
              ),
              
              // Filter dropdown
              DropdownButton<EmployeeStatus>(
                value: _viewModel._statusFilter,
                onChanged: _viewModel.setStatusFilter,
                items: EmployeeStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.name),
                  );
                }).toList(),
              ),
              
              // Employee list
              Expanded(
                child: ListView.builder(
                  itemCount: _viewModel.filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = _viewModel.filteredEmployees[index];
                    return ListTile(
                      title: Text('${employee.firstName} ${employee.lastName}'),
                      subtitle: Text(employee.email),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

---

## 3. Высокая сложность (High Complexity)

Для экранов со сложной логикой, множеством зависимых полей или списков используем **State Object Pattern** с одним `ValueNotifier`. Это похоже на BLoC/Cubit, но проще.

### Подход: State Object Pattern + AsyncValue

```dart
import 'package:my_app/core/utils/async_value.dart';

// 1. State Class (Иммутабельный)
class ScheduleState {
  final AsyncValue<List<Shift>> shifts;
  final DateTime selectedDate;
  final CalendarView view; // day, week, month
  final String? selectedEmployeeId;
  final AsyncValue<List<Employee>> employees;

  const ScheduleState({
    this.shifts = const AsyncLoading(),
    required this.selectedDate,
    this.view = CalendarView.week,
    this.selectedEmployeeId,
    this.employees = const AsyncLoading(),
  });

  // copyWith для создания новых состояний
  ScheduleState copyWith({
    AsyncValue<List<Shift>>? shifts,
    DateTime? selectedDate,
    CalendarView? view,
    String? selectedEmployeeId,
    AsyncValue<List<Employee>>? employees,
  }) {
    return ScheduleState(
      shifts: shifts ?? this.shifts,
      selectedDate: selectedDate ?? this.selectedDate,
      view: view ?? this.view,
      selectedEmployeeId: selectedEmployeeId ?? this.selectedEmployeeId,
      employees: employees ?? this.employees,
    );
  }

  // Computed properties
  List<Shift> get visibleShifts {
    if (shifts is! AsyncData<List<Shift>>) return [];
    
    final allShifts = (shifts as AsyncData<List<Shift>>).data;
    
    // Фильтр по выбранному сотруднику
    if (selectedEmployeeId != null) {
      return allShifts
          .where((shift) => shift.employeeId == selectedEmployeeId)
          .toList();
    }
    
    return allShifts;
  }
}

// 2. ViewModel
class ScheduleViewModel {
  final ShiftRepository _shiftRepository;
  final EmployeeRepository _employeeRepository;

  ScheduleViewModel({
    required ShiftRepository shiftRepository,
    required EmployeeRepository employeeRepository,
  })  : _shiftRepository = shiftRepository,
        _employeeRepository = employeeRepository;

  final state = ValueNotifier<ScheduleState>(
    ScheduleState(selectedDate: DateTime.now())
  );

  // Actions
  Future<void> loadData() async {
    // Загружаем сотрудников
    state.value = state.value.copyWith(
      employees: const AsyncLoading(),
    );

    try {
      final employees = await _employeeRepository.getEmployees();
      state.value = state.value.copyWith(
        employees: AsyncData(employees),
      );
    } catch (e) {
      state.value = state.value.copyWith(
        employees: AsyncError(e.toString()),
      );
    }

    // Загружаем смены
    await loadShifts();
  }

  Future<void> loadShifts() async {
    state.value = state.value.copyWith(
      shifts: const AsyncLoading(),
    );

    try {
      final shifts = await _shiftRepository.getShifts(
        startDate: _getStartDate(),
        endDate: _getEndDate(),
      );
      
      state.value = state.value.copyWith(
        shifts: AsyncData(shifts),
      );
    } catch (e) {
      state.value = state.value.copyWith(
        shifts: AsyncError(e.toString()),
      );
    }
  }

  void changeView(CalendarView newView) {
    state.value = state.value.copyWith(view: newView);
    loadShifts(); // Перезагружаем смены для нового view
  }

  void selectDate(DateTime date) {
    state.value = state.value.copyWith(selectedDate: date);
    loadShifts();
  }

  void filterByEmployee(String? employeeId) {
    state.value = state.value.copyWith(selectedEmployeeId: employeeId);
  }

  DateTime _getStartDate() {
    // Логика вычисления начальной даты в зависимости от view
    switch (state.value.view) {
      case CalendarView.day:
        return state.value.selectedDate;
      case CalendarView.week:
        return state.value.selectedDate.subtract(
          Duration(days: state.value.selectedDate.weekday - 1)
        );
      case CalendarView.month:
        return DateTime(
          state.value.selectedDate.year,
          state.value.selectedDate.month,
          1,
        );
    }
  }

  DateTime _getEndDate() {
    // Логика вычисления конечной даты
    switch (state.value.view) {
      case CalendarView.day:
        return state.value.selectedDate;
      case CalendarView.week:
        return _getStartDate().add(const Duration(days: 6));
      case CalendarView.month:
        return DateTime(
          state.value.selectedDate.year,
          state.value.selectedDate.month + 1,
          0,
        );
    }
  }

  void dispose() {
    state.dispose();
  }
}

enum CalendarView { day, week, month }
```

### Использование во View:
```dart
class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  late final ScheduleViewModel _viewModel = ScheduleViewModel(
    shiftRepository: locator<ShiftRepository>(),
    employeeRepository: locator<EmployeeRepository>(),
  );

  @override
  void initState() {
    super.initState();
    _viewModel.loadData();
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
        title: const Text('Schedule'),
        actions: [
          // View switcher
          ValueListenableBuilder<ScheduleState>(
            valueListenable: _viewModel.state,
            builder: (context, state, _) {
              return SegmentedButton<CalendarView>(
                segments: const [
                  ButtonSegment(value: CalendarView.day, label: Text('Day')),
                  ButtonSegment(value: CalendarView.week, label: Text('Week')),
                  ButtonSegment(value: CalendarView.month, label: Text('Month')),
                ],
                selected: {state.view},
                onSelectionChanged: (Set<CalendarView> newSelection) {
                  _viewModel.changeView(newSelection.first);
                },
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<ScheduleState>(
        valueListenable: _viewModel.state,
        builder: (context, state, _) {
          // Обработка состояния загрузки смен
          return state.shifts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $message'),
                  ElevatedButton(
                    onPressed: _viewModel.loadShifts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (shifts) {
              // Обработка состояния загрузки сотрудников
              return state.employees.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (message) => Center(child: Text('Error: $message')),
                data: (employees) {
                  return Column(
                    children: [
                      // Employee filter
                      DropdownButton<String>(
                        value: state.selectedEmployeeId,
                        hint: const Text('All Employees'),
                        onChanged: _viewModel.filterByEmployee,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Employees'),
                          ),
                          ...employees.map((employee) {
                            return DropdownMenuItem(
                              value: employee.id,
                              child: Text('${employee.firstName} ${employee.lastName}'),
                            );
                          }),
                        ],
                      ),
                      
                      // Calendar
                      Expanded(
                        child: SfCalendar(
                          view: _mapViewToSyncfusion(state.view),
                          dataSource: ShiftDataSource(
                            state.visibleShifts,
                            employees,
                          ),
                          onTap: (details) {
                            if (details.date != null) {
                              _viewModel.selectDate(details.date!);
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  CalendarView _mapViewToSyncfusion(CalendarView view) {
    switch (view) {
      case CalendarView.day:
        return CalendarView.day;
      case CalendarView.week:
        return CalendarView.week;
      case CalendarView.month:
        return CalendarView.month;
    }
  }
}
```

---

## 📊 Применение к экранам проекта

| Экран | Сложность | Подход | Обоснование |
|-------|-----------|--------|-------------|
| **Login** | Простая | `ValueNotifier<AsyncValue<void>>` | Одно состояние - процесс логина |
| **Dashboard** | Простая | `ValueNotifier` для каждого виджета | Независимые виджеты статистики |
| **Employee List** | Средняя | `ChangeNotifier` | Фильтры, поиск, сортировка зависят друг от друга |
| **Employee Detail** | Простая | `ValueNotifier<AsyncValue<Employee>>` | Загрузка одного сотрудника |
| **Employee Form** | Средняя | `ChangeNotifier` | Множество полей формы с валидацией |
| **Schedule Calendar** | Высокая | State Object Pattern | Дата, view, фильтры, смены, сотрудники |
| **Create Shift Dialog** | Средняя | `ChangeNotifier` | Валидация, проверка конфликтов |

---

## 🎯 Рекомендации

### Для текущего проекта Shift Manager:

1. **Login / Простые формы:** 
   - Используйте `ValueNotifier<AsyncValue<T>>`
   - Простота и читаемость кода

2. **Employee List / Фильтры:** 
   - Используйте `ChangeNotifier`
   - Удобство работы с зависимыми полями
   - Автоматический пересчет computed properties

3. **Schedule Calendar / Сложная логика:** 
   - Используйте State Object Pattern
   - Иммутабельность предотвращает баги
   - Легко тестировать
   - Предсказуемые обновления UI

### Общие правила:

- ✅ **Всегда** оборачивайте асинхронные операции в `AsyncValue<T>`
- ✅ **Всегда** вызывайте `dispose()` в ViewModels
- ✅ **Не** смешивайте подходы в одном ViewModel
- ✅ **Используйте** computed properties вместо дублирования логики
- ✅ **Тестируйте** ViewModels независимо от UI

---

## 📚 Дополнительные ресурсы

- [`AsyncValue` implementation](../lib/core/utils/async_value.dart)
- [Architecture rules](../.cursor/rules/architecture.mdc)
- [Conventions](../.cursor/rules/conventions.mdc)

---

**Последнее обновление**: 2025-11-28