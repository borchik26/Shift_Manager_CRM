import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/services/api_service.dart';

/// Repository for employee operations
/// ViewModels should use this instead of calling ApiService directly
class EmployeeRepository {
  final ApiService _apiService;

  EmployeeRepository({required ApiService apiService})
    : _apiService = apiService;

  Future<List<Employee>> getEmployees() {
    return _apiService.getEmployees();
  }

  Future<Employee?> getEmployeeById(String id) {
    return _apiService.getEmployeeById(id);
  }

  Future<Employee> createEmployee(Employee employee) {
    return _apiService.createEmployee(employee);
  }

  Future<Employee> updateEmployee(Employee employee) {
    return _apiService.updateEmployee(employee);
  }

  Future<void> deleteEmployee(String id) {
    return _apiService.deleteEmployee(id);
  }

  Future<List<String>> getAvailableBranches() {
    return _apiService.getAvailableBranches();
  }

  Future<List<String>> getAvailableRoles() {
    return _apiService.getAvailableRoles();
  }
}
