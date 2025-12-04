import 'package:flutter/material.dart';
import 'package:my_app/core/ui/constants/kit_colors.dart';

enum EmployeeStatus {
  onShift,
  dayOff,
  vacation;

  String get displayName {
    switch (this) {
      case EmployeeStatus.onShift:
        return 'На смене';
      case EmployeeStatus.dayOff:
        return 'Выходной';
      case EmployeeStatus.vacation:
        return 'Отпуск';
    }
  }

  Color get color {
    switch (this) {
      case EmployeeStatus.onShift:
        return KitColors.green600; // Ярко-зеленый
      case EmployeeStatus.dayOff:
        return KitColors.gray500; // Серый
      case EmployeeStatus.vacation:
        return KitColors.yellow500; // Желтый/Янтарный
    }
  }
}

class EmployeeSyncfusionModel {
  final String id;
  final String name;
  final String role;
  final String branch;
  final EmployeeStatus status;
  final int workedHours;
  final String avatarUrl;

  const EmployeeSyncfusionModel({
    required this.id,
    required this.name,
    required this.role,
    required this.branch,
    required this.status,
    required this.workedHours,
    required this.avatarUrl,
  });

  // Генерация моковых данных
  factory EmployeeSyncfusionModel.mock(int index) {
    final names = [
      'Иван Петров',
      'Мария Сидорова',
      'Алексей Иванов',
      'Елена Смирнова',
      'Дмитрий Козлов',
      'Анна Новикова',
      'Сергей Морозов',
      'Ольга Волкова',
      'Андрей Соколов',
      'Татьяна Лебедева',
      'Николай Егоров',
      'Екатерина Павлова',
      'Владимир Семенов',
      'Наталья Федорова',
      'Михаил Голубев',
      'Светлана Виноградова',
    ];

    final roles = [
      'Менеджер',
      'Кассир',
      'Администратор',
      'Продавец-консультант',
      'Старший продавец',
      'Охранник',
      'Уборщик',
      'Товаровед',
    ];

    final branches = ['ТЦ Мега', 'Центр', 'Аэропорт'];

    final statuses = EmployeeStatus.values;

    // Используем такой же формат ID, как и в MockApiService, чтобы профиль
    // можно было загрузить по маршруту `/dashboard/employees/:id`.
    final id = 'emp_${index + 1}';

    return EmployeeSyncfusionModel(
      id: id,
      name: names[index % names.length],
      role: roles[index % roles.length],
      branch: branches[index % branches.length],
      status: statuses[index % statuses.length],
      workedHours: 120 + (index * 7) % 80,
      avatarUrl: 'https://i.pravatar.cc/150?u=$id',
    );
  }

  // Генерация списка из 50 сотрудников
  static List<EmployeeSyncfusionModel> generateMockList() {
    return List.generate(50, (index) => EmployeeSyncfusionModel.mock(index));
  }
}
