# 👤 Profile Screen - TimelineTile + PercentIndicator Implementation Guide

## 🎯 Задача
Реализовать экран "Профиль сотрудника" с использованием специализированных пакетов для визуализации истории и прогресса.

---

## 📚 Входные данные

### 1. Референс UI
- **Файл**: `Profil-sotrudnika.jpeg`
- **Стиль**: Clean SaaS (белые карточки, тени, скругления 12px)
- **Layout**: Адаптивный (Grid на Desktop, Column на Mobile)

### 2. Пакеты
- **timeline_tile**: https://pub.dev/packages/timeline_tile
- **percent_indicator**: https://pub.dev/packages/percent_indicator

### 3. Архитектура
- **Pattern**: MVVM
- **State Management**: ValueNotifier<AsyncValue<T>> (Simple Screen - single async operation)

---

## 🏗️ Архитектура (MVVM)

### 1. Model (`lib/employees/models/profile_model.dart`)

```dart
class HistoryEvent {
  final DateTime date;
  final String title;
  final String description;

  const HistoryEvent({
    required this.date,
    required this.title,
    required this.description,
  });

  factory HistoryEvent.mock(int index) {
    final now = DateTime.now();
    final events = [
      {
        'date': now.subtract(const Duration(days: 1)),
        'title': 'Смена завершена',
        'description': 'Дневная смена 09:00-18:00 в ТЦ Мега',
      },
      {
        'date': now.subtract(const Duration(days: 3)),
        'title': 'Повышение',
        'description': 'Назначен старшим администратором',
      },
      {
        'date': now.subtract(const Duration(days: 7)),
        'title': 'Обучение пройдено',
        'description': 'Курс "Управление конфликтами"',
      },
      {
        'date': now.subtract(const Duration(days: 30)),
        'title': 'Принят на работу',
        'description': 'Должность: Администратор',
      },
    ];

    final event = events[index % events.length];
    return HistoryEvent(
      date: event['date'] as DateTime,
      title: event['title'] as String,
      description: event['description'] as String,
    );
  }
}

class EmployeeProfile {
  final String id;
  final String name;
  final String role;
  final String avatarUrl;
  final String email;
  final String phone;
  final String address;
  final String branch;
  final DateTime hireDate;
  final List<HistoryEvent> history;
  final double workedHours;
  final double totalHours;

  const EmployeeProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.email,
    required this.phone,
    required this.address,
    required this.branch,
    required this.hireDate,
    required this.history,
    required this.workedHours,
    required this.totalHours,
  });

  double get hoursPercent => workedHours / totalHours;

  factory EmployeeProfile.mock(String id) {
    return EmployeeProfile(
      id: id,
      name: 'Иван Петров',
      role: 'Старший администратор',
      avatarUrl: 'https://i.pravatar.cc/150?u=$id',
      email: 'ivan.petrov@company.com',
      phone: '+7 (999) 123-45-67',
      address: 'г. Москва, ул. Ленина, д. 10',
      branch: 'ТЦ Мега',
      hireDate: DateTime.now().subtract(const Duration(days: 365)),
      history: List.generate(4, (index) => HistoryEvent.mock(index)),
      workedHours: 128,
      totalHours: 160,
    );
  }
}
```

---

### 2. ViewModel (`lib/employees/viewmodels/profile_view_model.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/employees/models/profile_model.dart';

class ProfileViewModel {
  // Simple Screen: используем ValueNotifier<AsyncValue<T>>
  final profileState = ValueNotifier<AsyncValue<EmployeeProfile>>(
    const AsyncLoading(),
  );

  /// Загрузка профиля сотрудника (Mock)
  Future<void> loadProfile(String employeeId) async {
    profileState.value = const AsyncLoading();

    try {
      // Имитация сетевого запроса
      await Future.delayed(const Duration(seconds: 1));

      // Генерация моковых данных
      final profile = EmployeeProfile.mock(employeeId);
      profileState.value = AsyncData(profile);
    } catch (e) {
      profileState.value = AsyncError('Ошибка загрузки профиля: ${e.toString()}');
    }
  }

  /// Очистка профиля
  void clearProfile() {
    profileState.value = const AsyncLoading();
  }

  void dispose() {
    profileState.dispose();
  }
}
```

---

### 3. View (`lib/employees/views/profile_view.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/employees/viewmodels/profile_view_model.dart';
import 'package:my_app/employees/models/profile_model.dart';

class ProfileView extends StatefulWidget {
  final String employeeId;

  const ProfileView({
    super.key,
    required this.employeeId,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _viewModel.loadProfile(widget.employeeId);
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
        title: const Text('Профиль сотрудника'),
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
      body: ValueListenableBuilder<AsyncValue<EmployeeProfile>>(
        valueListenable: _viewModel.profileState,
        builder: (context, state, child) {
          return state.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            data: (profile) => _buildProfileContent(context, profile),
            error: (error) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, EmployeeProfile profile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: isDesktop
              ? _buildDesktopLayout(profile)
              : _buildMobileLayout(profile),
        );
      },
    );
  }

