import 'dart:async' as dart_async;
import 'dart:io';

import 'package:my_app/core/utils/exceptions/app_exceptions.dart' as app;
import 'package:my_app/core/utils/retry/circuit_breaker.dart';
import 'package:my_app/core/utils/retry/retry_handler.dart';
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
  final CircuitBreaker _circuitBreaker;

  /// Timeout для операций (30 секунд)
  static const _defaultTimeout = Duration(seconds: 30);

  SupabaseApiService()
      : _client = Supabase.instance.client,
        _circuitBreaker = CircuitBreaker();

  // =====================================================
  // HELPER: Выполнение с retry, circuit breaker и timeout
  // =====================================================

  /// Выполняет операцию с retry, circuit breaker и timeout
  Future<T> _executeWithResilience<T>(
    Future<T> Function() operation, {
    Duration timeout = _defaultTimeout,
  }) async {
    return _circuitBreaker.execute(() async {
      return RetryHandler.execute(
        operation: () => _withTimeout(operation(), timeout: timeout),
      );
    });
  }

  /// Оборачивает операцию в timeout
  Future<T> _withTimeout<T>(
    Future<T> operation, {
    Duration timeout = _defaultTimeout,
  }) {
    return operation.timeout(
      timeout,
      onTimeout: () => throw const app.TimeoutException(
        'Превышено время ожидания ответа от сервера',
      ),
    );
  }

  /// Преобразует ошибки в типизированные исключения
  Never _handleError(Object error, String operation) {
    // Уже типизированные исключения
    if (error is app.AppException) throw error;

    // AuthException от Supabase
    if (error is AuthException) {
      throw app.AuthException('Ошибка авторизации: ${error.message}', error);
    }

    // PostgrestException от Supabase
    if (error is PostgrestException) {
      final code = error.code;
      final message = error.message;

      // 409 Conflict - overlap, duplicates
      if (code == '23505' || message.contains('overlaps')) {
        throw app.ConflictException(message, error);
      }

      // 404 Not Found
      if (code == 'PGRST116') {
        throw app.NotFoundException('Ресурс не найден', error);
      }

      // 401/403 Auth errors
      if (code == '401' || code == '403') {
        throw app.AuthException('Ошибка доступа', error, int.tryParse(code ?? ''));
      }

      // Прочие PostgrestException
      throw app.ServerException('Ошибка базы данных: $message', error);
    }

    // SocketException - сетевые ошибки
    if (error is SocketException) {
      throw app.NetworkException(
        'Ошибка сети. Проверьте подключение к интернету.',
        error,
      );
    }

    // dart:async TimeoutException
    if (error is dart_async.TimeoutException) {
      throw const app.TimeoutException(
        'Превышено время ожидания ответа от сервера',
      );
    }

    // Неизвестные ошибки
    throw app.ServerException('Ошибка $operation: $error', error);
  }

  // =====================================================
  // AUTHENTICATION
  // =====================================================

  @override
  Future<app_user.User?> login(String username, String password) async {
    try {
      // In Supabase, "username" is email
      final response = await _withTimeout(
        _client.auth.signInWithPassword(
          email: username,
          password: password,
        ),
      );

      if (response.user == null) return null;

      // Fetch profile to get role and other data
      final profileData = await _executeWithResilience(() async {
        return _client
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();
      });

      // Check if user is approved
      // Managers can always login, employees need to be active
      final userRole = profileData['role'] as String?;
      final userStatus = profileData['status'] as String?;

      if (userRole != 'manager' && userStatus != 'active') {
        await logout();
        throw app.ValidationException(
            'Ваш аккаунт ещё не активирован. Дождитесь подтверждения менеджера.');
      }

      return app_user.User(
        id: profileData['id'] as String,
        username: profileData['email'] as String,
        role: profileData['role'] as String,
      );
    } on AuthException catch (e) {
      throw app.AuthException('Ошибка авторизации: ${e.message}', e);
    } catch (e) {
      _handleError(e, 'входа');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _withTimeout(_client.auth.signOut());
    } catch (e) {
      _handleError(e, 'выхода');
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
      final authResponse = await _withTimeout(
        _client.auth.signUp(
          email: email,
          password: password,
          data: {
            'first_name': firstName,
            'last_name': lastName,
            'role': role,
          },
        ),
      );

      if (authResponse.user == null) {
        throw app.ServerException('Ошибка создания учётной записи');
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
        throw app.ConflictException('Пользователь с таким email уже зарегистрирован', e);
      }
      throw app.AuthException('Ошибка регистрации: ${e.message}', e);
    } catch (e) {
      _handleError(e, 'регистрации');
    }
  }

  // =====================================================
  // EMPLOYEES (mapped from profiles with role='employee')
  // =====================================================

  @override
  Future<List<Employee>> getEmployees() async {
    return _executeWithResilience(() async {
      final response = await _client
          .from('profiles')
          .select()
          .eq('role', 'employee')
          .order('full_name', ascending: true);

      return (response as List)
          .map((json) => _profileToEmployee(json))
          .toList();
    });
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    return _executeWithResilience(() async {
      final response =
          await _client.from('profiles').select().eq('id', id).maybeSingle();

      if (response == null) return null;

      return _profileToEmployee(response);
    });
  }

  @override
  Future<Employee> createEmployee(Employee employee) async {
    return _executeWithResilience(() async {
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
    });
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    return _executeWithResilience(() async {
      final updateData = {
        'full_name': employee.fullName,
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

      final response = await _client
          .from('profiles')
          .update(updateData)
          .eq('id', employee.id)
          .select()
          .single();

      return _profileToEmployee(response);
    });
  }

  @override
  Future<void> deleteEmployee(String id) async {
    return _executeWithResilience(() async {
      await _client.from('profiles').delete().eq('id', id);
    });
  }

  // =====================================================
  // SHIFTS
  // =====================================================

  @override
  Future<List<Shift>> getShifts({DateTime? startDate, DateTime? endDate}) async {
    return _executeWithResilience(() async {
      var query = _client.from('shifts').select('*');

      if (startDate != null) {
        query = query.gte('start_time', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('end_time', endDate.toIso8601String());
      }

      final response = await query.order('start_time', ascending: true);

      return (response as List).map((json) => Shift.fromJson(json)).toList();
    });
  }

  @override
  Future<List<Shift>> getShiftsByEmployee(String employeeId) async {
    return _executeWithResilience(() async {
      final response = await _client
          .from('shifts')
          .select('*')
          .eq('employee_id', employeeId)
          .order('start_time', ascending: true);

      return (response as List).map((json) => Shift.fromJson(json)).toList();
    });
  }

  @override
  Future<Shift?> getShiftById(String id) async {
    return _executeWithResilience(() async {
      final response =
          await _client.from('shifts').select('*').eq('id', id).maybeSingle();

      if (response == null) return null;

      return Shift.fromJson(response);
    });
  }

  @override
  Future<Shift> createShift(Shift shift) async {
    try {
      return await _executeWithResilience(() async {
        final insertData = shift.toJson();
        insertData.remove('id');
        insertData.remove('status');

        final response =
            await _client.from('shifts').insert(insertData).select('*').single();

        return Shift.fromJson(response);
      });
    } on PostgrestException catch (e) {
      if (e.message.contains('overlaps')) {
        throw app.ConflictException('Смена пересекается с существующей сменой сотрудника', e);
      }
      _handleError(e, 'создания смены');
    }
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    try {
      return await _executeWithResilience(() async {
        final response = await _client
            .from('shifts')
            .update(shift.toJson())
            .eq('id', shift.id)
            .select('*')
            .single();

        return Shift.fromJson(response);
      });
    } on PostgrestException catch (e) {
      if (e.message.contains('overlaps')) {
        throw app.ConflictException('Смена пересекается с существующей сменой сотрудника', e);
      }
      _handleError(e, 'обновления смены');
    }
  }

  @override
  Future<void> deleteShift(String id) async {
    return _executeWithResilience(() async {
      await _client.from('shifts').delete().eq('id', id);
    });
  }

  // =====================================================
  // REFERENCE DATA
  // =====================================================

  @override
  Future<List<String>> getAvailableBranches() async {
    return _executeWithResilience(() async {
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
    });
  }

  @override
  Future<List<String>> getAvailableRoles() async {
    return _executeWithResilience(() async {
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
    });
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
    return _executeWithResilience(() async {
      final response = await _client
          .from('branches')
          .select()
          .order('name', ascending: true);

      return (response as List).map((json) => Branch.fromJson(json)).toList();
    });
  }

  @override
  Future<Branch?> getBranchById(String id) async {
    return _executeWithResilience(() async {
      final response =
          await _client.from('branches').select().eq('id', id).maybeSingle();

      if (response == null) return null;

      return Branch.fromJson(response);
    });
  }

  @override
  Future<Branch> createBranch(Branch branch) async {
    try {
      return await _executeWithResilience(() async {
        final insertData = branch.toJson();
        insertData.remove('id');

        final response =
            await _client.from('branches').insert(insertData).select().single();

        return Branch.fromJson(response);
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw app.ConflictException('Филиал с таким названием уже существует', e);
      }
      _handleError(e, 'создания филиала');
    }
  }

  @override
  Future<Branch> updateBranch(Branch branch) async {
    try {
      return await _executeWithResilience(() async {
        final response = await _client
            .from('branches')
            .update(branch.toJson())
            .eq('id', branch.id)
            .select()
            .single();

        return Branch.fromJson(response);
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw app.ConflictException('Филиал с таким названием уже существует', e);
      }
      _handleError(e, 'обновления филиала');
    }
  }

  @override
  Future<void> deleteBranch(String id) async {
    return _executeWithResilience(() async {
      await _client.from('branches').delete().eq('id', id);
    });
  }

  // =====================================================
  // POSITIONS
  // =====================================================

  @override
  Future<List<Position>> getPositions() async {
    return _executeWithResilience(() async {
      final response = await _client
          .from('positions')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((json) => Position.fromJson(json))
          .toList();
    });
  }

  @override
  Future<Position?> getPositionById(String id) async {
    return _executeWithResilience(() async {
      final response = await _client
          .from('positions')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return Position.fromJson(response);
    });
  }

  @override
  Future<Position> createPosition(Position position) async {
    try {
      return await _executeWithResilience(() async {
        final insertData = position.toJson()..remove('id');

        final response = await _client
            .from('positions')
            .insert(insertData)
            .select()
            .single();

        return Position.fromJson(response);
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw app.ConflictException('Должность с таким названием уже существует', e);
      }
      _handleError(e, 'создания должности');
    }
  }

  @override
  Future<Position> updatePosition(Position position) async {
    try {
      return await _executeWithResilience(() async {
        final response = await _client
            .from('positions')
            .update(position.toJson())
            .eq('id', position.id)
            .select()
            .single();

        return Position.fromJson(response);
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw app.ConflictException('Должность с таким названием уже существует', e);
      }
      _handleError(e, 'обновления должности');
    }
  }

  @override
  Future<void> deletePosition(String id) async {
    return _executeWithResilience(() async {
      await _client.from('positions').delete().eq('id', id);
    });
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
    return _executeWithResilience(() async {
      final response = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    });
  }

  /// Get a specific user profile by ID
  @override
  Future<UserProfile?> getProfileById(String id) async {
    return _executeWithResilience(() async {
      final response =
          await _client.from('profiles').select().eq('id', id).maybeSingle();

      if (response == null) return null;

      return UserProfile.fromJson(response);
    });
  }

  /// Update user status (active, inactive, pending)
  @override
  Future<void> updateUserStatus(String userId, String newStatus) async {
    final validStatuses = ['active', 'inactive', 'pending'];
    if (!validStatuses.contains(newStatus)) {
      throw app.ValidationException('Неверный статус: $newStatus');
    }

    return _executeWithResilience(() async {
      await _client
          .from('profiles')
          .update({'status': newStatus})
          .eq('id', userId);
    });
  }

  /// Delete a user profile completely
  /// WARNING: This will also delete the auth user if cascade is configured
  @override
  Future<void> deleteUserProfile(String userId) async {
    return _executeWithResilience(() async {
      await _client.from('profiles').delete().eq('id', userId);
    });
  }

  // =====================================================
  // HEALTH CHECK
  // =====================================================

  /// Проверка доступности Supabase
  Future<bool> healthCheck() async {
    try {
      await _withTimeout(
        _client.from('branches').select('id').limit(1),
        timeout: const Duration(seconds: 5),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
