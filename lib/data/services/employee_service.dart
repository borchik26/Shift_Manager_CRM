import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/services/base_supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeService extends BaseSupabaseService<Employee> {
  @override
  String get tableName => 'profiles';

  @override
  Employee fromJson(Map<String, dynamic> json) {
    final fullName = json['full_name'] as String;
    final nameParts = fullName.split(' ');

    return Employee(
      id: json['id'] as String,
      firstName: nameParts.isNotEmpty ? nameParts[0] : 'Unknown',
      lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      position: json['position'] as String? ?? 'Сотрудник',
      branch: json['branch'] as String? ?? 'Главный',
      status: json['status'] as String? ?? 'pending',
      hireDate: json['hire_date'] != null
          ? DateTime.parse(json['hire_date'] as String)
          : DateTime.now(),
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      desiredDaysOff: [],
    );
  }

  @override
  Map<String, dynamic> toJson(Employee employee) {
    return {
      'id': employee.id,
      'first_name': employee.firstName,
      'last_name': employee.lastName,
      'email': employee.email,
      'phone': employee.phone,
      'position': employee.position,
      'branch': employee.branch,
      'status': employee.status,
      'hire_date': employee.hireDate.toIso8601String(),
      'avatar_url': employee.avatarUrl,
      'address': employee.address,
      'hourly_rate': employee.hourlyRate,
      'role': 'employee',
    };
  }

  Future<List<Employee>> getEmployees() async {
    return executeWithResilience(() async {
      final response = await Supabase.instance.client
          .from(tableName)
          .select()
          .eq('role', 'employee')
          .order('full_name', ascending: true);

      return (response as List).map((json) => fromJson(json)).toList();
    });
  }

  Future<Employee> createEmployee(Employee employee) async {
    return create(toJson(employee));
  }

  Future<Employee> updateEmployee(Employee employee) async {
    final updateData = {
      'first_name': employee.firstName,
      'last_name': employee.lastName,
      'email': employee.email,
      'phone': employee.phone,
      'position': employee.position,
      'branch': employee.branch,
      'status': employee.status,
      'hire_date': employee.hireDate.toIso8601String(),
      'avatar_url': employee.avatarUrl,
      'address': employee.address,
      'hourly_rate': employee.hourlyRate,
    };
    return update(employee.id, updateData);
  }

  Future<void> deleteEmployee(String id) async {
    return delete(id);
  }
}
