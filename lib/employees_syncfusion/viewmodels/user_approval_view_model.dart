import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/models/user_profile.dart';
import 'package:my_app/data/repositories/auth_repository.dart';

/// ViewModel for managing user approval and profile operations
class UserApprovalViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AsyncValue<List<UserProfile>> _usersState = const AsyncLoading();
  AsyncValue<void> _operationState = const AsyncData(null);
  List<UserProfile> _filteredUsers = [];
  String _statusFilter = '';
  bool _disposed = false;

  UserApprovalViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  // =====================================================
  // GETTERS
  // =====================================================

  AsyncValue<List<UserProfile>> get usersState => _usersState;
  AsyncValue<void> get operationState => _operationState;
  List<UserProfile> get filteredUsers => _filteredUsers;
  String get statusFilter => _statusFilter;
  int get totalCount => _usersState.dataOrNull?.length ?? 0;
  int get filteredCount => _filteredUsers.length;

  // =====================================================
  // METHODS
  // =====================================================

  /// Load all users from the profiles table
  Future<void> loadUsers() async {
    _usersState = const AsyncLoading();
    _safeNotifyListeners();

    try {
      final users = await _authRepository.getAllProfiles();
      _usersState = AsyncData(users);
      _applyFilters();
      _safeNotifyListeners();
    } catch (e) {
      _usersState = AsyncError('Ошибка загрузки пользователей: $e');
      debugPrint('Error loading users: $e');
      _safeNotifyListeners();
    }
  }

  /// Set status filter and reapply filters
  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
    _safeNotifyListeners();
  }

  /// Approve a user (pending -> active)
  Future<void> approveUser(String userId) async {
    _operationState = const AsyncLoading();
    _safeNotifyListeners();

    try {
      await _authRepository.updateUserStatus(userId, 'active');
      _operationState = const AsyncData(null);
      await loadUsers();
    } catch (e) {
      _operationState = AsyncError('Ошибка активации пользователя: $e');
      debugPrint('Error approving user: $e');
      _safeNotifyListeners();
    }
  }

  /// Reject a user (pending -> inactive)
  Future<void> rejectUser(String userId) async {
    _operationState = const AsyncLoading();
    _safeNotifyListeners();

    try {
      await _authRepository.updateUserStatus(userId, 'inactive');
      _operationState = const AsyncData(null);
      await loadUsers();
    } catch (e) {
      _operationState = AsyncError('Ошибка отклонения пользователя: $e');
      debugPrint('Error rejecting user: $e');
      _safeNotifyListeners();
    }
  }

  /// Delete a user completely
  Future<void> deleteUser(String userId) async {
    _operationState = const AsyncLoading();
    _safeNotifyListeners();

    try {
      await _authRepository.deleteUserProfile(userId);
      _operationState = const AsyncData(null);
      await loadUsers();
    } catch (e) {
      _operationState = AsyncError('Ошибка удаления пользователя: $e');
      debugPrint('Error deleting user: $e');
      _safeNotifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _operationState = const AsyncData(null);
    _safeNotifyListeners();
  }

  // =====================================================
  // PRIVATE METHODS
  // =====================================================

  void _applyFilters() {
    final users = _usersState.dataOrNull ?? [];
    if (_statusFilter.isEmpty) {
      _filteredUsers = List.from(users);
    } else {
      _filteredUsers = users.where((u) => u.status == _statusFilter).toList();
    }
  }

  /// Safe notifyListeners that checks if ViewModel is still alive
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
