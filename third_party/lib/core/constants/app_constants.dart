/// Application-wide constants
class AppConstants {
  // Employee statuses
  static const String employeeStatusActive = 'active';
  static const String employeeStatusVacation = 'vacation';
  static const String employeeStatusSickLeave = 'sick_leave';

  // Shift statuses
  static const String shiftStatusPending = 'pending';
  static const String shiftStatusConfirmed = 'confirmed';
  static const String shiftStatusCancelled = 'cancelled';

  // User roles
  static const String roleAdministrator = 'administrator';
  static const String roleManager = 'manager';
  static const String roleEmployee = 'employee';

  // Default credentials (for mock auth)
  static const String defaultUsername = 'admin';
  static const String defaultPassword = 'admin';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration mockApiDelay = Duration(milliseconds: 800);

  // Date/Time
  static const int workingHoursPerDay = 8;
  static const int workingDaysPerWeek = 5;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 100;
  static const int minShiftDurationMinutes = 30;
  static const int maxShiftDurationHours = 24;
}

/// Employee status helper
class EmployeeStatus {
  static const active = AppConstants.employeeStatusActive;
  static const vacation = AppConstants.employeeStatusVacation;
  static const sickLeave = AppConstants.employeeStatusSickLeave;

  static List<String> get all => [active, vacation, sickLeave];

  static String getLabel(String status) {
    switch (status) {
      case active:
        return 'Active';
      case vacation:
        return 'On Vacation';
      case sickLeave:
        return 'Sick Leave';
      default:
        return status;
    }
  }
}

/// Shift status helper
class ShiftStatus {
  static const pending = AppConstants.shiftStatusPending;
  static const confirmed = AppConstants.shiftStatusConfirmed;
  static const cancelled = AppConstants.shiftStatusCancelled;

  static List<String> get all => [pending, confirmed, cancelled];

  static String getLabel(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case confirmed:
        return 'Confirmed';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }
}

/// User role helper
class UserRole {
  static const administrator = AppConstants.roleAdministrator;
  static const manager = AppConstants.roleManager;
  static const employee = AppConstants.roleEmployee;

  static List<String> get all => [administrator, manager, employee];

  static String getLabel(String role) {
    switch (role) {
      case administrator:
        return 'Administrator';
      case manager:
        return 'Manager';
      case employee:
        return 'Employee';
      default:
        return role;
    }
  }
}