# 💾 Mock Data Persistence Strategy

## 📋 Текущее состояние
**MockApiService** хранит все данные в памяти:
```dart
class MockApiService {
  List<Employee> _employees = [];
  List<Shift> _shifts = [];
  
  // ❌ При перезапуске приложения все данные теряются
}
```

---

## 🤔 Нужно ли persistence для MVP?

### ✅ Аргументы "НЕ НУЖНО":
1. **MVP фокус** - проверка UI/UX, а не данных
2. **Быстрая разработка** - persistence добавляет сложность
3. **Тестирование** - легко сбросить состояние
4. **Backend готовность** - данные все равно будут с сервера

### ⚠️ Аргументы "НУЖНО":
1. **UX continuity** - пользователь ожидает сохранения
2. **Разработка** - постоянный ввод данных утомляет
3. **Демонстрация** - показывать реальный сценарий использования

---

## 🎯 Рекомендация для текущего проекта

### ✅ MVP Phase (Дни 1-14): **НЕ НУЖНО**
```dart
// MockApiService - оставить как есть
class MockApiService {
  List<Employee> _employees = _generateMockEmployees(); // В памяти
  List<Shift> _shifts = _generateMockShifts();     // В памяти
  
  // ✅ Просто и быстро для MVP
}
```

**Причины:**
- Фокус на UI, а не на данные
- Быстрое прототипирование
- Легкое тестирование сценариев

### 🔄 Post-MVP Phase: **НУЖНО**
```dart
// Enhanced MockApiService с persistence
class EnhancedMockApiService {
  static const String _employeesKey = 'mock_employees';
  static const String _shiftsKey = 'mock_shifts';
  
  Future<void> _initializeFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Загружаем из SharedPreferences
    final employeesJson = prefs.getString(_employeesKey);
    if (employeesJson != null) {
      _employees = employeeFromJson(employeesJson);
    }
    
    final shiftsJson = prefs.getString(_shiftsKey);
    if (shiftsJson != null) {
      _shifts = shiftFromJson(shiftsJson);
    }
  }
  
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Сохраняем в SharedPreferences
    await prefs.setString(_employeesKey, employeeToJson(_employees));
    await prefs.setString(_shiftsKey, shiftToJson(_shifts));
  }
  
  // CRUD операции с автоматическим сохранением
  Future<Employee> createEmployee(Employee employee) async {
    _employees.add(employee);
    await _saveToStorage(); // ✅ Автоматически сохраняем
    return employee;
  }
}
```

---

## 🛠️ Implementation Options

### Option 1: SharedPreferences (Рекомендуется)
**Плюсы:**
- ✅ Просто в использовании
- ✅ Быстро
- ✅ Надежно для mobile/desktop
- ✅ Уже есть в Flutter ecosystem

**Минусы:**
- ❌ Не работает в Web (localStorage)
- ❌ Ограничение по размеру (~2MB)

**Реализация:**
```yaml
# pubspec.yaml
dependencies:
  shared_preferences: ^2.0.0
```

```dart
import 'package:shared_preferences/shared_preferences.dart';

class PersistentMockService {
  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();
  
  Future<void> saveEmployees(List<Employee> employees) async {
    final prefs = await _prefs;
    await prefs.setString('employees', jsonEncode(employees));
  }
  
  Future<List<Employee>> loadEmployees() async {
    final prefs = await _prefs;
    final json = prefs.getString('employees') ?? '[]';
    return (jsonDecode(json) as List)
        .map((e) => Employee.fromJson(e))
        .toList();
  }
}
```

### Option 2: Hive Database (Более мощно)
**Плюсы:**
- ✅ Быстрое чтение/запись
- ✅ Поддерживает сложные запросы
- ✅ Работает на всех платформах
- ✅ Нет ограничений по размеру

**Минусы:**
- ❌ Больше зависимостей
- ❌ Сложнее в настройке

**Реализация:**
```yaml
dependencies:
  hive: ^2.0.0
  hive_flutter: ^1.0.0
  path_provider: ^2.0.0
```

### Option 3: SQLite (Максимальная совместимость)
**Плюсы:**
- ✅ Полная SQL поддержка
- ✅ Совместимость с будущим backend
- ✅ Мощные запросы

**Минусы:**
- ❌ Самый сложный в настройке
- ❌ Избыточно для MVP

---

## 📅 Timeline внедрения

### Phase 1: MVP (Текущий)
```dart
// MockApiService - in memory only
class MockApiService {
  // ✅ Без persistence - просто и быстро
}
```

### Phase 2: Enhanced MVP (Опционально)
```dart
// MockApiService + SharedPreferences
class MockApiService {
  Future<void> initializePersistence() async {
    // Загрузить сохраненные данные при старте
  }
  
  Future<void> _persistData() async {
    // Сохранять после каждого изменения
  }
}
```

### Phase 3: Production Ready
```dart
// RealApiService + Local Cache
class ApiService {
  final HttpAbstraction _http;
  final LocalCache _cache;
  
  Future<List<Employee>> getEmployees() async {
    // Сначала из cache, потом из сети
    final cached = await _cache.getEmployees();
    if (cached != null) return cached;
    
    final network = await _http.getEmployees();
    await _cache.saveEmployees(network);
    return network;
  }
}
```

---

## 🎯 Рекомендация для текущего этапа

### ✅ Оставить MockApiService как есть
**Причины:**
1. **Speed** - Разработка MVP без задержек
2. **Focus** - UI/UX важнее данных
3. **Testing** - Легко сбросить состояние
4. **Simplicity** - Меньше кода, меньше багов

### 🔄 Добавить persistence ПОСЛЕ MVP
**Когда:**
- MVP готов и протестирован
- Нужна демонстрация с реальными данными
- Пользователи жалуются на потерю данных

### 📝 Checklist для внедрения persistence:
```markdown
- [ ] Добавить shared_preferences в pubspec.yaml
- [ ] Создать PersistentStorageService
- [ ] Интегрировать в MockApiService
- [ ] Добавить initialize() метод
- [ ] Тестировать сохранение/загрузку
- [ ] Обновить документацию
```

---

## 💡 Альтернативный подход: Hybrid

```dart
class HybridMockService {
  final MockApiService _memoryService = MockApiService();
  final PersistentStorage _storage = PersistentStorage();
  
  Future<List<Employee>> getEmployees() async {
    // Сначала пробуем из памяти
    if (_memoryService._employees.isNotEmpty) {
      return _memoryService._employees;
    }
    
    // Если память пуста - загружаем из storage
    final stored = await _storage.loadEmployees();
    _memoryService._employees = stored;
    return stored;
  }
  
  Future<void> createEmployee(Employee employee) async {
    await _memoryService.createEmployee(employee);
    await _storage.saveEmployee(employee);
  }
}
```

---

**Решение**: Для MVP оставить текущий MockApiService без persistence.  
Добавить persistence на этапе Post-MVP при необходимости.

**Последнее обновление**: 2025-11-28