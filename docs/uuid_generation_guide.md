# 🆔 UUID Generation Guide

## 📋 Текущее состояние
**Проблема**: При создании новых Employee/Shift нужны UUID, но нет проверки уникальности  
**Риск**: Дубликаты ID могут привести к багам в UI

---

## 🎯 Решение: UUID Generation + Uniqueness Check

### 1. ✅ UUID Package (уже в зависимостях)
```yaml
# pubspec.yaml
dependencies:
  uuid: ^4.0.0  # ✅ Уже добавлен
```

### 2. ✅ UUID Generation Pattern
```dart
import 'package:uuid/uuid.dart';

class UuidGenerator {
  static final Uuid _uuid = const Uuid();
  
  // Генерируем UUID v4 (random)
  static String generateId() => _uuid.v4();
  
  // Генерируем UUID v7 (time-based) - лучше для сортировки
  static String generateTimeBasedId() => _uuid.v7();
  
  // Генерируем UUID v5 (namespace-based) - для предсказуемости
  static String generateNamespaceId(String namespace, String name) =>
      _uuid.v5(Uuid.NAMESPACE_URL, name);
}
```

### 3. ✅ MockApiService с проверкой уникальности
```dart
import 'package:uuid/uuid.dart';

class MockApiService {
  final Set<String> _usedIds = <String>{};
  final Uuid _uuid = const Uuid();
  
  Future<Employee> createEmployee(CreateEmployeeRequest request) async {
    await _simulateNetworkDelay();
    
    // ✅ Проверяем уникальность ID
    String newId;
    int attempts = 0;
    const maxAttempts = 100;
    
    do {
      newId = _uuid.v4();
      attempts++;
      
      if (attempts > maxAttempts) {
        throw Exception('Failed to generate unique ID after $maxAttempts attempts');
      }
    } while (_usedIds.contains(newId));
    
    _usedIds.add(newId);
    
    final employee = Employee(
      id: newId,
      firstName: request.firstName,
      lastName: request.lastName,
      email: request.email,
      phone: request.phone,
      position: request.position,
      status: EmployeeStatus.active,
      hireDate: DateTime.now(),
    );
    
    _employees.add(employee);
    return employee;
  }
  
  Future<Shift> createShift(CreateShiftRequest request) async {
    await _simulateNetworkDelay();
    
    // ✅ Проверяем уникальность ID
    String newId;
    int attempts = 0;
    const maxAttempts = 100;
    
    do {
      newId = _uuid.v4();
      attempts++;
      
      if (attempts > maxAttempts) {
        throw Exception('Failed to generate unique ID after $maxAttempts attempts');
      }
    } while (_usedIds.contains(newId));
    
    _usedIds.add(newId);
    
    // ✅ Проверяем конфликты смен
    final conflictingShift = _shifts.firstWhere(
      (shift) => 
        shift.employeeId == request.employeeId &&
        _isTimeOverlapping(shift, request.startTime, request.endTime),
      orElse: () => null as Shift,
    );
    
    if (conflictingShift != null) {
      throw ValidationError(
        'Shift conflicts with existing shift for employee',
        code: 'SHIFT_CONFLICT'
      );
    }
    
    final shift = Shift(
      id: newId,
      employeeId: request.employeeId,
      startTime: request.startTime,
      endTime: request.endTime,
      status: ShiftStatus.scheduled,
      notes: request.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _shifts.add(shift);
    return shift;
  }
  
  bool _isTimeOverlapping(Shift existing, DateTime newStart, DateTime newEnd) {
    return (newStart.isBefore(existing.endTime) && newEnd.isAfter(existing.startTime));
  }
}
```

---

## 4. ✅ Repository с UUID генерацией
```dart
class EmployeeRepository {
  final ApiService _apiService;
  final Uuid _uuid = const Uuid();
  
  EmployeeRepository({required ApiService apiService})
      : _apiService = apiService;
  
  Future<Employee> createEmployee(CreateEmployeeRequest request) async {
    // ✅ Repository генерирует ID
    final employeeWithId = request.copyWith(
      id: _uuid.v4(),
    );
    
    return await _apiService.createEmployee(employeeWithId);
  }
  
  Future<Shift> createShift(CreateShiftRequest request) async {
    // ✅ Repository генерирует ID
    final shiftWithId = request.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return await _apiService.createShift(shiftWithId);
  }
}
```

---

## 5. ✅ ViewModel с UUID
```dart
class CreateEmployeeViewModel extends ChangeNotifier {
  final EmployeeRepository _repository;
  
  CreateEmployeeViewModel({required EmployeeRepository repository})
      : _repository = repository;
  
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _phone;
  String? _position;
  
  final createState = ValueNotifier<AsyncValue<Employee>>(const AsyncLoading());
  
  Future<void> createEmployee() async {
    // ✅ Валидация
    if (!_validateForm()) {
      createState.value = AsyncError('Please fill all required fields');
      return;
    }
    
    createState.value = const AsyncLoading();
    
    try {
      final request = CreateEmployeeRequest(
        firstName: _firstName!,
        lastName: _lastName!,
        email: _email!,
        phone: _phone!,
        position: _position!,
      );
      
      // ✅ Repository генерирует UUID автоматически
      final employee = await _repository.createEmployee(request);
      createState.value = AsyncData(employee);
      
      // ✅ Очищаем форму
      _clearForm();
      
    } catch (error, stackTrace) {
      ErrorHandler.handle(error, stackTrace);
      createState.value = AsyncError('Failed to create employee');
    }
  }
  
  bool _validateForm() {
    return _firstName != null && _firstName!.isNotEmpty &&
           _lastName != null && _lastName!.isNotEmpty &&
           _email != null && _email!.isNotEmpty &&
           _position != null && _position!.isNotEmpty;
  }
  
  void _clearForm() {
    _firstName = null;
    _lastName = null;
    _email = null;
    _phone = null;
    _position = null;
    notifyListeners();
  }
  
  void dispose() {
    createState.dispose();
  }
}
```

