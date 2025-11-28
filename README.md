# Shift Manager CRM - MVP

Flutter-приложение для управления сменами сотрудников с адаптивным интерфейсом для Desktop/Tablet/Mobile.

## 🎯 Описание проекта

Shift Manager CRM - это система управления сменами сотрудников, разработанная по архитектуре MVVM с использованием Repository Pattern. Проект включает mock API для разработки и тестирования без backend.

### Основные возможности MVP:

- ✅ Аутентификация (логин/логаут)
- ✅ Управление сотрудниками (CRUD)
- ✅ Управление сменами (CRUD)
- ✅ Календарь смен (Syncfusion Calendar)
- ✅ Адаптивный UI (Desktop/Tablet/Mobile)
- ✅ Mock API с тестовыми данными

## 🏗️ Архитектура

### MVVM + Repository Pattern

```
View → ViewModel → Repository → Service
```

**Правила:**

- View общается только с ViewModel
- ViewModel общается только с Repository
- Repository общается с Service
- ViewModel НИКОГДА не обращается к Service напрямую

### Структура проекта

```
lib/
├── config/              # Конфигурация (routes, locator)
├── core/                # Ядро приложения
│   ├── abstractions/    # Интерфейсы
│   ├── constants/       # Константы приложения
│   ├── ui/              # UI компоненты и тема
│   └── utils/           # Утилиты (navigation, http, notifications)
├── data/                # Data Layer
│   ├── models/          # Модели данных
│   ├── repositories/    # Репозитории
│   └── services/        # Сервисы (API)
└── features/            # Фичи приложения
    ├── auth/            # Аутентификация
    ├── dashboard/       # Главная панель
    ├── employees/       # Управление сотрудниками
    └── schedule/        # Календарь смен
```

## 🚀 Быстрый старт

### Требования

- Flutter SDK 3.24.5+
- Dart 3.5.4+

### Установка

```bash
# Клонировать репозиторий
git clone https://github.com/borchik26/Shift_Manager_CRM.git
cd Shift_Manager_CRM

# Установить зависимости
flutter pub get

# Запустить приложение
flutter run
```

### Тестовые данные для входа

```
Email: admin@example.com
Password: password123
```

## 📦 Основные зависимости

```yaml
# State Management
flutter: sdk

# UI Components
syncfusion_flutter_calendar: ^27.2.5
pluto_grid: ^8.6.0

# HTTP
http: ^1.2.2

# Utilities
intl: ^0.19.0
```

## 🎨 UI Компоненты

### Базовые компоненты (lib/core/ui/widgets/)

- **AdaptiveCard** - Адаптивная карточка с max-width
- **CustomButton** - Кнопка с loading state
- **StatusBadge** - Цветные бейджи статусов
- **EmployeeAvatar** - Аватар с fallback на инициалы
- **LoadingIndicator** - Индикатор загрузки

### Утилиты (lib/core/utils/)

- **ResponsiveHelper** - Определение размера экрана
- **Validators** - Валидация форм
- **ErrorHandler** - Обработка ошибок
- **DateFormatter** - Форматирование дат

## 📊 Data Layer

### Модели (lib/data/models/)

```dart
// Employee
class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String position;
  final EmployeeStatus status;
  final DateTime hireDate;
}

// Shift
class Shift {
  final String id;
  final String employeeId;
  final DateTime startTime;
  final DateTime endTime;
  final ShiftStatus status;
  final String? notes;
}

// User
class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
}
```

### Mock API (lib/data/services/mock_api_service.dart)

- 50 тестовых сотрудников
- 20 тестовых смен
- Задержка 800ms для имитации сети
- Все CRUD операции

### Repositories (lib/data/repositories/)

- **AuthRepository** - Аутентификация
- **EmployeeRepository** - Управление сотрудниками
- **ShiftRepository** - Управление сменами

## 🗺️ Навигация

### Роуты (lib/config/route_config.dart)

```dart
/                          → StartupView
/login                     → LoginView
/dashboard                 → DashboardView
/dashboard/employees       → EmployeeListView
/dashboard/employees/:id   → EmployeeDetailView
/dashboard/schedule        → ScheduleView
```

## 🎯 Константы

