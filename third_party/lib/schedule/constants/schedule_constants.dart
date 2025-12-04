/// Constants used across the schedule feature
class ScheduleConstants {
  ScheduleConstants._();

  /// Available employee roles
  /// Must match MockApiService._availableRoles and ShiftModel.getColorForRole
  static const List<String> roles = [
    'Уборщица',
    'Кассир',
    'Повар',
    'Менеджер',
  ];

  /// Available branch locations
  static const List<String> branches = [
    'ТЦ Мега',
    'Центр',
    'Аэропорт',
  ];
}
