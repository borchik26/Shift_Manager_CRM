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
import 'package:my_app/data/models/audit_log.dart';
import 'package:my_app/audit_logs/models/audit_log_filter.dart';
import 'package:my_app/data/services/api_service.dart';
import 'package:my_app/data/services/employee_service.dart';
import 'package:my_app/data/services/shift_service.dart';
import 'package:my_app/data/services/branch_service.dart';
import 'package:my_app/data/services/position_service.dart';
import 'package:my_app/data/services/audit_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of ApiService
/// Connects to Supabase backend for real data persistence
class SupabaseApiService implements ApiService {
  final SupabaseClient _client;
  final CircuitBreaker _circuitBreaker;

  late final EmployeeService _employeeService;
  late final ShiftService _shiftService;
  late final BranchService _branchService;
  late final PositionService _positionService;
  late final AuditService _auditService;

  /// Timeout для операций (30 секунд)
  static const _defaultTimeout = Duration(seconds: 30);

  SupabaseApiService()
    : _client = Supabase.instance.client,
      _circuitBreaker = CircuitBreaker() {
    _employeeService = EmployeeService();
    _shiftService = ShiftService();
    _branchService = BranchService();
    _positionService = PositionService();
    _auditService = AuditService();
  }

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
        throw app.AuthException(
          'Ошибка доступа',
          error,
          int.tryParse(code ?? ''),
        );
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
          'Ваш аккаунт ещё не активирован. Дождитесь подтверждения менеджера.',
        );
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
        throw app.ConflictException(
          'Пользователь с таким email уже зарегистрирован',
          e,
        );
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
  Future<List<Employee>> getEmployees() => _employeeService.getEmployees();

  @override
  Future<Employee?> getEmployeeById(String id) => _employeeService.getById(id);

  @override
  Future<Employee> createEmployee(Employee employee) =>
      _employeeService.createEmployee(employee);

  @override
  Future<Employee> updateEmployee(Employee employee) =>
      _employeeService.updateEmployee(employee);

  @override
  Future<void> deleteEmployee(String id) => _employeeService.deleteEmployee(id);

  // =====================================================
  // SHIFTS
  // =====================================================

  @override
  Future<List<Shift>> getShifts({
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _shiftService.getShifts(startDate: startDate, endDate: endDate);

  @override
  Future<List<Shift>> getShiftsByEmployee(String employeeId) =>
      _shiftService.getShiftsByEmployee(employeeId);

  @override
  Future<Shift?> getShiftById(String id) => _shiftService.getById(id);

  @override
  Future<Shift> createShift(Shift shift) => _shiftService.createShift(shift);

  @override
  Future<Shift> updateShift(Shift shift) => _shiftService.updateShift(shift);

  @override
  Future<void> deleteShift(String id) => _shiftService.deleteShift(id);

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
  Future<List<Branch>> getBranches() => _branchService.getBranches();

  @override
  Future<Branch?> getBranchById(String id) => _branchService.getById(id);

  @override
  Future<Branch> createBranch(Branch branch) =>
      _branchService.createBranch(branch);

  @override
  Future<Branch> updateBranch(Branch branch) =>
      _branchService.updateBranch(branch);

  @override
  Future<void> deleteBranch(String id) => _branchService.deleteBranch(id);

  // =====================================================
  // POSITIONS
  // =====================================================

  @override
  Future<List<Position>> getPositions() => _positionService.getPositions();

  @override
  Future<Position?> getPositionById(String id) => _positionService.getById(id);

  @override
  Future<Position> createPosition(Position position) =>
      _positionService.createPosition(position);

  @override
  Future<Position> updatePosition(Position position) =>
      _positionService.updatePosition(position);

  @override
  Future<void> deletePosition(String id) => _positionService.deletePosition(id);

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
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();

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
  // AUDIT LOGS
  // =====================================================

  @override
  Future<List<AuditLog>> getAuditLogs({
    int limit = 500,
    int offset = 0,
    AuditLogFilter? filter,
  }) =>
      _auditService.getAuditLogs(limit: limit, offset: offset, filter: filter);

  @override
  Future<void> deleteAllAuditLogs() => _auditService.deleteAllAuditLogs();

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
