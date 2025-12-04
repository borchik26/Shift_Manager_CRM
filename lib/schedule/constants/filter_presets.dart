import 'package:flutter/material.dart';

/// Быстрые пресеты фильтров для удобного доступа
class FilterPreset {
  const FilterPreset({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

/// Список доступных быстрых пресетов
class FilterPresets {
  static const today = FilterPreset(
    id: 'today',
    label: 'Сегодня',
    icon: Icons.today,
  );

  static const myShifts = FilterPreset(
    id: 'my_shifts',
    label: 'Мои смены',
    icon: Icons.person,
  );

  static const withConflicts = FilterPreset(
    id: 'with_conflicts',
    label: 'С конфликтами',
    icon: Icons.warning,
  );

  static const unassigned = FilterPreset(
    id: 'unassigned',
    label: 'Незаполненные',
    icon: Icons.event_busy,
  );

  /// Все доступные пресеты в порядке отображения
  static const List<FilterPreset> all = [
    today,
    myShifts,
    withConflicts,
    unassigned,
  ];
}
