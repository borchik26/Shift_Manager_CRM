/// Enum для фильтрации смен по периоду времени
enum DateRangeFilter {
  /// Все смены без фильтрации по дате
  all('Все', null),

  /// Смены только за сегодня
  today('Сегодня', Duration(days: 1)),

  /// Смены за текущую неделю
  week('Эта неделя', Duration(days: 7)),

  /// Смены за текущий месяц
  month('Этот месяц', Duration(days: 30));

  const DateRangeFilter(this.label, this.duration);

  /// Отображаемое название фильтра
  final String label;

  /// Длительность периода относительно текущей даты
  final Duration? duration;

  /// Вычисляет начальную дату для фильтрации
  DateTime? getStartDate() {
    if (duration == null) return null;

    final now = DateTime.now();

    switch (this) {
      case DateRangeFilter.today:
        return DateTime(now.year, now.month, now.day);
      case DateRangeFilter.week:
        // Начало недели (понедельник)
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekday - 1));
      case DateRangeFilter.month:
        // Начало месяца
        return DateTime(now.year, now.month, 1);
      case DateRangeFilter.all:
        return null;
    }
  }

  /// Вычисляет конечную дату для фильтрации
  DateTime? getEndDate() {
    if (duration == null) return null;

    final now = DateTime.now();

    switch (this) {
      case DateRangeFilter.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case DateRangeFilter.week:
        // Конец недели (воскресенье)
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day)
            .add(Duration(days: 7 - weekday, hours: 23, minutes: 59, seconds: 59));
      case DateRangeFilter.month:
        // Конец месяца
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case DateRangeFilter.all:
        return null;
    }
  }
}
