import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/models/user.dart';
import 'package:my_app/data/services/api_service.dart';

/// Mock implementation of ApiService for development
/// All hardcoded data resides here as per architecture rules
class MockApiService implements ApiService {
  // Simulated delay for realistic API behavior
  static const _delay = Duration(milliseconds: 800);

  // Reference data constants (будут заменены на API calls в production)
  static const List<String> _availableBranches = [
    'ТЦ Мега',
    'Центр',
    'Аэропорт',
  ];
  static const List<String> _availableRoles = [
    'Уборщица',
    'Кассир',
    'Повар',
    'Менеджер',
  ];

  // Hourly rates by position (in rubles)
  static const Map<String, double> _hourlyRates = {
    'Уборщица': 250.0,
    'Кассир': 400.0,
    'Повар': 600.0,
    'Менеджер': 840.0,
  };

  // Mock data storage
  final List<Employee> _employees = [];
  final List<Shift> _shifts = [];
  User? _currentUser;

  MockApiService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Generate 50 mock employees with mix of men and women
    final branches = _availableBranches;
    final positions = _availableRoles;
    final statuses = ['active', 'vacation', 'sick_leave'];

    // Male names
    final maleFirstNames = [
      'Александр',
      'Дмитрий',
      'Максим',
      'Иван',
      'Михаил',
      'Андрей',
      'Сергей',
      'Алексей',
      'Артём',
      'Владимир',
    ];

    // Female names
    final femaleFirstNames = [
      'Анна',
      'Мария',
      'Елена',
      'Ольга',
      'Наталья',
      'Татьяна',
      'Ирина',
      'Светлана',
      'Екатерина',
      'Юлия',
    ];

    final lastNames = [
      'Иванов',
      'Петров',
      'Сидоров',
      'Смирнов',
      'Кузнецов',
      'Попов',
      'Васильев',
      'Соколов',
      'Михайлов',
      'Новиков',
    ];

    for (int i = 0; i < 50; i++) {
      // Alternate between male and female
      final isMale = i % 2 == 0;

      final firstName = isMale
          ? maleFirstNames[i % maleFirstNames.length]
          : femaleFirstNames[i % femaleFirstNames.length];

      // Backend-ready: Use UI Avatars as fallback (works offline)
      // Format: https://ui-avatars.com/api/?name=Имя+Фамилия&size=150&background=random
      final name = '$firstName ${lastNames[i % lastNames.length]}';
      final avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&size=150&background=${_getColorForIndex(i)}&color=fff';

      _employees.add(
        Employee(
          id: 'emp_${i + 1}',
          firstName: firstName,
          lastName: lastNames[i % lastNames.length],
          position: positions[i % positions.length],
          branch: branches[i % branches.length],
          status: statuses[i % statuses.length],
          hireDate: DateTime.now().subtract(Duration(days: 365 * (i % 5))),
          email: 'employee${i + 1}@company.com',
          phone: '+7 (900) ${100 + i}-${10 + i}-${20 + i}',
          avatarUrl: avatarUrl,
        ),
      );
    }

    // Generate shifts for each employee (15-31 shifts per employee for current month)
    final now = DateTime.now();
    int shiftCounter = 0;

