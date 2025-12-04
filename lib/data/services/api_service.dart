import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/models/user.dart';

/// Abstract interface for API service
/// All data access should go through this interface
abstract class ApiService {
  // Authentication
  Future<User?> login(String username, String password);
  Future<void> logout();

  // Employees
  Future<List<Employee>> getEmployees();
  Future<Employee?> getEmployeeById(String id);
  Future<Employee> createEmployee(Employee employee);
  Future<Employee> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String id);

  // Shifts
  Future<List<Shift>> getShifts({DateTime? startDate, DateTime? endDate});
  Future<List<Shift>> getShiftsByEmployee(String employeeId);
  Future<Shift?> getShiftById(String id);
  Future<Shift> createShift(Shift shift);
  Future<Shift> updateShift(Shift shift);
  Future<void> deleteShift(String id);

  // Filter options / Reference data
  Future<List<String>> getAvailableBranches();
  Future<List<String>> getAvailableRoles();
}
