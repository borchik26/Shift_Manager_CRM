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
    'Менеджер',
    'Кассир',
    'Администратор',
    'Продавец-консультант',
    'Старший продавец',
    'Охранник',
    'Уборщик',
    'Товаровед',
  ];

  // Mock data storage
  final List<Employee> _employees = [];
  final List<Shift> _shifts = [];
  User? _currentUser;

  MockApiService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Generate 50 mock employees
    final branches = _availableBranches;
    final positions = _availableRoles;
    final statuses = ['active', 'vacation', 'sick_leave'];
    final firstNames = [
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
      _employees.add(
        Employee(
          id: 'emp_${i + 1}',
          firstName: firstNames[i % firstNames.length],
          lastName: lastNames[i % lastNames.length],
          position: positions[i % positions.length],
          branch: branches[i % branches.length],
          status: statuses[i % statuses.length],
          hireDate: DateTime.now().subtract(Duration(days: 365 * (i % 5))),
          email: 'employee${i + 1}@company.com',
          phone: '+7 (900) ${100 + i}-${10 + i}-${20 + i}',
          avatarUrl: 'https://i.pravatar.cc/150?u=emp_${i + 1}',
        ),
      );
    }

    // Generate shifts for each employee (20-30 shifts per employee for last month)
    final now = DateTime.now();
    int shiftCounter = 0;

    for (var employee in _employees) {
      // Generate 30-50 shifts for each employee
      final shiftsCount = 30 + (employee.id.hashCode.abs() % 21);

      for (int i = 0; i < shiftsCount; i++) {
        // Distribute shifts over the last month
        final daysAgo = shiftsCount - i;
        final shiftDate = now.subtract(Duration(days: daysAgo));

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
}
