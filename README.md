# CRM - Система управления персоналом и сменами

## Оглавление
1. [Обзор проекта](#обзор-проекта)
2. [Архитектура](#архитектура)
3. [Технологический стек](#технологический-стек)
4. [Структура проекта](#структура-проекта)
5. [База данных](#база-данных)
6. [Установка и настройка](#установка-и-настройка)
7. [Основные функции](#основные-функции)
8. [Роутинг](#роутинг)
9. [Разработка](#разработка)

## Обзор проекта

CRM система для управления персоналом, филиалами, должностями и расписанием смен. Приложение построено на Flutter с использованием MVVM архитектуры и Supabase в качестве backend.

### Основные возможности:
- ✅ Управление сотрудниками (CRUD операции, профили, одобрение регистраций)
- ✅ Управление филиалами с адресами
- ✅ Управление должностями с почасовой оплатой
- ✅ Планирование и управление сменами
- ✅ График смен с визуализацией (Syncfusion Calendar)
- ✅ Авторизация и регистрация с ролями
- ✅ Роли: менеджер и сотрудник
- ✅ Фильтрация по должностям, филиалам, датам, статусам
- ✅ Drag & Drop для перемещения смен
- ✅ Детекция конфликтов смен
- ✅ Dashboard с статистикой и графиками
- ✅ Журнал аудита (Audit Logs) для отслеживания всех изменений
- ✅ Адаптивный дизайн (мобильные и десктопные версии)
- ✅ Система уведомлений (Toast) с тактильной обратной связью

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
│  │   SupabaseApiService (Supabase)   │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Правила зависимостей:

1. **View** → может использовать только **ViewModel**
2. **ViewModel** → может использовать **Repository** и **App Services**
3. **Repository** → может использовать только **ApiService**
4. **App Services** → используются для разделяемого состояния между ViewModels
5. **ViewModels** → НИКОГДА не используют другие ViewModels (используйте App Services)
6. **ViewModels** → НЕ имеют доступа к BuildContext (делегируйте View)

### Dependency Injection

Используется собственный `ModuleLocator` для управления зависимостями. Все сервисы регистрируются в `lib/config/locator_config.dart`.

### State Management

Проект использует три подхода в зависимости от сложности:

1. **ValueNotifier<T>** - для простых состояний (1-2 независимых состояния)
2. **ChangeNotifier** - для средней сложности (множественные зависимые поля)

Все async операции оборачиваются в `AsyncValue<T>` для единообразной обработки состояний загрузки/ошибок.

## Технологический стек

### Frontend
- **Flutter** 3.8.0+
- **Dart** 3.8.0+

### Backend & Data

#### supabase_flutter (^2.10.3)
Backend as a Service (BaaS) платформа для работы с базой данных, аутентификацией и real-time подписками.

**Использование**:
- Авторизация и регистрация пользователей (Supabase Auth)
- CRUD операции с PostgreSQL
- Real-time обновления для синхронизации данных

**Расположение**: `lib/core/config/supabase_config.dart`, `lib/data/services/supabase_api_service.dart`

#### flutter_dotenv (^5.2.1)
Загрузка переменных окружения из .env файла.

**Использование**: Хранение Supabase URL и ключей, разделение конфигурации для локальной и production среды.

---

### UI Components

#### Syncfusion Flutter (^31.2.16)
Набор профессиональных UI компонентов:

- **syncfusion_flutter_calendar**: График смен с drag & drop (`lib/schedule/`)
- **syncfusion_flutter_datagrid**: Таблица сотрудников с сортировкой (`lib/employees_syncfusion/`)
- **syncfusion_flutter_charts**: Графики загрузки на Dashboard (`lib/dashboard/widgets/`)
- **syncfusion_flutter_core**: Базовый пакет для всех компонентов

#### Другие UI компоненты
- **google_fonts** (^6.0.0): Кастомные шрифты
- **timeline_tile** (^2.0.0): Временные линии
- **percent_indicator** (^4.0.0): Процентные индикаторы
- **flutter_svg** (^2.0.0): SVG изображения
- **cupertino_icons** (^1.0.8): iOS иконки

---

### Utilities

#### uuid (^4.0.0)
Генератор UUID для уникальных идентификаторов всех сущностей.

**Использование**: Генерация ID в Repository слое для сотрудников, смен, филиалов, должностей.

#### equatable (^2.0.0)
Упрощение сравнения объектов через переопределение `==` и `hashCode`.

**Использование**: Модели данных для корректного сравнения объектов.

#### intl (^0.20.2)
Интернационализация и форматирование дат, чисел, валют.

**Использование**: Форматирование дат (русская локаль) в `lib/core/utils/date_formatter.dart`.

#### logging (^1.2.0)
Структурированное логирование.

**Использование**: Логирование через `lib/core/abstractions/logging_abstraction.dart` и HTTP логирование через `lib/core/utils/http/http_interceptor.dart`.

---

### HTTP Clients

- **http** (^1.3.0): Базовый HTTP клиент
- **cronet_http** (^1.3.3): Оптимизированный клиент для Android (HTTP/2)
- **cupertino_http** (^2.1.0): Нативный клиент для iOS (NSURLSession)

---

### Development Dependencies

- **flutter_test** (SDK): Unit и widget тестирование
- **integration_test** (SDK): Интеграционное тестирование
- **flutter_lints** (^5.0.0): Правила линтера для качества кода
- **mcp_server** (^1.0.3): Интеграция с MCP серверами

## Структура проекта

```
lib/
├── audit_logs/                   # Модуль журнала аудита
│   ├── models/                  # audit_log_constants, audit_log_filter
│   ├── viewmodels/              # audit_log_data_source, audit_logs_view_model
│   ├── views/                   # audit_logs_view
│   └── widgets/                 # audit_log_detail_dialog, audit_log_filter_dialog, changes_diff_widget, mobile_audit_logs_view
│
├── auth/                         # Модуль авторизации
│   ├── viewmodels/              # auth_view_model, registration_view_model
│   └── views/                   # login_view, registration_view
│
├── branches/                     # Управление филиалами
│   ├── branch_view_model.dart
│   ├── branch_view.dart
│   └── widgets/                 # create_branch_dialog, edit_branch_dialog
│
├── config/                       # Конфигурация приложения
│   ├── locator_config.dart      # Dependency Injection setup
│   └── route_config.dart        # Роутинг конфигурация
│
├── core/                         # Ядро приложения
│   ├── abstractions/            # logging_abstraction
│   ├── config/                  # supabase_config
│   ├── constants/               # api_endpoints, app_constants
│   ├── services/                # auth_service
│   ├── ui/                      # UI компоненты и темы
│   │   ├── app_theme.dart
│   │   ├── constants/           # border_radius, breakpoints, durations, kit_colors, shadows, spacing, text_styles
│   │   └── widgets/             # adaptive_card, confirmation_dialog, custom_button, employee_avatar, filter_dropdown, loading_indicator, status_badge
│   └── utils/                   # Утилиты
│       ├── async_value.dart
│       ├── color_generator.dart
│       ├── date_formatter.dart
│       ├── error_handler.dart
│       ├── exceptions/          # Кастомные исключения
│       ├── http/                # http_abstraction, http_interceptor, http_stub, http_web
│       ├── internal_notification/ # notify_service, toast (toast_event, toast_view_model, toast_view), haptic_feedback
│       ├── locator.dart
│       ├── navigation/          # best_router, navigation_observable, route_data, route_information_parser, router_delegate, router_service, url_strategy
│       └── retry/               # circuit_breaker, retry_policy
│
├── dashboard/                    # Главная панель
│   ├── models/                  # dashboard_alert, dashboard_stats
│   ├── viewmodels/              # dashboard_view_model
│   ├── views/                   # dashboard_view, home_view
│   └── widgets/                 # alerts_list_widget, loading_hours_chart, quick_actions_widget, safe_loading_hours_chart, stat_card, weekly_calendar_widget
│
├── data/                         # Слой данных
│   ├── models/                  # audit_log, branch, employee, position, shift, user_profile, user
│   ├── repositories/            # audit_log_repository, auth_repository, branch_repository, employee_repository, position_repository, shift_repository
│   └── services/                # api_service, mock_api_service, position_service, shift_service, supabase_api_service
│
├── employees_syncfusion/         # Модуль управления сотрудниками
│   ├── models/                  # employee_syncfusion_model, profile_model
│   ├── viewmodels/              # employee_data_source, employee_syncfusion_view_model, profile_view_model, user_approval_view_model
│   ├── views/                   # employee_syncfusion_view, profile_view
│   └── widgets/                 # create_employee_dialog, edit_profile_dialog, employee_card, employee_desktop_grid, employee_filters_dialog, profile_header_card, profile_history_card, user_approval_tab
│
├── not_found/                    # 404 страница
│   ├── not_found_view_model.dart
│   └── not_found_view.dart
│
├── positions/                    # Управление должностями
│   ├── position_view_model.dart
│   ├── position_view.dart
│   └── widgets/                 # create_position_dialog, edit_position_dialog
│
├── schedule/                     # Модуль расписания смен
│   ├── constants/               # filter_presets, schedule_constants, schedule_view_type
│   ├── models/                  # date_range_filter, shift_adapter, shift_model, shift_status_filter
│   ├── utils/                   # employee_sorter, schedule_statistics, shift_conflict_checker, shift_filter
│   ├── viewmodels/              # schedule_view_model, shift_data_source
│   ├── views/                   # mobile_schedule_grid_view, schedule_view
│   └── widgets/                 # desktop_schedule_view, employee_filter_dropdown, filter_chips_bar, mobile_schedule_view, profession_row, role_legend, shift_card, shift_cell, shift_details_dialog, shift_form_datetime_section, shift_form_employee_section, shift_form_location_section, status_filter_dropdown, summary_bar, view_switcher
│
├── startup/                      # Инициализация приложения
│   ├── startup_view_model.dart
│   └── startup_view.dart
│
└── main.dart                     # Точка входа

55 directories, 166 files
```

## База данных

### Схема базы данных (Supabase PostgreSQL)

#### Таблицы:

1. **profiles** - Профили пользователей
   - `id` (UUID, PK) - Связан с auth.users.id
   - `email` (TEXT, UNIQUE)
   - `first_name`, `last_name` (TEXT)
   - `role` (TEXT) - 'employee' или 'manager'
   - `status` (TEXT) - 'active', 'inactive', 'pending'
   - `branch_id` (UUID, FK → branches.id, nullable)
   - `position` (TEXT, nullable)
   - `hourly_rate` (NUMERIC, nullable)
   - `hire_date` (TIMESTAMP, nullable)
   - `avatar_url`, `phone`, `address` (TEXT, nullable)
   - `created_at`, `updated_at` (TIMESTAMP)

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
   - `employee_id` (UUID, FK → profiles.id, nullable)
   - `start_time`, `end_time` (TIMESTAMP)
   - `role_title` (TEXT)
   - `location` (TEXT)
   - `status` (TEXT) - 'confirmed', 'swap_requested', 'pending', 'scheduled', 'vacation', 'sick_leave'
   - `hourly_rate` (NUMERIC)
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
   - `action` (TEXT)
   - `table_name` (TEXT)
   - `record_id` (UUID)
   - `old_data`, `new_data` (JSONB)
   - `created_at` (TIMESTAMP)



## Основные функции

### 1. Авторизация и регистрация
- **Логин**: `/login`
- **Регистрация**: `/register`
- Поддержка ролей: менеджер и сотрудник
- Статус аккаунта: pending (требует одобрения менеджера), active, inactive
- Автоматическое создание профиля при регистрации

### 2. Управление сотрудниками
- **Список**: `/dashboard/employees`
- **Профиль**: `/dashboard/employees/:id`
- CRUD операции через диалоги
- Фильтрация по филиалам, должностям, статусам
- Одобрение регистраций новых пользователей (менеджеры)
- Syncfusion DataGrid с сортировкой и виртуализацией
- Адаптивный дизайн (десктоп/мобильная версия)

### 3. Управление филиалами
- **Страница**: `/dashboard/branches`
- Создание, редактирование, удаление филиалов
- Поле адреса для каждого филиала
- Привязка сотрудников к филиалам

### 4. Управление должностями
- **Страница**: `/dashboard/positions`
- Создание, редактирование, удаление должностей
- Настройка почасовой ставки для каждой должности
- Привязка должностей к сотрудникам

### 5. График смен
- **Страница**: `/dashboard/schedule`
- Визуализация через Syncfusion Calendar
- Drag & Drop для перемещения смен
- Фильтрация по:
  - Сотрудникам
  - Должностям
  - Филиалам
  - Датам (диапазон)
  - Статусу смен (confirmed, pending, scheduled, vacation, sick_leave)
- Детекция конфликтов смен (пересечения)
- Статистика (общее количество часов, сотрудников)
- Адаптивный дизайн (десктоп/мобильная версия)

### 6. Dashboard
- **Главная**: `/dashboard`
- Статистика:
  - Количество сотрудников
  - Активные смены
  - Общее количество часов
- Графики загрузки (Syncfusion Charts)
- Быстрые действия
- Календарь недели

### 7. Журнал аудита
- **Страница**: `/dashboard/audit-logs`
- Отслеживание всех изменений в системе
- Фильтрация по действиям, таблицам, пользователям
- Просмотр изменений (diff старых и новых данных)
- Доступ только для менеджеров

## Роутинг

Роутинг настроен в `lib/config/route_config.dart`. Используется кастомный `BestRouter` (`lib/core/utils/navigation/`) для навигации.

### Публичные маршруты (не требуют авторизации):
- `/` → LoginView
- `/login` → LoginView
- `/register` → RegistrationView
- `/404` → NotFoundView

### Защищенные маршруты (требуют авторизации):
- `/dashboard` → HomeView (Dashboard)
- `/dashboard/employees` → EmployeeSyncfusionView
- `/dashboard/employees/:id` → ProfileView
- `/dashboard/schedule` → ScheduleView
- `/dashboard/branches` → BranchView
- `/dashboard/positions` → PositionView
- `/dashboard/audit-logs` → AuditLogsView (только менеджеры)

Все защищенные маршруты обернуты в `DashboardView`, который предоставляет общий layout с навигацией.

## Разработка

### Соглашения по коду

#### Именование
- **IDs**: Всегда используйте `String` (UUID формат), никогда `int`
- **JSON**: `snake_case` для ключей (например, `user_name`, `hire_date`)
- **Dart**: `camelCase` для свойств классов (например, `userName`, `hireDate`)
- **Классы**: `PascalCase` (например, `TodoService`, `HomeViewModel`)
- **Сериализация**: Все модели должны иметь `fromJson` и `toJson`

#### Организация файлов
Простые фичи (≤5 файлов):
- `{feature_name}/{name}_model.dart`
- `{feature_name}/{name}_view_model.dart`
- `{feature_name}/{name}_view.dart`

Сложные фичи (с поддиректориями):
- `{feature_name}/models/{name}.dart`
- `{feature_name}/viewmodels/{name}_view_model.dart`
- `{feature_name}/views/{name}_view.dart`
- `{feature_name}/widgets/{name}_widget.dart`

### State Management

Выбор подхода в зависимости от сложности:

1. **ValueNotifier<T>** - простые состояния (1-2 независимых состояния)
2. **ChangeNotifier** - средняя сложность (множественные зависимые поля)

Все async операции оборачиваются в `AsyncValue<T>` (см. `lib/core/utils/async_value.dart`).

### Обработка ошибок

- Все async операции обернуты в try-catch
- Централизованная обработка через `ErrorHandler`
- Использование `AsyncValue<T>` для состояний
- Уведомления пользователя через `NotifyService`

### Memory Management

- Все ViewModels ДОЛЖНЫ иметь `dispose()` метод
- Все ValueNotifiers ДОЛЖНЫ быть disposed в `ViewModel.dispose()`
- Views ДОЛЖНЫ вызывать `ViewModel.dispose()` в своем `dispose()`
- Использовать `ValueListenableBuilder` вместо ручных listeners

### UUID Generation

- Все ID генерируются как UUID строки
- Использование пакета `uuid`
- ID генерируются в Repository слое

### Code Style

- Использование `flutter_lints` для проверки кода
- Форматирование через `dart format`
- Комментарии только где необходимо
- Self-documenting code через описательные имена



