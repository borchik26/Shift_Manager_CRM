import 'package:my_app/data/models/branch.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/models/user.dart' as app_user;
import 'package:my_app/data/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of ApiService
/// Connects to Supabase backend for real data persistence
class SupabaseApiService implements ApiService {
  final SupabaseClient _client;

  SupabaseApiService() : _client = Supabase.instance.client;

  // =====================================================
  // AUTHENTICATION
  // =====================================================

  @override
  Future<app_user.User?> login(String username, String password) async {
    try {
      // In Supabase, "username" is email
      final response = await _client.auth.signInWithPassword(
        email: username,
        password: password,
      );

      if (response.user == null) return null;

      // Fetch profile to get role and other data
      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      // Check if user is approved (status = 'active')
      if (profileData['status'] != 'active') {
        await logout();
        throw Exception(
            'Ваш аккаунт ещё не активирован. Дождитесь подтверждения менеджера.');
      }

      return app_user.User(
        id: profileData['id'] as String,
        username: profileData['email'] as String,
        role: profileData['role'] as String,
      );
    } on AuthException catch (e) {
      throw Exception('Ошибка авторизации: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка входа: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Ошибка выхода: $e');
    }
  }

  // =====================================================
  // EMPLOYEES (mapped from profiles with role='employee')
  // =====================================================

  @override
  Future<List<Employee>> getEmployees() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('role', 'employee')
          .order('full_name', ascending: true);