    for (var employee in _employees) {
      // Generate 15-31 shifts for each employee (realistic monthly schedule)
      final shiftsCount = 15 + (employee.id.hashCode.abs() % 17); // 15 to 31 shifts

      for (int i = 0; i < shiftsCount; i++) {
        // Distribute shifts over the current month only
        final daysAgo = shiftsCount - i;
        final shiftDate = now.subtract(Duration(days: daysAgo));

        // Skip if shift is not in current month
        if (shiftDate.month != now.month || shiftDate.year != now.year) {
          continue;
        }

        // Different start times (morning/day/evening/night)
        final startHour = _getShiftStartHour(employee.id, i);
        final startTime = DateTime(
          shiftDate.year,
          shiftDate.month,
          shiftDate.day,
          startHour,
          0,
        );

        // Different durations (6-12 hours)
        final duration = _getShiftDuration(employee.id, i);
        final endTime = startTime.add(Duration(hours: duration));

        // Different locations
        final location =
            _availableBranches[(employee.id.hashCode.abs() + i) % _availableBranches.length];

        shiftCounter++;
        _shifts.add(
          Shift(
            id: 'shift_$shiftCounter',
            employeeId: employee.id,
            location: location,
            startTime: startTime,
            endTime: endTime,
            status: i % 10 == 0 ? 'pending' : 'confirmed',
            isNightShift: startHour >= 20 || startHour < 6,
            notes: i % 15 == 0 ? 'Важная смена' : null,
          ),
        );
      }
    }
  }

  // Helper method to get varied shift start hours
  int _getShiftStartHour(String employeeId, int shiftIndex) {
    final patterns = [9, 12, 14, 18, 20, 22]; // Morning, day, evening, night
    final hash = (employeeId.hashCode.abs() + shiftIndex) % patterns.length;
    return patterns[hash];
  }

  // Helper method to get varied shift durations
  int _getShiftDuration(String employeeId, int shiftIndex) {
    final durations = [6, 8, 10, 12]; // 6-12 hours
    final hash = (employeeId.hashCode.abs() + shiftIndex * 2) % durations.length;
    return durations[hash];
  }

  // Helper method to get varied background colors for avatars
  static String _getColorForIndex(int index) {
    final colors = [
      '0D8ABC', '3DA5D9', '2E7EAA', '0E4C92', '1F77B4',
      '2CA02C', '98DF8A', '17BECF', '9467BD', 'E377C2',
      'FF7F0E', 'FFBB78', 'D62728', 'FF9896', '8C564B',
    ];
    return colors[index % colors.length];
  }

  @override
  Future<User?> login(String username, String password) async {
    await Future.delayed(_delay);

    // Simple mock authentication
    if ((username == 'admin' || username == 'admin@example.com') &&
        (password == 'admin' || password == 'password123')) {
      _currentUser = const User(
        id: 'user_1',
        username: 'admin',
        role: 'administrator',
      );
      return _currentUser;
    }

    return null;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(_delay);
    _currentUser = null;
  }

  @override
  Future<List<Employee>> getEmployees() async {
    await Future.delayed(_delay);
    return List.unmodifiable(_employees);
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    await Future.delayed(_delay);
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Employee> createEmployee(Employee employee) async {
    await Future.delayed(_delay);
    _employees.add(employee);
    return employee;
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    await Future.delayed(_delay);
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      _employees[index] = employee;
    }
    return employee;
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await Future.delayed(_delay);
    _employees.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<Shift>> getShifts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(_delay);

    if (startDate == null && endDate == null) {
      return List.unmodifiable(_shifts);
    }

    return _shifts.where((shift) {
      if (startDate != null && shift.startTime.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && shift.endTime.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<Shift>> getShiftsByEmployee(String employeeId) async {
    await Future.delayed(_delay);
    return _shifts.where((s) => s.employeeId == employeeId).toList();
  }

  @override
  Future<Shift?> getShiftById(String id) async {
    await Future.delayed(_delay);
    try {
      return _shifts.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Shift> createShift(Shift shift) async {
    await Future.delayed(_delay);
    _shifts.add(shift);
    return shift;
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    await Future.delayed(_delay);
    final index = _shifts.indexWhere((s) => s.id == shift.id);
    if (index != -1) {
      _shifts[index] = shift;
    }
    return shift;
  }

  @override
  Future<void> deleteShift(String id) async {
    await Future.delayed(_delay);
    _shifts.removeWhere((s) => s.id == id);
  }

  @override
  Future<List<String>> getAvailableBranches() async {
    await Future.delayed(_delay);
    return List.from(_availableBranches);
  }

  @override
  Future<List<String>> getAvailableRoles() async {
    await Future.delayed(_delay);
    return List.from(_availableRoles);
  }

  /// Get hourly rate for a position
  static double getHourlyRate(String position) {
    return _hourlyRates[position] ?? 400.0; // Default to Кассир rate
  }

  /// Get all hourly rates
  static Map<String, double> getAllHourlyRates() {
    return Map.from(_hourlyRates);
  }
}
