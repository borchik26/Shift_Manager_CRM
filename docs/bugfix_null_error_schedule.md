# Исправление ошибки "Unexpected null value" в графике смен

## 🐛 Проблема
При открытии графика смен появлялась ошибка:
```
Failed to load schedule data: Unexpected null value.
```

## 🔍 Причина
В процессе оптимизации был добавлен кэш для `CalendarResource` объектов. Проблема возникла из-за неправильного порядка инициализации:

1. В методе `_loadData()` вызывался `_updateFilteredList()` (строка 78)
2. Внутри `_updateFilteredList()` пытались получить доступ к `_resourceCache['unassigned']!`
3. Но кэш для "unassigned" создавался **после** вызова `_updateFilteredList()` (строки 84-91)
4. Результат: `null` reference exception

## ✅ Решение

### Изменение 1: Порядок инициализации в `_loadData()`
**До:**
```dart
_updateFilteredList();

// Add "Open Shifts" resource (also cache it)
if (!_resourceCache.containsKey('unassigned')) {
  _resourceCache['unassigned'] = CalendarResource(...);
}
```

**После:**
```dart
// Add "Open Shifts" resource to cache BEFORE calling _updateFilteredList
if (!_resourceCache.containsKey('unassigned')) {
  _resourceCache['unassigned'] = CalendarResource(...);
}

_updateFilteredList();
```

### Изменение 2: Безопасный доступ в `_updateFilteredList()`
**До:**
```dart
if (_searchQuery == null || _searchQuery!.isEmpty || 'open shifts'.contains(_searchQuery!.toLowerCase())) {
  resources.insert(0, _resourceCache['unassigned']!); // ❌ Может быть null
}
```

**После:**
```dart
if (_searchQuery == null || _searchQuery!.isEmpty || 'open shifts'.contains(_searchQuery!.toLowerCase())) {
  // Ensure "Open Shifts" resource is cached
  if (!_resourceCache.containsKey('unassigned')) {
    _resourceCache['unassigned'] = CalendarResource(
      id: 'unassigned',
      displayName: 'Open Shifts',
      color: Colors.grey,
    );
  }
  resources.insert(0, _resourceCache['unassigned']!); // ✅ Гарантированно не null
}
```

## 📝 Итоги

### Что было исправлено:
1. ✅ Изменен порядок инициализации кэша в `_loadData()`
2. ✅ Добавлена проверка наличия "unassigned" в кэше в `_updateFilteredList()`
3. ✅ Гарантирована безопасность доступа к кэшированным ресурсам

### Как проверить:
1. Запустить приложение
2. Войти в систему (admin@example.com / password123)
3. Перейти на "График смен"
4. График должен загрузиться без ошибок

### Дополнительная диагностика:
Если ошибка повторяется, проверьте:
- Логи в консоли
- Правильность данных в `ShiftRepository` и `EmployeeRepository`
- Корректность метода `ShiftModel.fromShift()`

## 🎯 Результат
Ошибка `Unexpected null value` устранена. График смен загружается и работает корректно.
