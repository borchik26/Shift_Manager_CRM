import 'package:my_app/data/models/branch.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/models/user.dart';
import 'package:my_app/data/models/user_profile.dart';
import 'package:my_app/data/models/position.dart';
import 'package:my_app/data/models/audit_log.dart';
import 'package:my_app/audit_logs/models/audit_log_filter.dart';

/// Abstract interface for API service
/// All data access should go through this interface
abstract class ApiService {
  // Authentication
  Future<User?> login(String username, String password);
  Future<User?> register(String email, String password, String firstName, String lastName, String role);
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

  // Branches
  Future<List<Branch>> getBranches();
  Future<Branch?> getBranchById(String id);
  Future<Branch> createBranch(Branch branch);
  Future<Branch> updateBranch(Branch branch);
  Future<void> deleteBranch(String id);

  // Positions
  Future<List<Position>> getPositions();
  Future<Position?> getPositionById(String id);
  Future<Position> createPosition(Position position);
  Future<Position> updatePosition(Position position);
  Future<void> deletePosition(String id);

  // User Profiles (from 'profiles' table)
  Future<List<UserProfile>> getAllProfiles();
  Future<UserProfile?> getProfileById(String id);
  Future<void> updateUserStatus(String userId, String newStatus);
  Future<void> deleteUserProfile(String userId);

  // Filter options / Reference data
  Future<List<String>> getAvailableBranches();
  Future<List<String>> getAvailableRoles();
  Future<List<String>> getAvailableUserRoles();

  // Audit Logs
  Future<List<AuditLog>> getAuditLogs({
    int limit = 500,
    int offset = 0,
    AuditLogFilter? filter,
  });
  Future<void> deleteAllAuditLogs();
}