  Widget _buildDesktopLayout(EmployeeProfile profile) {
    return Column(
      children: [
        // Header Card (полная ширина)
        _buildHeaderCard(profile),
        const SizedBox(height: 16),
        
        // Grid с двумя колонками
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Левая колонка
            Expanded(
              child: Column(
                children: [
                  _buildInfoCard(profile),
                  const SizedBox(height: 16),
                  _buildTimeCard(profile),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Правая колонка
            Expanded(
              child: _buildHistoryCard(profile),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(EmployeeProfile profile) {
    return Column(
      children: [
        _buildHeaderCard(profile),
        const SizedBox(height: 16),
        _buildInfoCard(profile),
        const SizedBox(height: 16),
        _buildTimeCard(profile),
        const SizedBox(height: 16),
        _buildHistoryCard(profile),
      ],
    );
  }

  Widget _buildHeaderCard(EmployeeProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Аватар
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(profile.avatarUrl),
              onBackgroundImageError: (_, __) {},
              child: const Icon(Icons.person, size: 40),
            ),
            const SizedBox(width: 24),
            
            // Информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.role,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      profile.branch,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Кнопка редактирования
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Редактирование профиля
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Редактировать'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(EmployeeProfile profile) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Контактная информация',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email_outlined, 'Email', profile.email),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone_outlined, 'Телефон', profile.phone),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, 'Адрес', profile.address),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Дата приема',
              dateFormat.format(profile.hireDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCard(EmployeeProfile profile) {
    final percent = profile.hoursPercent;
    final percentText = '${(percent * 100).toInt()}%';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Учет времени',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Отработано: ${profile.workedHours.toInt()} из ${profile.totalHours.toInt()} ч',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            LinearPercentIndicator(
              lineHeight: 12.0,
              percent: percent.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              progressColor: Colors.blue,
              barRadius: const Radius.circular(6),
              animation: true,
              animationDuration: 1000,
              center: Text(
                percentText,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(EmployeeProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: profile.history.length,
              itemBuilder: (context, index) {
                final event = profile.history[index];
                final isFirst = index == 0;
                final isLast = index == profile.history.length - 1;

                return TimelineTile(
                  alignment: TimelineAlign.start,
                  isFirst: isFirst,
                  isLast: isLast,
                  indicatorStyle: IndicatorStyle(
                    width: 20,
                    height: 20,
                    indicator: Container(
                      decoration: BoxDecoration(
                        color: isFirst ? Colors.blue : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  beforeLineStyle: LineStyle(
                    color: Colors.grey.shade300,
                    thickness: 2,
                  ),
                  endChild: Container(
                    padding: const EdgeInsets.only(
                      left: 16,
                      bottom: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMMM yyyy', 'ru').format(event.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📝 Checklist для реализации

### Подготовка:
- [ ] Добавить `timeline_tile` и `percent_indicator` в `pubspec.yaml`
- [ ] Добавить `intl` для форматирования дат
- [ ] Создать папку `lib/employees/` с подпапками (models, viewmodels, views)
- [ ] Убедиться, что `async_value.dart` создан в `lib/core/utils/`

### Реализация:
- [ ] Создать `profile_model.dart` с `EmployeeProfile` и `HistoryEvent`
- [ ] Создать `profile_view_model.dart` с `ValueNotifier<AsyncValue<T>>`
- [ ] Создать `profile_view.dart` с `ValueListenableBuilder`
- [ ] Реализовать Header Card с аватаром и кнопкой
- [ ] Реализовать Info Card с контактами
- [ ] Реализовать Time Card с `LinearPercentIndicator`
- [ ] Реализовать History Card с `TimelineTile`

### Стилизация:
- [ ] Карточки: белые, тень, скругление 12px
- [ ] Адаптивный layout (Desktop: Grid, Mobile: Column)
- [ ] Timeline: синий индикатор для первого, серый для остальных
- [ ] Progress bar: синий, высота 12px, анимация

---

## 🎯 Ожидаемый результат

### Функциональность:
- ✅ Загрузка профиля с задержкой 1 сек
- ✅ Адаптивный layout (Desktop/Mobile)
- ✅ Timeline с историей событий
- ✅ Progress bar с процентом отработанных часов
- ✅ Контактная информация
- ✅ Кнопка редактирования

### UI особенности:
- ✅ Clean SaaS стиль
- ✅ Белые карточки с тенями
- ✅ Скругления 12px
- ✅ Анимированный progress bar
- ✅ Цветные индикаторы в timeline

---

**Последнее обновление**: 2025-11-28  
**Статус**: Готов к реализации  
**Время реализации**: 3-4 часа