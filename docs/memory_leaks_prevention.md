# 🛡️ Memory Leaks Prevention Guide

## 📋 Обязательные правила для предотвращения утечек памяти

### 🎯 Основной принцип:
**Каждый созданный `ValueNotifier`, `StreamSubscription`, `ChangeNotifier` должен быть disposed!**

---

## 1. ✅ ViewModel Dispose Pattern

### Правильный шаблон:
```dart
class ExampleViewModel {
  final ValueNotifier<String> data = ValueNotifier('');
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final StreamSubscription _subscription;
  
  ExampleViewModel({required SomeService service})
      : _subscription = service.dataStream.listen((data) {
          // Обработка данных
        });

  // ОБЯЗАТЕЛЬНЫЙ МЕТОД
  void dispose() {
    data.dispose();        // ✅ Dispose ValueNotifier
    isLoading.dispose();   // ✅ Dispose ValueNotifier
    _subscription.cancel(); // ✅ Cancel StreamSubscription
  }
}
```

### ❌ Распростленные ошибки:
```dart
class BadViewModel {
  final ValueNotifier<String> data = ValueNotifier('');
  
  // ❌ НЕТ dispose() метода
  // ❌ ValueNotifier не будет disposed = MEMORY LEAK
}
```

---

## 2. ✅ View Dispose Pattern

### Правильный шаблон:
```dart
class ExampleView extends StatefulWidget {
  const ExampleView({super.key});

  @override
  State<ExampleView> createState() => _ExampleViewState();
}

class _ExampleViewState extends State<ExampleView> {
  late final ExampleViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExampleViewModel(service: locator<SomeService>());
  }

  @override
  void dispose() {
    _viewModel.dispose(); // ✅ ОБЯЗАТЕЛЬНО вызвать dispose
    super.dispose();       // ✅ Вызвать super.dispose()
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _viewModel.data,
      builder: (context, value, child) {
        return Text(value);
      },
    );
  }
}
```

### ❌ Распростленные ошибки:
```dart
class BadView extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    // ❌ ViewModel создается в build() = новый объект каждый rebuild
    final viewModel = ExampleViewModel(service: locator<SomeService>());
    
    return ValueListenableBuilder(
      valueListenable: viewModel.data,
      builder: (context, value, child) => Text(value),
    );
  }
  
  // ❌ dispose() не вызывается для ViewModel
}
```

---

## 3. ✅ StreamSubscription Handling

### Правильный шаблон:
```dart
class StreamViewModel {
  final List<StreamSubscription> _subscriptions = [];
  
  StreamViewModel({required StreamService service}) {
    // Подписываемся на несколько стримов
    _subscriptions.add(
      service.dataStream.listen(_handleData)
    );
    _subscriptions.add(
      service.errorStream.listen(_handleError)
    );
  }
  
  void dispose() {
    // ✅ Отменяем ВСЕ подписки
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
```

---

## 4. ✅ ChangeNotifier Pattern

### Правильный шаблон:
```dart
class ComplexViewModel extends ChangeNotifier {
  List<String> _items = [];
  
  // ✅ ChangeNotifier не требует dispose() для себя,
  // но должен dispose() свои ValueNotifier
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  
  void loadItems() async {
    isLoading.value = true;
    notifyListeners();
    
    try {
      _items = await _repository.getItems();
      isLoading.value = false;
      notifyListeners();
    } catch (e) {
      isLoading.value = false;
      notifyListeners();
    }
  }
  
  void dispose() {
    isLoading.dispose(); // ✅ Dispose вложенных ValueNotifier
    super.dispose();     // ✅ Вызвать super.dispose()
  }
}
```

---

## 5. ✅ Проверка перед коммитом

### Чек-лист для каждого ViewModel:
```dart
class ViewModelChecklist {
  // ✅ 1. Есть ли dispose() метод?
  // ✅ 2. Вызываются ли dispose() у всех ValueNotifier?
  // ✅ 3. Отменяются ли все StreamSubscription?
  // ✅ 4. Вызывается ли dispose() во View?
  // ✅ 5. Нет ли прямых подписок в View?
}
```

### Автоматическая проверка (опционально):
```dart
class BaseViewModel {
  final List<VoidCallback> _disposeCallbacks = [];
  
  void addDisposeCallback(VoidCallback callback) {
    _disposeCallbacks.add(callback);
  }
  
  void dispose() {
    for (final callback in _disposeCallbacks) {
      callback();
    }
    _disposeCallbacks.clear();
  }
}

// Использование:
class ExampleViewModel extends BaseViewModel {
  final ValueNotifier<String> data = ValueNotifier('');
  
  ExampleViewModel() {
    addDisposeCallback(data.dispose); // ✅ Автоматически dispose
  }
}
```