### Статусы (lib/core/constants/app_constants.dart)

```dart
// Employee Status
enum EmployeeStatus { active, inactive, onLeave }

// Shift Status
enum ShiftStatus { scheduled, inProgress, completed, cancelled }

// User Role
enum UserRole { admin, manager, employee }
```

### API Endpoints (lib/core/constants/api_endpoints.dart)

```dart
class ApiEndpoints {
  static const String baseUrl = 'https://api.example.com';
  static const String login = '/auth/login';
  static const String employees = '/employees';
  static const String shifts = '/shifts';
  // ... и другие
}
```

## 📅 Syncfusion Calendar Integration

### Адаптер (lib/schedule/models/shift_adapter.dart)

```dart
// Конвертация Shift → Appointment
final appointment = ShiftAdapter.toAppointment(shift, employee);

// Создание DataSource для календаря
final dataSource = ShiftDataSource(shifts, employees);
```

## 🔧 Dependency Injection

### Locator (lib/config/locator_config.dart)

```dart
void setupLocator() {
  // Services
  locator.registerLazySingleton<ApiService>(() => MockApiService());
  
  // Repositories
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(locator<ApiService>())
  );
  // ... другие репозитории
}
```

## 📱 Адаптивность

### Breakpoints (lib/core/ui/constants/breakpoints.dart)

```dart
static const double mobile = 600;    // < 600px
static const double tablet = 1024;   // 600-1024px
static const double desktop = 1024;  // > 1024px
```

### Использование

```dart
final helper = ResponsiveHelper(context);

if (helper.isMobile) {
  // Mobile layout
} else if (helper.isTablet) {
  // Tablet layout
} else {
  // Desktop layout
}
```

## 🧪 Тестирование

```bash
# Запустить все тесты
flutter test

# Запустить конкретный тест
flutter test test/core/utils/locator_test.dart
```

## 📝 План разработки (14 дней)

### ✅ День 1-2: Подготовка (ЗАВЕРШЕНО)

- [X] Анализ требований
- [X] Настройка проекта
- [X] Data Layer
- [X] Базовые компоненты

### 🔄 День 3-4: Аутентификация (ТЕКУЩИЙ ЭТАП)

- [ ] Login Screen
- [ ] Auth ViewModel
- [ ] Session Management

### 📋 День 5-7: Управление сотрудниками

- [ ] Employee List
- [ ] Employee Detail
- [ ] Employee Form (Create/Edit)

### 📅 День 8-10: Календарь смен

- [ ] Schedule View
- [ ] Shift Form
- [ ] Calendar Integration

### 🎨 День 11-12: UI/UX полировка

- [ ] Адаптивность
- [ ] Анимации
- [ ] Error handling

### 🧪 День 13-14: Тестирование и деплой

- [ ] Unit тесты
- [ ] Integration тесты
- [ ] Документация

## 📚 Документация

Архитектурные правила и документация по разработке находятся в локальной кодовой базе. Основные принципы:

- **Архитектура**: MVVM + Repository Pattern
- **State Management**: ValueNotifier для простых экранов, ChangeNotifier для сложных
- **Dependency Injection**: GetIt (locator)
- **Routing**: Custom Router на базе RouterDelegate

## 🤝 Вклад в проект

1. Следуйте архитектурным правилам проекта (MVVM + Repository Pattern)
2. Используйте snake_case для JSON ключей
3. Все ViewModels используют ValueNotifier или ChangeNotifier
4. Никогда не обращайтесь к Service из ViewModel напрямую - только через Repository
5. Все async операции оборачивайте в AsyncValue для обработки состояний

## 📄 Лицензия

MIT License

## 👥 Команда

- **Frontend**: Flutter Developer
- **Backend**: Backend Developer
- **Design**: UI/UX Designer

## 🔗 Ссылки

- **Репозиторий**: [https://github.com/borchik26/Shift_Manager_CRM](https://github.com/borchik26/Shift_Manager_CRM)
- **Issues**: [GitHub Issues](https://github.com/borchik26/Shift_Manager_CRM/issues)

---

**Статус проекта**: 🟢 В разработке (MVP Phase)
**Текущая версия**: 0.1.0
**Последнее обновление**: 2025-01-27
