/// Enum для фильтрации смен по статусу
enum ShiftStatusFilter {
  /// Все смены без фильтрации
  all('Все'),

  /// Только смены с конфликтами (hard errors)
  withConflicts('С конфликтами'),

  /// Только смены с предупреждениями (warnings)
  withWarnings('С предупреждениями'),

  /// Только обычные смены (без конфликтов и предупреждений)
  normal('Обычные');

  const ShiftStatusFilter(this.label);

  /// Отображаемое название фильтра
  final String label;
}
