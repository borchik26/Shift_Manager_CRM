import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Enum для типов представления календаря
enum ScheduleViewType {
  /// День - детальный вид одного дня с почасовыми слотами (30 мин)
  day,

  /// Неделя - текущий timeline view с ресурсами
  week,

  /// Месяц - обзор месяца с событиями в ячейках
  month;

  /// Локализованное название вида
  String get label {
    switch (this) {
      case ScheduleViewType.day:
        return 'День';
      case ScheduleViewType.week:
        return 'Неделя';
      case ScheduleViewType.month:
        return 'Месяц';
    }
  }

  /// Соответствующий CalendarView из Syncfusion
  CalendarView get calendarView {
    switch (this) {
      case ScheduleViewType.day:
        return CalendarView.timelineDay; // Timeline для консистентности
      case ScheduleViewType.week:
        return CalendarView.timelineWeek;
      case ScheduleViewType.month:
        return CalendarView.month; // Обычный month view
    }
  }

  /// Иконка для UI
  IconData get icon {
    switch (this) {
      case ScheduleViewType.day:
        return Icons.view_day;
      case ScheduleViewType.week:
        return Icons.view_week;
      case ScheduleViewType.month:
        return Icons.calendar_month;
    }
  }
}
