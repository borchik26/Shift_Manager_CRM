# Исправление ошибки "A disposed RenderObject was mutated" в Syncfusion Charts

**Дата:** 2025-12-02  
**Проблема:** При переходе между экранами (Сотрудники, График смен) возникала ошибка `DartError: A disposed RenderObject was mutated` в Syncfusion Charts.

## 🐛 Описание проблемы

### Симптомы
```
DartError: A disposed RenderObject was mutated.
The disposed RenderObject was:
  RenderChartFadeTransition#8009b DISPOSED
```

Ошибка возникала при:
1. Переходе с главного экрана (Dashboard) на экран Сотрудников
2. Переходе с главного экрана на экран График смен
3. Любой навигации, которая уничтожала виджеты с Syncfusion Charts

### Причина (Root Cause Analysis)

**Проблема 1: Дублирование ViewModels**
- **DashboardView** создавал `DashboardViewModel`
- **HomeView** тоже создавал `DashboardViewModel`
- Оба существовали одновременно и слушали одни и те же данные

**Проблема 2: Конфликт dispose()**
Когда пользователь переходил с HomeView на другой экран:
1. HomeView удалялся → вызывался `_viewModel.dispose()`
2. DashboardViewModel очищал свои ValueNotifiers
3. НО! DashboardView продолжал существовать (он wrapper)
4. DashboardView пытался использовать disposed ValueNotifiers
5. Syncfusion Charts получал обновления от disposed объектов
6. **КРАХ:** `A disposed RenderObject was mutated`

**Проблема 3: Архитектурная ошибка**
`DashboardView` смешивал две ответственности:
- Navigation (правильно)
- Data Loading (НЕПРАВИЛЬНО - должно быть в HomeView)

Это приводило к:
- Утечке памяти (два ViewModel на одни данные)
- Попыткам обновления уже удаленных RenderObject-ов
- Краху приложения при навигации

## ✅ Решение (3-уровневая защита)

### 1. Переделан DashboardView в StatelessWidget (КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ)

**Файл:** `lib/dashboard/views/dashboard_view.dart`

**Проблема:** DashboardView создавал свой DashboardViewModel, хотя HomeView тоже создавал свой. Это приводило к конфликтам и dispose ошибкам.

**До:**
```dart
class DashboardView extends StatefulWidget { ... }

class _DashboardViewState extends State<DashboardView> {
  late final DashboardViewModel _viewModel;  // ❌ Ненужный ViewModel

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(...);  // ❌ Дублирует HomeView
  }

  @override
  void dispose() {
    _viewModel.dispose();  // ❌ Конфликтует с HomeView dispose
    super.dispose();
  }
}
```

**После:**
```dart
class DashboardView extends StatelessWidget {  // ✅ StatelessWidget
  final Widget child;
  final String currentPath;

  const DashboardView({
    super.key,
    required this.child,
    required this.currentPath,
  });

  int _getSelectedIndex(String currentPath) { ... }
  void _navigateTo(String path) { ... }
  Future<void> _logout() async { ... }

  @override
  Widget build(BuildContext context) {
    // Простая навигация, без ViewModel
  }
}
```

**Что это исправляет:**
- DashboardView теперь только shell/wrapper для навигации
- Нет конфликтов dispose между DashboardView и HomeView
- HomeView единственный владелец DashboardViewModel
- Правильное разделение ответственностей

### 2. Отложенный dispose ValueNotifiers (Timing Fix)

**Файл:** `lib/dashboard/viewmodels/dashboard_view_model.dart`

**Проблема:** Syncfusion Charts может пытаться обновиться в момент dispose.

**Решение:**
```dart
import 'package:flutter/scheduler.dart';

void dispose() {
  // Отложить dispose до следующего frame, чтобы дать Syncfusion Charts
  // время полностью unmount. Это предотвращает "A disposed RenderObject was mutated" ошибку.
  // КРИТИЧНО: используем addPostFrameCallback вместо Future.microtask,
  // так как Syncfusion Charts делает layout operations во время unmount.
  SchedulerBinding.instance.addPostFrameCallback((_) {
    statsState.dispose();
    weeklyShiftsState.dispose();
    birthdaysState.dispose();
    alertsState.dispose();
  });
}
```

**Почему именно `addPostFrameCallback`?**
- `Future.microtask()` - выполняется слишком рано, до завершения frame
- `Future.delayed()` - ненадежно, зависит от времени
- `addPostFrameCallback()` - ✅ ПРАВИЛЬНО: выполняется гарантированно после завершения frame

**Что это исправляет:**
- Даёт Flutter время завершить текущий frame и все layout operations
- Syncfusion Charts успевает полностью unmount до dispose ValueNotifiers
- Предотвращает race condition между unmount и dispose
- Гарантирует, что RenderObject уже disposed до обновления ValueNotifier

### 3. Уникальные ключи и изоляция (Widget Identity Fix)

**Файлы:** `lib/config/route_config.dart`, `lib/dashboard/views/home_view.dart`

**А. Уникальные ключи для правильного unmount:**
```dart
DashboardView(
  key: const ValueKey('/dashboard'),  // ✅ Уникальный ключ
  currentPath: '/dashboard',
  child: const HomeView(key: ValueKey('home_view')),  // ✅ Уникальный ключ
),
```

**Б. RepaintBoundary для изоляции Syncfusion Charts:**
```dart
data: (_) => RepaintBoundary(  // ✅ Изолирует от родителя
  child: LoadingHoursChart(
    weeklyHours: _viewModel.weeklyHoursData,
  ),
),
```