---

## 6. ✅ Request DTOs
```dart
// Запрос на создание сотрудника (без ID)
class CreateEmployeeRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String position;
  
  const CreateEmployeeRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.position,
  });
  
  CreateEmployeeRequest copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? position,
  }) {
    return CreateEmployeeRequest(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      position: position ?? this.position,
    );
  }
}

// Запрос на создание смены (без ID)
class CreateShiftRequest {
  final String employeeId;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  
  const CreateShiftRequest({
    required this.employeeId,
    required this.startTime,
    required this.endTime,
    this.notes,
  });
  
  CreateShiftRequest copyWith({
    String? id,
    String? employeeId,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreateShiftRequest(
      employeeId: employeeId ?? this.employeeId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
    );
  }
}
```

---

## 7. ✅ Model Updates
```dart
class Employee {
  final String id;
  final String firstName;
  final String lastName;
  // ... другие поля
  
  const Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    // ... другие параметры
  });
  
  // ✅ Фабричный метод для создания с новым ID
  factory Employee.withGeneratedId({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    required String position,
    required EmployeeStatus status,
    required DateTime hireDate,
  }) {
    return Employee(
      id: UuidGenerator.generateId(), // ✅ Автоматическая генерация
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      position: position,
      status: status,
      hireDate: hireDate,
    );
  }
  
  // ✅ Метод для копирования с новым ID
  Employee copyWithNewId({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? position,
    EmployeeStatus? status,
    DateTime? hireDate,
  }) {
    return Employee(
      id: UuidGenerator.generateId(), // ✅ Новый ID при копировании
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      position: position ?? this.position,
      status: status ?? this.status,
      hireDate: hireDate ?? this.hireDate,
    );
  }
}
```

---

## 8. ✅ Testing UUID Generation
```dart
// test/utils/uuid_test.dart
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

void main() {
  group('UUID Generation', () {
    late Uuid uuid;
    
    setUp(() {
      uuid = const Uuid();
    });
    
    test('generates unique IDs', () {
      final ids = <String>[];
      
      // Генерируем 1000 ID и проверяем уникальность
      for (int i = 0; i < 1000; i++) {
        final id = uuid.v4();
        expect(ids, isNot(contains(id)));
        ids.add(id);
      }
    });
    
    test('generates valid UUID format', () {
      final id = uuid.v4();
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      
      expect(uuidRegex.hasMatch(id), true);
    });
    
    test('generates different types of UUIDs', () {
      final v4 = uuid.v4();
      final v7 = uuid.v7();
      final v5 = uuid.v5(Uuid.NAMESPACE_URL, 'test');
      
      expect(v4, isNot(equals(v7)));
      expect(v4, isNot(equals(v5)));
      expect(v7, isNot(equals(v5)));
    });
  });
}
```

---

## 9. ✅ Performance Considerations

### UUID v4 (Random):
- ✅ Быстрое генерирование
- ✅ Нет коллизий (практически)
- ❌ Не сортируется по времени

### UUID v7 (Time-based):
- ✅ Сортируется по времени
- ✅ Уникальность гарантирована
- ⚠️ Немного медленнее

### Рекомендация:
```dart
// Для сущностей с временной зависимостью (Shift, Log):
final shiftId = _uuid.v7(); // ✅ Сортируется по времени

// Для сущностей без временной зависимости (Employee):
final employeeId = _uuid.v4(); // ✅ Быстрее
```

---

## 10. ✅ Integration Checklist

### Для MockApiService:
```markdown
- [ ] Добавить import 'package:uuid/uuid.dart'
- [ ] Создать Set<String> _usedIds для отслеживания
- [ ] Реализовать проверку уникальности ID
- [ ] Обрабатывать коллизии (бросать исключение)
- [ ] Генерировать ID в методах create*
```

### Для Repository:
```markdown
- [ ] Использовать Request DTOs без ID
- [ ] Генерировать ID перед вызовом API
- [ ] Передавать ID в API вызов
```

### Для ViewModel:
```markdown
- [ ] Использовать Request DTOs
- [ ] Не передавать ID в формы
- [ ] Проверять валидацию перед созданием
```

### Для Models:
```markdown
- [ ] Добавить фабричные методы withGeneratedId
- [ ] Добавить copyWithNewId методы
- [ ] Обновить fromJson для обработки ID
```

---

## 🎯 Практическая реализация

### Шаг 1: Обновить MockApiService
```dart
// Добавить в начало файла:
import 'package:uuid/uuid.dart';

class MockApiService {
  final Set<String> _usedIds = <String>{};
  final Uuid _uuid = const Uuid();
  
  // Обновить методы create* с проверкой уникальности
}
```

### Шаг 2: Создать Request DTOs
```dart
// lib/data/requests/create_employee_request.dart
class CreateEmployeeRequest { ... }

// lib/data/requests/create_shift_request.dart  
class CreateShiftRequest { ... }
```

### Шаг 3: Обновить Repository
```dart
// Генерировать ID перед API вызовом
Future<Employee> createEmployee(CreateEmployeeRequest request) async {
  final employeeWithId = request.copyWith(id: _uuid.v4());
  return await _apiService.createEmployee(employeeWithId);
}
```

---

**Рекомендация**: Внедрить UUID генерацию с проверкой уникальности для предотвращения дубликатов ID.

**Последнее обновление**: 2025-11-28