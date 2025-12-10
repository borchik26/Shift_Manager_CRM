import 'package:flutter/material.dart';
import 'package:my_app/data/models/user_profile.dart';
import 'package:my_app/data/repositories/auth_repository.dart';

/// ViewModel for managing user approval and profile operations
class UserApprovalViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  List<UserProfile> _users = [];
  List<UserProfile> _filteredUsers = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = ''; // '' = all, 'pending', 'active', 'inactive'

  UserApprovalViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  // =====================================================
  // GETTERS
  // =====================================================

  List<UserProfile> get users => _users;
  List<UserProfile> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;
  int get totalCount => _users.length;
  int get filteredCount => _filteredUsers.length;

  // =====================================================
  // METHODS
  // =====================================================

  /// Load all users from the profiles table
  Future<void> loadUsers() async {
    _setLoading(true);
    _error = null;
    try {
      _users = await _authRepository.getAllProfiles();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading users: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Set status filter and reapply filters
  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  /// Approve a user (pending -> active)
  Future<void> approveUser(String userId) async {
    try {
      await _authRepository.updateUserStatus(userId, 'active');
      await loadUsers();
    } catch (e) {
      _error = 'Ошибка активации пользователя: $e';
      debugPrint('Error approving user: $e');
      notifyListeners();
    }
  }

  /// Reject a user (pending -> inactive)
  Future<void> rejectUser(String userId) async {
    try {
      await _authRepository.updateUserStatus(userId, 'inactive');
      await loadUsers();
    } catch (e) {
      _error = 'Ошибка отклонения пользователя: $e';
      debugPrint('Error rejecting user: $e');
      notifyListeners();
    }
  }

  /// Delete a user completely
  Future<void> deleteUser(String userId) async {
    try {
      await _authRepository.deleteUserProfile(userId);
      await loadUsers();
    } catch (e) {
      _error = 'Ошибка удаления пользователя: $e';
      debugPrint('Error deleting user: $e');
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // =====================================================
  // PRIVATE METHODS
  // =====================================================

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _applyFilters() {
    if (_statusFilter.isEmpty) {
      _filteredUsers = List.from(_users);
    } else {
      _filteredUsers = _users.where((u) => u.status == _statusFilter).toList();
    }
  }
}