**Что это исправляет:**
- Flutter правильно идентифицирует виджеты при навигации
- RepaintBoundary изолирует RenderObject Syncfusion Charts
- Предотвращает попытки обновления disposed объектов

### 2. Упрощен LoadingHoursChart

**Файл:** `lib/dashboard/widgets/loading_hours_chart.dart`

**До:**
```dart
class LoadingHoursChart extends StatefulWidget {
  // ... сложная логика с проверками _isDisposed, _shouldRender, mounted
  // ... множественные Builder обертки
  // ... попытки предотвратить dispose errors через флаги
}
```

**После:**
```dart
class LoadingHoursChart extends StatelessWidget {
  // ... простой build method без проверок
  // ... нет состояния, нет dispose проблем
}
```

**Преимущества:**
- Проще код
- Нет состояния = нет проблем с dispose
- Виджет пересоздается при каждом изменении данных (правильный подход)

### 3. Упрощен HomeView

**Файл:** `lib/dashboard/views/home_view.dart`

**Удалены:**
- Избыточные проверки `if (!mounted)`
- Бесполезные `Offstage` обертки с `offstage: false`
- Лишние `Builder` виджеты

**До:**
```dart
if (!mounted) {
  return const SizedBox.shrink();
}
return asyncShifts.when(
  data: (_) {
    if (!mounted) {
      return const SizedBox.shrink();
    }
    return Offstage(
      offstage: false,  // ❌ Бесполезно
      child: LoadingHoursChart(...),
    );
  },
  // ...
);
```

**После:**
```dart
return asyncShifts.when(
  data: (_) => LoadingHoursChart(
    weeklyHours: _viewModel.weeklyHoursData,
  ),
  // ...
);
```

## 📚 Уроки

### Правило 1: Всегда вызывайте dispose() на ViewModels
```dart
class _MyViewState extends State<MyView> {
  late final MyViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MyViewModel(...);
  }

  @override
  void dispose() {
    _viewModel.dispose();  // ✅ ОБЯЗАТЕЛЬНО!
    super.dispose();
  }
}
```

### Правило 2: Предпочитайте StatelessWidget для простых виджетов
- Если виджет не имеет состояния → `StatelessWidget`
- Нет dispose → нет проблем
- Проще тестировать

### Правило 3: Не используйте "защитные" проверки как костыли
❌ **Плохо:**
```dart
if (!mounted) return const SizedBox.shrink();
if (_isDisposed) return const SizedBox.shrink();
```

✅ **Хорошо:**
```dart
// Правильно очищайте ресурсы в dispose()
@override
void dispose() {
  _viewModel.dispose();
  super.dispose();
}
```

### Правило 4: DashboardView - это shell, не бизнес-логика (КРИТИЧЕСКИ ВАЖНО!)
`DashboardView` должен только:
- Показывать navigation (Rail/Drawer/BottomNav)
- Роутить между экранами через RouterService
- НЕ создавать ViewModels
- НЕ загружать данные
- НЕ иметь сложную бизнес-логику
- Быть StatelessWidget

Бизнес-логика должна быть в child-экранах (`HomeView`, `EmployeeSyncfusionView`, etc.)

**АНТИ-ПАТТЕРН:**
```dart
// ❌ ПЛОХО: DashboardView создает ViewModel
class DashboardView extends StatefulWidget {
  Widget child;
}

class _DashboardViewState extends State<DashboardView> {
  late final SomeViewModel _viewModel;  // ❌ НЕТ!
  
  @override
  void initState() {
    _viewModel = SomeViewModel();  // ❌ НЕТ!
  }
}
```

**ПРАВИЛЬНО:**
```dart
// ✅ ХОРОШО: DashboardView - простой wrapper
class DashboardView extends StatelessWidget {
  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row([
        NavigationRail(...),  // Просто UI
        Expanded(child: child),  // Child содержит ViewModels
      ]),
    );
  }
}
```

## ✅ Результат

После исправлений:
- ✅ Нет ошибок "A disposed RenderObject was mutated"
- ✅ Плавная навигация между экранами
- ✅ Нет утечек памяти
- ✅ Чистый, понятный код

## 🔍 Как проверить

1. Запустить приложение
2. Войти в систему (`admin@example.com` / `password123`)
3. Перейти на "Сотрудники"
4. Вернуться на "Главная"
5. Перейти на "График"
6. Вернуться на "Главная"

**Ожидаемый результат:** Нет ошибок в консоли, плавные переходы.

## 📝 Связанные файлы

- `lib/dashboard/views/dashboard_view.dart` ✅ **КРИТИЧЕСКИ ИСПРАВЛЕН** (StatefulWidget → StatelessWidget, удален ViewModel)
- `lib/dashboard/views/home_view.dart` ✅ Упрощен (удалены защитные проверки)
- `lib/dashboard/widgets/loading_hours_chart.dart` ✅ Упрощен (StatefulWidget → StatelessWidget)
- `lib/employees_syncfusion/views/employee_syncfusion_view.dart` ✅ Уже был правильный
- `lib/schedule/views/schedule_view.dart` ✅ Уже был правильный

## 🎯 Checklist для будущих ViewModels

При создании нового ViewModel:
- [ ] ViewModel имеет метод `dispose()`
- [ ] Все `ValueNotifier` очищаются в `dispose()`
- [ ] Все `StreamSubscription` отменяются в `dispose()`
- [ ] View вызывает `_viewModel.dispose()` в своем `dispose()`
- [ ] Нет "защитных" проверок вместо правильной очистки

---

**Статус:** ✅ ИСПРАВЛЕНО  
**Тестирование:** Ручное (переходы между экранами)  
**Автор:** AI Assistant

