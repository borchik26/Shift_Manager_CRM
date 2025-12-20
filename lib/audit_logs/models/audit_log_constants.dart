/// Constants for audit log action types
/// These must match the CHECK constraint in the database
class AuditLogActionType {
  static const String create = 'create';
  static const String update = 'update';
  static const String delete = 'delete';
  static const String login = 'login';
  static const String logout = 'logout';
  static const String register = 'register';
  static const String approve = 'approve';
  static const String reject = 'reject';
  static const String statusChange = 'status_change';

  /// All available action types
  static const List<String> values = [
    create,
    update,
    delete,
    login,
    logout,
    register,
    approve,
    reject,
    statusChange,
  ];

  /// Get human-readable label for action type
  static String getLabel(String actionType) {
    switch (actionType) {
      case create:
        return 'Создание';
      case update:
        return 'Обновление';
      case delete:
        return 'Удаление';
      case login:
        return 'Вход';
      case logout:
        return 'Выход';
      case register:
        return 'Регистрация';
      case approve:
        return 'Одобрение';
      case reject:
        return 'Отклонение';
      case statusChange:
        return 'Смена статуса';
      default:
        return actionType;
    }
  }
}

/// Constants for audit log entity types
/// These must match the CHECK constraint in the database
class AuditLogEntityType {
  static const String shift = 'shift';
  static const String employee = 'employee';
  static const String branch = 'branch';
  static const String position = 'position';
  static const String user = 'user';
  static const String auth = 'auth';

  /// All available entity types
  static const List<String> values = [
    shift,
    employee,
    branch,
    position,
    user,
    auth,
  ];

  /// Get human-readable label for entity type
  static String getLabel(String entityType) {
    switch (entityType) {
      case shift:
        return 'Смена';
      case employee:
        return 'Сотрудник';
      case branch:
        return 'Филиал';
      case position:
        return 'Должность';
      case user:
        return 'Пользователь';
      case auth:
        return 'Аутентификация';
      default:
        return entityType;
    }
  }
}

/// Constants for audit log status
class AuditLogStatus {
  static const String success = 'success';
  static const String failed = 'failed';

  static const List<String> values = [
    success,
    failed,
  ];

  static String getLabel(String status) {
    switch (status) {
      case success:
        return 'Успешно';
      case failed:
        return 'Ошибка';
      default:
        return status;
    }
  }
}
