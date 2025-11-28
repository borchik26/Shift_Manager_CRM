import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/models/user.dart';
import 'package:my_app/data/services/api_service.dart';

/// Mock implementation of ApiService for development
/// All hardcoded data resides here as per architecture rules
class MockApiService implements ApiService {
  // Simulated delay for realistic API behavior
  static const _delay = Duration(milliseconds: 800);

  // Mock data storage
  final List<Employee> _employees = [];
  final List<Shift> _shifts = [];
  User? _currentUser;

  MockApiService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Generate 50 mock employees
    final branches = ['Москва', 'Санкт-Петербург', 'Казань', 'Новосибирск'];
    final positions = ['Менеджер', 'Администратор', 'Специалист', 'Директор'];
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
      'Владимир'
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
      'Новиков'
    ];

    for (int i = 0; i < 50; i++) {
      _employees.add(Employee(
        id: 'emp_${i + 1}',
        firstName: firstNames[i % firstNames.length],
        lastName: lastNames[i % lastNames.length],
        position: positions[i % positions.length],
        branch: branches[i % branches.length],
        status: statuses[i % statuses.length],
        hireDate: DateTime.now().subtract(Duration(days: 365 * (i % 5))),
        email: 'employee${i + 1}@company.com',
        phone: '+7 (900) ${100 + i}-${10 + i}-${20 + i}',
      ));
    }

    // Generate 20 mock shifts
    final now = DateTime.now();
    for (int i = 0; i < 20; i++) {
      final startDate = now.add(Duration(days: i % 7));
      final startTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        9 + (i % 3) * 4,
      );
      final endTime = startTime.add(Duration(hours: 8));

      _shifts.add(Shift(
        id: 'shift_${i + 1}',
        employeeId: _employees[i % _employees.length].id,
        startTime: startTime,
        endTime: endTime,
        status: i % 5 == 0 ? 'pending' : 'confirmed',
        isNightShift: startTime.hour >= 20 || startTime.hour < 6,
        notes: i % 3 == 0 ? 'Важная смена' : null,
      ));
    }
  }

  @override
  Future<User?> login(String username, String password) async {
    await Future.delayed(_delay);

    // Simple mock authentication
    if (username == 'admin' && password == 'admin') {
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
  Future<List<Shift>> getShifts({DateTime? startDate, DateTime? endDate}) async {
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
}