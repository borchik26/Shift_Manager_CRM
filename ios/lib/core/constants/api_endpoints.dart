/// API endpoints for future backend integration
class ApiEndpoints {
  // Base URL (will be configured for production)
  static const String baseUrl = 'https://api.shiftmanager.com';
  static const String apiVersion = 'v1';
  
  static String get apiBase => '$baseUrl/$apiVersion';

  // Authentication
  static String get login => '$apiBase/auth/login';
  static String get logout => '$apiBase/auth/logout';
  static String get refreshToken => '$apiBase/auth/refresh';

  // Employees
  static String get employees => '$apiBase/employees';
  static String employeeById(String id) => '$apiBase/employees/$id';
  static String get createEmployee => '$apiBase/employees';
  static String updateEmployee(String id) => '$apiBase/employees/$id';
  static String deleteEmployee(String id) => '$apiBase/employees/$id';

  // Shifts
  static String get shifts => '$apiBase/shifts';
  static String shiftById(String id) => '$apiBase/shifts/$id';
  static String get createShift => '$apiBase/shifts';
  static String updateShift(String id) => '$apiBase/shifts/$id';
  static String deleteShift(String id) => '$apiBase/shifts/$id';
  static String shiftsByEmployee(String employeeId) => 
      '$apiBase/shifts?employee_id=$employeeId';
  static String shiftsByDateRange(DateTime start, DateTime end) =>
      '$apiBase/shifts?start=${start.toIso8601String()}&end=${end.toIso8601String()}';

  // Schedule
  static String get schedule => '$apiBase/schedule';
  static String scheduleByMonth(int year, int month) =>
      '$apiBase/schedule?year=$year&month=$month';

  // Notifications
  static String get notifications => '$apiBase/notifications';
  static String notificationById(String id) => '$apiBase/notifications/$id';
  static String markNotificationRead(String id) =>
      '$apiBase/notifications/$id/read';

  // User profile
  static String get profile => '$apiBase/profile';
  static String get updateProfile => '$apiBase/profile';
}