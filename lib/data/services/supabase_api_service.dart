import 'package:my_app/data/models/branch.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/models/user.dart' as app_user;
import 'package:my_app/data/models/user_profile.dart';
import 'package:my_app/data/models/position.dart';
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

  @override
  Future<app_user.User?> register(
    String email,
    String password,
    String firstName,
    String lastName,
    String role,
  ) async {
    try {
      // 1. Create auth user via Supabase Auth with metadata
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Ошибка создания учётной записи');
      }

      final userId = authResponse.user!.id;

      // 2. Profile is automatically created by database trigger on auth user creation
      // The trigger creates a row in profiles table with:
      // id, email, full_name (from first_name + last_name), role, status='pending', created_at
      // See: supabase/migrations/20251214_create_profile_on_auth.sql

      // 3. Return User object
      return app_user.User(
        id: userId,
        username: email,
        role: role,
        email: email,
        firstName: firstName,
        lastName: lastName,
        status: 'pending',
        createdAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      if (e.message.contains('User already exists')) {
        throw Exception('Пользователь с таким email уже зарегистрирован');
      }
      throw Exception('Ошибка регистрации: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка регистрации: $e');
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
      // For MVP we insert directly into profiles table (no auth signUp flow)
      final insertData = {
        'id': employee.id, // UUID generated on client
        'full_name': '${employee.firstName} ${employee.lastName}',
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

      final response = await _client
          .from('profiles')
          .insert(insertData)
          .select()
          .single();

      return _profileToEmployee(response);
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
      // Let DB apply default/valid status
      insertData.remove('status');

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
      final response = await _client
          .from('branches')
          .select('name')
          .order('name', ascending: true);

      final branches = (response as List)
          .map((row) => row['name'] as String)
          .where((b) => b.isNotEmpty)
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
      final response = await _client
          .from('positions')
          .select('name')
          .order('name', ascending: true);

      final roles = (response as List)
          .map((row) => row['name'] as String)
          .where((r) => r.isNotEmpty)
          .toList();

      roles.sort();
      return roles;
    } catch (e) {
      throw Exception('Ошибка загрузки ролей: $e');
    }
  }

  @override
  Future<List<String>> getAvailableUserRoles() async {
    // Return available user roles for registration ('employee', 'manager')
    return ['employee', 'manager'];
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
  // POSITIONS
  // =====================================================

  @override
  Future<List<Position>> getPositions() async {
    try {
      final response = await _client
          .from('positions')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((json) => Position.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Ошибка загрузки должностей: $e');
    }
  }

  @override
  Future<Position?> getPositionById(String id) async {
    try {
      final response = await _client
          .from('positions')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return Position.fromJson(response);
    } catch (e) {
      throw Exception('Ошибка загрузки должности: $e');
    }
  }

  @override
  Future<Position> createPosition(Position position) async {
    try {
      final insertData = position.toJson()..remove('id');

      final response = await _client
          .from('positions')
          .insert(insertData)
          .select()
          .single();

      return Position.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Должность с таким названием уже существует');
      }
      throw Exception('Ошибка создания должности: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка создания должности: $e');
    }
  }

  @override
  Future<Position> updatePosition(Position position) async {
    try {
      final response = await _client
          .from('positions')
          .update(position.toJson())
          .eq('id', position.id)
          .select()
          .single();

      return Position.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Должность с таким названием уже существует');
      }
      throw Exception('Ошибка обновления должности: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка обновления должности: $e');
    }
  }

  @override
  Future<void> deletePosition(String id) async {
    try {
      await _client.from('positions').delete().eq('id', id);
    } catch (e) {
      throw Exception('Ошибка удаления должности: $e');
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

  // =====================================================
  // USER PROFILES (from 'profiles' table)
  // =====================================================

  /// Get all user profiles from the profiles table
  @override
  Future<List<UserProfile>> getAllProfiles() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Ошибка загрузки пользователей: $e');
    }
  }

  /// Get a specific user profile by ID
  @override
  Future<UserProfile?> getProfileById(String id) async {
    try {
      final response =
          await _client.from('profiles').select().eq('id', id).maybeSingle();

      if (response == null) return null;

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Ошибка загрузки профиля пользователя: $e');
    }
  }

  /// Update user status (active, inactive, pending)
  @override
  Future<void> updateUserStatus(String userId, String newStatus) async {
    try {
      final validStatuses = ['active', 'inactive', 'pending'];
      if (!validStatuses.contains(newStatus)) {
        throw Exception('Неверный статус: $newStatus');
      }

      await _client
          .from('profiles')
          .update({'status': newStatus})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Ошибка обновления статуса пользователя: $e');
    }
  }

  /// Delete a user profile completely
  /// WARNING: This will also delete the auth user if cascade is configured
  @override
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _client.from('profiles').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Ошибка удаления профиля пользователя: $e');
    }
  }
}
