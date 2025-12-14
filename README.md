# CRM - Система управления персоналом и сменами

## Оглавление
1. [Обзор проекта](#обзор-проекта)
2. [Архитектура](#архитектура)
3. [Технологический стек](#технологический-стек)
4. [Структура проекта](#структура-проекта)
5. [База данных](#база-данных)
6. [Установка и настройка](#установка-и-настройка)
7. [Запуск проекта](#запуск-проекта)
8. [Основные функции](#основные-функции)
9. [Роутинг](#роутинг)
10. [Разработка](#разработка)

## Обзор проекта

CRM система для управления персоналом, филиалами, должностями и расписанием смен. Приложение построено на Flutter и использует Supabase в качестве backend.

### Основные возможности:
- ✅ Управление сотрудниками (CRUD операции)
- ✅ Управление филиалами
- ✅ Управление должностями с почасовой оплатой
- ✅ Планирование и управление сменами
- ✅ График смен с визуализацией (Syncfusion Calendar)
- ✅ Авторизация и регистрация
- ✅ Роли: менеджер и сотрудник
- ✅ Фильтрация по должностям, филиалам, датам
- ✅ Drag & Drop для перемещения смен
- ✅ Конфликты смен (детекция пересечений)
- ✅ Dashboard с статистикой

## Архитектура

Проект использует **MVVM (Model-View-ViewModel)** паттерн с четким разделением слоев:

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  ┌──────────┐       ┌──────────────┐   │
│  │   View   │ ←──→  │  ViewModel   │   │
│  └──────────┘       └──────────────┘   │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│          Business Logic Layer           │
│  ┌──────────────┐   ┌──────────────┐   │
│  │ App Services │   │  Repository  │   │
│  └──────────────┘   └──────────────┘   │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│            Data Layer                   │
│  ┌───────────────────────────────────┐  │
│  │      ApiService (Supabase)        │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Правила зависимостей:

1. **View** → может использовать только **ViewModel**
2. **ViewModel** → может использовать **Repository** и **App Services**
3. **Repository** → может использовать только **ApiService**
4. **App Services** → используются для разделяемого состояния между ViewModels

### Dependency Injection

Используется собственный `ModuleLocator` для управления зависимостями. Все сервисы регистрируются в `lib/config/locator_config.dart`.

## Технологический стек

### Frontend
- **Flutter** 3.8.0+ - 
- **Dart** 3.8.0+ 

### Backend & Data

#### supabase_flutter (^2.10.3)
**Назначение**: Backend as a Service (BaaS) платформа для работы с базой данных, аутентификацией и real-time подписками.

**Использование в проекте**:
- Авторизация и регистрация пользователей (через Supabase Auth)
- CRUD операции с базой данных PostgreSQL
- Row Level Security (RLS) для защиты данных
- Real-time обновления для синхронизации данных между клиентами

**Расположение**: `lib/core/config/supabase_config.dart`, `lib/data/services/supabase_api_service.dart`

---

### UI Components

#### syncfusion_flutter_core (^31.2.16)
**Назначение**: Ядро библиотеки Syncfusion, необходимый базовый пакет для всех компонентов Syncfusion.

**Использование в проекте**: Используется как зависимость для других пакетов Syncfusion (Calendar, DataGrid, Charts).

#### syncfusion_flutter_calendar (^31.2.16)
**Назначение**: Компонент календаря с поддержкой множества представлений (день, неделя, месяц, timeline) и drag & drop.

**Использование в проекте**:
- График смен сотрудников (`lib/schedule/views/schedule_view.dart`)
- Визуализация расписания с возможностью перемещения смен
- Отображение смен в разных форматах (week, month, timeline)

**Ключевые возможности**:
- Drag & Drop для перемещения смен
- Кастомные ячейки для отображения информации о сменах
- Фильтрация и группировка событий

#### syncfusion_flutter_datagrid (^31.2.16)
**Назначение**: Высокопроизводительная таблица данных с сортировкой, фильтрацией и группировкой.

**Использование в проекте**:
- Таблица сотрудников (`lib/employees_syncfusion/views/employee_syncfusion_view.dart`)
- Отображение списка сотрудников с возможностью сортировки и фильтрации
- Редактирование данных в ячейках

**Ключевые возможности**:
- Виртуализация для работы с большими объемами данных
- Сортировка по столбцам
- Кастомные ячейки и стилизация

#### syncfusion_flutter_charts (^31.2.16)
**Назначение**: Библиотека для создания различных типов графиков и диаграмм.

**Использование в проекте**:
- Графики загрузки на Dashboard (`lib/dashboard/widgets/loading_hours_chart.dart`)
- Визуализация статистики по сменам и сотрудникам
- Диаграммы распределения нагрузки

#### google_fonts (^6.0.0)
**Назначение**: Пакет для загрузки и использования Google Fonts в приложении.

**Использование в проекте**:
- Кастомные шрифты для улучшения дизайна
- Используется в теме приложения (`lib/core/ui/app_theme.dart`)

#### timeline_tile (^2.0.0)
**Назначение**: Виджет для создания таймлайнов и временных линий.

**Использование в проекте**: Может использоваться для визуализации истории событий или временных последовательностей в профилях сотрудников.

#### percent_indicator (^4.0.0)
**Назначение**: Виджеты для отображения процентных индикаторов и прогресс-баров.

**Использование в проекте**:
- Индикаторы прогресса
- Визуализация статистики и метрик на Dashboard

#### flutter_svg (^2.0.0)
**Назначение**: Библиотека для отображения SVG изображений в Flutter.

**Использование в проекте**: Отображение векторных иконок и графики, если используются SVG файлы в проекте.

#### cupertino_icons (^1.0.8)
**Назначение**: Стандартный набор иконок iOS (Cupertino) для использования в Flutter.

**Использование в проекте**: Использование стандартных иконок для интерфейса приложения.

---

### Utilities

#### uuid (^4.0.0)
**Назначение**: Генератор UUID (Universally Unique Identifier) для создания уникальных идентификаторов.

**Использование в проекте**:
- Генерация уникальных ID для всех сущностей (сотрудники, смены, филиалы, должности)
- Используется в Repository слое для создания новых записей
- Заменяет автоинкрементные ID для лучшей масштабируемости

**Расположение**: Используется в `lib/data/repositories/` для генерации ID при создании новых сущностей.

#### equatable (^2.0.0)
**Назначение**: Пакет для упрощения сравнения объектов через переопределение операторов `==` и `hashCode`.

**Использование в проекте**:
- Использование в моделях данных для корректного сравнения объектов
- Упрощает сравнение объектов Employee, Shift, Branch, Position
- Важно для работы с ValueNotifier и проверок изменений состояния

#### intl (^0.20.2)
**Назначение**: Пакет для интернационализации и локализации, форматирования дат, чисел и валют.

**Использование в проекте**:
- Форматирование дат и времени (русская локаль)
- Отображение дат создания смен, найма сотрудников
- Используется в `lib/core/utils/date_formatter.dart`
- Инициализируется в `main.dart` с русской локалью

#### logging (^1.2.0)
**Назначение**: Пакет для структурированного логирования в приложении.

**Использование в проекте**:
- Логирование операций приложения
- Отладка и мониторинг работы приложения
- Используется через абстракцию в `lib/core/abstractions/logging_abstraction.dart`
- HTTP логирование через `lib/core/utils/http/http_interceptor.dart`

---

### HTTP Clients

#### http (^1.3.0)
**Назначение**: Базовый HTTP клиент для Dart, предоставляет функции для выполнения HTTP запросов.

**Использование в проекте**: 
- Используется как базовый HTTP клиент
- Может использоваться в HTTP абстракциях для выполнения запросов к API

#### cronet_http (^1.3.3)
**Назначение**: HTTP клиент на основе Chromium Cronet, обеспечивает высокую производительность и поддержку HTTP/2.

**Использование в проекте**: 
- Оптимизированный HTTP клиент для Android платформы
- Обеспечивает лучшую производительность и эффективность работы с сетью
- Используется для HTTP запросов к Supabase API

#### cupertino_http (^2.1.0)
**Назначение**: HTTP клиент на основе NSURLSession для iOS платформы.

**Использование в проекте**: 
- Нативный HTTP клиент для iOS платформы
- Обеспечивает интеграцию с iOS системой сетевого стека
- Используется для HTTP запросов к Supabase API на iOS

---

### Development Dependencies

#### flutter_test (SDK)
**Назначение**: Фреймворк для unit и widget тестирования в Flutter.

**Использование в проекте**: 
- Написание unit тестов для бизнес-логики
- Widget тесты для проверки UI компонентов
- Тесты находятся в папке `test/`

#### integration_test (SDK)
**Назначение**: Фреймворк для интеграционного тестирования приложения.

**Использование в проекте**: 
- Интеграционные тесты для проверки полных сценариев использования
- End-to-end тестирование функциональности

#### flutter_lints (^5.0.0)
**Назначение**: Набор правил линтера для Flutter, помогающий поддерживать качество кода.

**Использование в проекте**: 
- Проверка кода на соответствие стандартам Flutter
- Правила активируются в `analysis_options.yaml`
- Помогает находить потенциальные проблемы и поддерживать единый стиль кода

#### mcp_server (^1.0.3)
**Назначение**: Пакет для работы с MCP (Model Context Protocol) серверами.

**Использование в проекте**: 
- Используется для интеграции с MCP серверами в процессе разработки
- Может использоваться для инструментов разработки и интеграции с AI-ассистентами

## Структура проекта

```
lib/
├── auth/                          # Модуль авторизации
│   ├── viewmodels/               # AuthViewModel, RegistrationViewModel
│   └── views/                    # LoginView, RegistrationView
│
├── branches/                      # Управление филиалами
│   ├── branch_view_model.dart
│   ├── branch_view.dart
│   └── widgets/                  # CreateBranchDialog, EditBranchDialog
│
├── config/                        # Конфигурация приложения
│   ├── locator_config.dart       # Dependency Injection setup
│   └── route_config.dart         # Роутинг конфигурация
│
├── core/                         # Ядро приложения
│   ├── abstractions/             # Абстракции (logging)
│   ├── config/                   # Конфигурация (Supabase)
│   ├── constants/                # Константы (API endpoints, app constants)
│   ├── services/                 # App Services (AuthService)
│   ├── ui/                       # UI компоненты и темы
│   │   ├── app_theme.dart
│   │   ├── constants/            # Colors, spacing, text styles
│   │   └── widgets/              # Переиспользуемые виджеты
│   └── utils/                    # Утилиты
│       ├── async_value.dart      # AsyncValue для состояния
│       ├── error_handler.dart    # Обработка ошибок
│       ├── locator.dart          # DI контейнер
│       ├── navigation/           # Навигация и роутинг
│       ├── http/                 # HTTP клиент и interceptors
│       └── retry/                # Retry logic и circuit breaker
│
├── dashboard/                    # Главная панель
│   ├── models/                   # DashboardStats, DashboardAlert
│   ├── viewmodels/              # DashboardViewModel
│   ├── views/                   # DashboardView, HomeView
│   └── widgets/                 # Статистические виджеты
│
├── data/                         # Слой данных
│   ├── models/                  # Модели данных (Employee, Shift, Branch, Position)
│   ├── repositories/            # Репозитории (абстракции доступа к данным)
│   └── services/                # ApiService, SupabaseApiService, MockApiService
│
├── employees_syncfusion/        # Модуль управления сотрудниками
│   ├── models/                  # EmployeeSyncfusionModel, ProfileModel
│   ├── viewmodels/             # EmployeeSyncfusionViewModel, ProfileViewModel
│   ├── views/                  # EmployeeSyncfusionView, ProfileView
│   └── widgets/                # Диалоги и фильтры
│
├── positions/                   # Управление должностями
│   ├── position_view_model.dart
│   ├── position_view.dart
│   └── widgets/                # CreatePositionDialog, EditPositionDialog
│
├── schedule/                    # Модуль расписания смен
│   ├── constants/              # Константы расписания
│   ├── models/                 # ShiftModel, ShiftAdapter, фильтры
│   ├── utils/                  # ShiftConflictChecker, ScheduleStatistics
│   ├── viewmodels/             # ScheduleViewModel, ShiftDataSource
│   ├── views/                  # ScheduleView, MobileScheduleGridView
│   └── widgets/                # Виджеты календаря смен
│
├── startup/                     # Инициализация приложения
│   ├── startup_view_model.dart
│   └── startup_view.dart
│
├── home/                        # Главная страница
├── not_found/                   # 404 страница
└── main.dart                    # Точка входа
```

## База данных

### Схема базы данных

#### Таблицы:

1. **profiles** - Профили пользователей
   - `id` (UUID, PK) - Связан с auth.users.id
   - `email` (TEXT, UNIQUE)
   - `first_name`, `last_name` (TEXT)
   - `role` (TEXT) - 'employee' или 'manager'
   - `status` (TEXT) - 'active', 'inactive', 'pending'
   - `branch_id` (UUID, FK → branches.id)
   - `position` (TEXT) - Название должности
   - `hourly_rate` (NUMERIC) - Почасовая ставка
   - `hire_date` (TIMESTAMP)
   - `avatar_url`, `phone`, `address` (TEXT, nullable)

2. **branches** - Филиалы компании
   - `id` (UUID, PK)
   - `name` (TEXT, UNIQUE)
   - `address` (TEXT, nullable)
   - `created_at`, `updated_at` (TIMESTAMP)

3. **positions** - Должности
   - `id` (UUID, PK)
   - `name` (TEXT, UNIQUE)
   - `hourly_rate` (NUMERIC)
   - `created_at`, `updated_at` (TIMESTAMP)

4. **shifts** - Смены
   - `id` (UUID, PK)
   - `employee_id` (UUID, FK → profiles.id)
   - `start_time`, `end_time` (TIMESTAMP)
   - `role_title` (TEXT) - Название роли
   - `location` (TEXT) - Локация филиала
   - `status` (TEXT) - 'confirmed', 'swap_requested'
   - `hourly_rate` (NUMERIC) - Ставка для конкретной смены
   - `is_night_shift` (BOOLEAN)
   - `employee_preferences` (TEXT, nullable)
   - `notes` (TEXT, nullable)
   - `created_at`, `updated_at` (TIMESTAMP)

5. **shift_swaps** - Обмен сменами
   - `id` (UUID, PK)
   - `requester_id` (UUID, FK → profiles.id)
   - `shift_id` (UUID, FK → shifts.id)
   - `target_employee_id` (UUID, FK → profiles.id)
   - `status` (TEXT) - 'pending', 'approved', 'rejected'
   - `manager_comment` (TEXT, nullable)

6. **audit_logs** - Журнал аудита
   - `id` (UUID, PK)
   - `user_id` (UUID, FK → profiles.id)
   - `action` (TEXT) - Тип действия
   - `table_name` (TEXT)
   - `record_id` (UUID)
   - `old_data`, `new_data` (JSONB)
   - `created_at` (TIMESTAMP)


### Миграции

Миграции находятся в `supabase/migrations/`:
- Миграции применяются автоматически при `supabase start`
- Для production: использовать Supabase Dashboard или CLI

## Установка и настройка

### Предварительные требования

- Flutter SDK 3.8.0+
- Dart SDK 3.8.0+
- Supabase CLI (для локальной разработки)
- Git


4. **Конфигурация приложения**

Файл `lib/core/config/supabase_config.dart` уже настроен для локальной разработки:
```dart
static const bool useLocal = true;  // Для локальной разработки
```



## Основные функции

### 1. Авторизация и регистрация
- **Логин**: `/login`
- **Регистрация**: `/register`
- Поддержка ролей: менеджер и сотрудник
- Статус аккаунта: pending, active, inactive

### 2. Управление сотрудниками
- **Список**: `/dashboard/employees`
- **Профиль**: `/dashboard/employees/:id`
- CRUD операции через диалоги
- Фильтрация по филиалам и должностям
- Использование Syncfusion DataGrid

### 3. Управление филиалами
- **Страница**: `/dashboard/branches`
- Создание, редактирование, удаление филиалов
- Поле адреса для каждого филиала

### 4. Управление должностями
- **Страница**: `/dashboard/positions`
- Создание, редактирование, удаление должностей
- Настройка почасовой ставки

### 5. График смен
- **Страница**: `/dashboard/schedule`
- Визуализация через Syncfusion Calendar
- Drag & Drop для перемещения смен
- Фильтрация по:
  - Сотрудникам
  - Должностям
  - Филиалам
  - Датам (диапазон)
  - Статусу смен
- Детекция конфликтов смен
- Статистика (общее количество часов, сотрудников)

### 6. Dashboard
- **Главная**: `/dashboard`
- Статистика:
  - Количество сотрудников
  - Активные смены
  - Общее количество часов
- Графики загрузки
- Быстрые действия

## Роутинг

Роутинг настроен в `lib/config/route_config.dart`. Используется кастомный `BestRouter` для навигации.

### Публичные маршруты (не требуют авторизации):
- `/` → LoginView
- `/login` → LoginView
- `/register` → RegistrationView
- `/404` → NotFoundView

### Защищенные маршруты (требуют авторизации):
- `/dashboard` → HomeView (в DashboardView)
- `/dashboard/employees` → EmployeeSyncfusionView
- `/dashboard/employees/:id` → ProfileView
- `/dashboard/schedule` → ScheduleView
- `/dashboard/branches` → BranchView
- `/dashboard/positions` → PositionView

Все защищенные маршруты обернуты в `DashboardView`, который предоставляет общий layout с навигацией.

## Разработка

### State Management

Проект использует несколько подходов в зависимости от сложности:

1. **ValueNotifier** - для простых состояний
2. **ChangeNotifier** - для средних по сложности
3. **State Object Pattern** - для сложных состояний

### Обработка ошибок

Централизованная обработка через `ErrorHandler`:
- Все async операции обернуты в try-catch
- Использование `AsyncValue<T>` для состояний
- Уведомления пользователя через `NotifyService`


### UUID Generation

Все ID генерируются как UUID строки (не int):
- Использование пакета `uuid`
- Валидация уникальности в API сервисе
- ID генерируются в Repository слое


### Memory Management

Важно правильно управлять памятью:
- Все ViewModels должны иметь `dispose()` метод
- ValueNotifiers должны быть disposed
- Views должны вызывать `viewModel.dispose()` в своем `dispose()`


### Code Style

- Использование `flutter_lints` для проверки кода
- Форматирование через `dart format`
- Комментарии только где необходимо
- Self-documenting code через описательные имена