      return (response as List)
          .map((json) => _profileToEmployee(json))
          .toList();
    } catch (e) {
      throw Exception('Ошибка загрузки сотрудников: $e');
    }
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    try {
      final response =
          await _client.from('profiles').select().eq('id', id).maybeSingle();

      if (response == null) return null;

      return _profileToEmployee(response);
    } catch (e) {
      throw Exception('Ошибка загрузки сотрудника: $e');
    }
  }

  @override
  Future<Employee> createEmployee(Employee employee) async {
    try {
      // Note: In Supabase, employees are created via auth.signUp
      // This method updates an existing profile or creates a placeholder
      // For now, throw error - employees should register via app
      throw UnimplementedError(
          'Создание сотрудников через signUp. Используйте форму регистрации.');
    } catch (e) {
      throw Exception('Ошибка создания сотрудника: $e');
    }
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    try {
      final updateData = {
        'full_name': employee.fullName,
        'email': employee.email,
        'phone': employee.phone,
        'position': employee.position, // ✅ FIXED: Add position field
        'branch': employee.branch,
        'status': employee.status,
        'hire_date': employee.hireDate.toIso8601String(),
        'avatar_url': employee.avatarUrl,
        'address': employee.address, // ✅ ADDED: Map address field
        'hourly_rate': employee.hourlyRate, // ✅ ADDED: Map hourly rate field
      };

      final response = await _client
          .from('profiles')
          .update(updateData)
          .eq('id', employee.id)
          .select()
          .single();

      return _profileToEmployee(response);
    } catch (e) {
      throw Exception('Ошибка обновления сотрудника: $e');
    }
  }

  @override
  Future<void> deleteEmployee(String id) async {
    try {
      // Hard delete (as per plan.mdc requirements)
      await _client.from('profiles').delete().eq('id', id);
    } catch (e) {
      throw Exception('Ошибка удаления сотрудника: $e');
    }
  }

  // =====================================================
  // SHIFTS
  // =====================================================

  @override
  Future<List<Shift>> getShifts({DateTime? startDate, DateTime? endDate}) async {
    try {
      var query = _client.from('shifts').select();

      if (startDate != null) {
        query = query.gte('start_time', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('end_time', endDate.toIso8601String());
      }

      final response = await query.order('start_time', ascending: true);

      return (response as List).map((json) => Shift.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки смен: $e');
    }
  }

  @override
  Future<List<Shift>> getShiftsByEmployee(String employeeId) async {
    try {
      final response = await _client
          .from('shifts')
          .select()
          .eq('employee_id', employeeId)
          .order('start_time', ascending: true);

      return (response as List).map((json) => Shift.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки смен сотрудника: $e');
    }
  }

  @override
  Future<Shift?> getShiftById(String id) async {
    try {
      final response =
          await _client.from('shifts').select().eq('id', id).maybeSingle();

      if (response == null) return null;

      return Shift.fromJson(response);
    } catch (e) {
      throw Exception('Ошибка загрузки смены: $e');
    }
  }

  @override
  Future<Shift> createShift(Shift shift) async {
    try {
      final insertData = shift.toJson();
      // Remove id for insert (Supabase generates it)
      insertData.remove('id');

      final response =
          await _client.from('shifts').insert(insertData).select().single();

      return Shift.fromJson(response);
    } on PostgrestException catch (e) {
      // Handle shift overlap error from trigger
      if (e.message.contains('overlaps')) {
        throw Exception('Смена пересекается с существующей сменой сотрудника');
      }
      throw Exception('Ошибка создания смены: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка создания смены: $e');
    }
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    try {
      final response = await _client
          .from('shifts')
          .update(shift.toJson())
          .eq('id', shift.id)
          .select()
          .single();

      return Shift.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('overlaps')) {
        throw Exception('Смена пересекается с существующей сменой сотрудника');
      }
      throw Exception('Ошибка обновления смены: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка обновления смены: $e');
    }
  }

  @override
  Future<void> deleteShift(String id) async {
    try {
      await _client.from('shifts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Ошибка удаления смены: $e');
    }
  }

  // =====================================================
  // REFERENCE DATA
  // =====================================================

  @override
  Future<List<String>> getAvailableBranches() async {
    try {
      // Get unique branches from profiles
      final response = await _client
          .from('profiles')
          .select('branch')
          .not('branch', 'is', null);

      final branches = (response as List)
          .map((row) => row['branch'] as String)
          .where((b) => b.isNotEmpty)
          .toSet()
          .toList();

      branches.sort();
      return branches;
    } catch (e) {
      throw Exception('Ошибка загрузки филиалов: $e');
    }
  }

  @override
  Future<List<String>> getAvailableRoles() async {
    try {
      // Get unique role_title from shifts
      final response = await _client
          .from('shifts')
          .select('role_title')
          .not('role_title', 'is', null);

      final roles = (response as List)
          .map((row) => row['role_title'] as String)
          .where((r) => r.isNotEmpty)
          .toSet()
          .toList();

      roles.sort();
      return roles;
    } catch (e) {
      throw Exception('Ошибка загрузки ролей: $e');
    }
  }

  // =====================================================
  // BRANCHES
  // =====================================================

  @override
  Future<List<Branch>> getBranches() async {
    try {
      final response = await _client
          .from('branches')
          .select()
          .order('name', ascending: true);

      return (response as List).map((json) => Branch.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки филиалов: $e');
    }
  }

  @override
  Future<Branch?> getBranchById(String id) async {
    try {
      final response =
          await _client.from('branches').select().eq('id', id).maybeSingle();

      if (response == null) return null;

      return Branch.fromJson(response);
    } catch (e) {
      throw Exception('Ошибка загрузки филиала: $e');
    }
  }

  @override
  Future<Branch> createBranch(Branch branch) async {
    try {
      final insertData = branch.toJson();
      // Remove id for insert (Supabase generates it)
      insertData.remove('id');

      final response =
          await _client.from('branches').insert(insertData).select().single();

      return Branch.fromJson(response);
    } on PostgrestException catch (e) {
      // Handle unique constraint violation
      if (e.code == '23505') {
        throw Exception('Филиал с таким названием уже существует');
      }
      throw Exception('Ошибка создания филиала: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка создания филиала: $e');
    }
  }

  @override
  Future<Branch> updateBranch(Branch branch) async {
    try {
      final response = await _client
          .from('branches')
          .update(branch.toJson())
          .eq('id', branch.id)
          .select()
          .single();

      return Branch.fromJson(response);
    } on PostgrestException catch (e) {
      // Handle unique constraint violation
      if (e.code == '23505') {
        throw Exception('Филиал с таким названием уже существует');
      }
      throw Exception('Ошибка обновления филиала: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка обновления филиала: $e');
    }
  }

  @override
  Future<void> deleteBranch(String id) async {
    try {
      await _client.from('branches').delete().eq('id', id);
    } catch (e) {
      throw Exception('Ошибка удаления филиала: $e');
    }
  }

  // =====================================================
  // HELPER: Map Supabase profile to Employee model
  // =====================================================
  Employee _profileToEmployee(Map<String, dynamic> json) {
    final fullName = json['full_name'] as String;
    final nameParts = fullName.split(' ');

    return Employee(
      id: json['id'] as String,
      firstName: nameParts.isNotEmpty ? nameParts[0] : 'Unknown',
      lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      position: json['position'] as String? ?? 'Сотрудник', // ✅ FIXED: Use correct field
      branch: json['branch'] as String? ?? 'Главный',
      status: json['status'] as String? ?? 'pending',
      hireDate: json['hire_date'] != null
          ? DateTime.parse(json['hire_date'] as String)
          : DateTime.now(),
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?, // ✅ ADDED: Map address field
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0.0, // ✅ ADDED: Map hourly rate field
      desiredDaysOff: [], // TODO: Implement when adding desired_days_off to DB
    );
  }
}
