import 'package:flutter/foundation.dart';
import 'package:my_app/data/models/user.dart';
import 'package:my_app/data/repositories/auth_repository.dart';

/// Service for managing authentication state across the app
/// This is an app-wide service that should be registered in the locator
class AuthService {
  AuthService({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  /// Current authenticated user
  final ValueNotifier<User?> currentUserNotifier = ValueNotifier<User?>(null);

  /// Check if user is authenticated
  bool get isAuthenticated => currentUserNotifier.value != null;

  /// Get current user (null if not authenticated)
  User? get currentUser => currentUserNotifier.value;

  /// Login with email and password
  /// Throws exception if credentials are invalid
  Future<void> login(String email, String password) async {
    final user = await _authRepository.login(email, password);
    if (user == null) {
      throw Exception('Invalid credentials');
    }
    currentUserNotifier.value = user;
    // TODO: Save token to SharedPreferences for persistence
  }

  /// Logout current user
  Future<void> logout() async {
    currentUserNotifier.value = null;
    // TODO: Clear token from SharedPreferences
  }

  /// Initialize auth state from stored token
  /// Call this on app startup to restore session
  Future<void> initializeAuth() async {
    // TODO: Load token from SharedPreferences
    // TODO: Validate token with backend
    // TODO: If valid, load user data
    // For now, just set to null (not authenticated)
    currentUserNotifier.value = null;
  }

  /// Dispose resources
  void dispose() {
    currentUserNotifier.dispose();
  }
}