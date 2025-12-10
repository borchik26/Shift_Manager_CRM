import 'package:my_app/data/models/user.dart';
import 'package:my_app/data/models/user_profile.dart';
import 'package:my_app/data/services/api_service.dart';

/// Repository for authentication operations
/// ViewModels should use this instead of calling ApiService directly
class AuthRepository {
  final ApiService _apiService;

  AuthRepository({required ApiService apiService}) : _apiService = apiService;

  Future<User?> login(String username, String password) {
    return _apiService.login(username, password);
  }

  Future<User?> register(
    String email,
    String password,
    String firstName,
    String lastName,
    String role,
  ) {
    return _apiService.register(email, password, firstName, lastName, role);
  }

  Future<void> logout() {
    return _apiService.logout();
  }

  Future<List<String>> getAvailableUserRoles() {
    return _apiService.getAvailableUserRoles();
  }

  // =====================================================
  // USER PROFILE MANAGEMENT
  // =====================================================

  /// Get all user profiles
  Future<List<UserProfile>> getAllProfiles() async {
    return _apiService.getAllProfiles();
  }

  /// Get a specific user profile by ID
  Future<UserProfile?> getProfileById(String id) async {
    return _apiService.getProfileById(id);
  }

  /// Update user status (active, inactive, pending)
  Future<void> updateUserStatus(String userId, String newStatus) async {
    return _apiService.updateUserStatus(userId, newStatus);
  }

  /// Delete a user profile
  Future<void> deleteUserProfile(String userId) async {
    return _apiService.deleteUserProfile(userId);
  }
}