---

## 6. ✅ ValueListenableBuilder Pattern

### Правильное использование:
```dart
class CorrectView extends StatelessWidget {
  const CorrectView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExampleViewModel>();
    
    return ValueListenableBuilder<String>(
      valueListenable: viewModel.data,
      builder: (context, value, child) {
        // ✅ ValueListenableBuilder автоматически управляет подпиской
        return Text(value);
      },
    );
  }
}
```

### ❌ Неправильное использование:
```dart
class BadView extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    
    final viewModel = context.read<ExampleViewModel>();
    
    // ❌ Прямая подписка - нужно вручную отписываться
    viewModel.data.addListener(() {
      setState(() {});
    });
  }
  
  @override
  void dispose() {
    // ❌ Нужно вручную отписываться
    final viewModel = context.read<ExampleViewModel>();
    viewModel.data.removeListener(() {});
    super.dispose();
  }
}
```

---

## 🎯 Практические примеры для проекта

### LoginViewModel:
```dart
class LoginViewModel {
  final loginState = ValueNotifier<AsyncValue<void>>(const AsyncData(null));
  
  void dispose() {
    loginState.dispose(); // ✅ Dispose состояния логина
  }
}
```

### EmployeeListViewModel:
```dart
class EmployeeListViewModel extends ChangeNotifier {
  final ValueNotifier<String> searchQuery = ValueNotifier('');
  
  void setSearchQuery(String query) {
    searchQuery.value = query;
    notifyListeners();
  }
  
  void dispose() {
    searchQuery.dispose(); // ✅ Dispose поиска
    super.dispose();        // ✅ Dispose ChangeNotifier
  }
}
```

### ScheduleViewModel:
```dart
class ScheduleViewModel {
  final state = ValueNotifier<ScheduleState>(ScheduleState.initial());
  final StreamSubscription _realtimeSubscription;
  
  ScheduleViewModel({required ScheduleService service})
      : _realtimeSubscription = service.realtimeUpdates.listen(_handleUpdate);
  
  void dispose() {
    state.dispose();           // ✅ Dispose состояния
    _realtimeSubscription.cancel(); // ✅ Отменить подписку
  }
}
```

---

## 🔍 Инструменты для проверки

### 1. Flutter Inspector
- Проверять количество объектов в памяти
- Искать "leaked" объекты после dispose

### 2. Dart DevTools
- Memory tab для анализа утечек
- Profile tab для поиска проблемных мест

### 3. Console logging:
```dart
class DebugViewModel {
  final ValueNotifier<String> data = ValueNotifier('');
  
  DebugViewModel() {
    debugPrint('ViewModel created: ${hashCode()}');
  }
  
  void dispose() {
    debugPrint('ViewModel disposed: ${hashCode()}');
    data.dispose();
  }
}
```

---

## 📝 Рекомендации для проекта

### 1. Создать BaseViewModel:
```dart
abstract class BaseViewModel {
  final List<VoidCallback> _disposeCallbacks = [];
  
  void addDisposeCallback(VoidCallback callback) {
    _disposeCallbacks.add(callback);
  }
  
  void dispose() {
    for (final callback in _disposeCallbacks) {
      callback();
    }
    _disposeCallbacks.clear();
  }
}
```

### 2. Использовать extension для проверки:
```dart
extension ViewModelDebug on ChangeNotifier {
  void debugDispose() {
    debugPrint('ChangeNotifier disposed: ${runtimeType}');
  }
}

extension ValueNotifierDebug<T> on ValueNotifier<T> {
  void debugDispose() {
    debugPrint('ValueNotifier disposed: ${runtimeType}');
  }
}
```

### 3. Добавить в architecture.mdc:
```markdown
## Memory Management Rules
- All ViewModels MUST have a dispose() method
- All ValueNotifiers MUST be disposed in ViewModel.dispose()
- All StreamSubscriptions MUST be cancelled in ViewModel.dispose()
- Views MUST call ViewModel.dispose() in their dispose()
- Use ValueListenableBuilder instead of manual listeners
```

---

**Последнее обновление**: 2025-11-28  
**Статус**: Готов к реализации