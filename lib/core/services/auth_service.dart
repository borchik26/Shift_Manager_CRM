import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_app/data/models/user.dart' as app_user;
import 'package:my_app/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing authentication state across the app
/// This is an app-wide service that should be registered in the locator
///
/// ✅ IMPROVED: Now uses Supabase's built-in session management
/// - onAuthStateChange listener for automatic session updates
/// - currentSession for session restoration on app startup
/// - No manual token management needed (Supabase handles it)
class AuthService {
  AuthService({required AuthRepository authRepository})
      : _authRepository = authRepository {
    _initializeAuthListener();
  }

  final AuthRepository _authRepository;
  StreamSubscription<AuthState>? _authSubscription;

  /// Current authenticated user
  final ValueNotifier<app_user.User?> currentUserNotifier = ValueNotifier<app_user.User?>(null);

  /// Check if user is authenticated
  bool get isAuthenticated => currentUserNotifier.value != null;

  /// Get current user (null if not authenticated)
  app_user.User? get currentUser => currentUserNotifier.value;

  /// ✅ NEW: Initialize Supabase auth state listener
  /// Automatically updates currentUser when session changes (login/logout/refresh)
  void _initializeAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        final session = data.session;
        if (session == null) {
          // User logged out or session expired
          currentUserNotifier.value = null;
        } else {
          // User logged in or session refreshed
          await _loadUserProfile(session.user.id);
        }
      },
    );
  }

  /// ✅ NEW: Load user profile from database
  /// Called when session is detected to populate user data
  Future<void> _loadUserProfile(String userId) async {
    try {
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      // Only set user if account is active
      if (profileData['status'] == 'active') {
        currentUserNotifier.value = app_user.User(
          id: profileData['id'] as String,
          username: profileData['email'] as String,
          role: profileData['role'] as String,
        );
      } else {
        currentUserNotifier.value = null;
      }
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
      currentUserNotifier.value = null;
    }
  }

  /// Login with email and password
  /// Throws exception if credentials are invalid
  Future<void> login(String email, String password) async {
    final user = await _authRepository.login(email, password);
    if (user == null) {
      throw Exception('Invalid credentials');
    }
    currentUserNotifier.value = user;
    // ✅ Session is automatically managed by Supabase (tokens, refresh, etc.)
  }

  /// Logout current user
  Future<void> logout() async {
    await _authRepository.logout(); // ✅ FIXED: Call repository logout
    currentUserNotifier.value = null;
  }

  /// ✅ IMPROVED: Initialize auth state from stored Supabase session
  /// Call this on app startup to restore session if user was previously logged in
  Future<void> initializeAuth() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // Session exists - restore user profile
        await _loadUserProfile(session.user.id);
      } else {
        // No session - user not logged in
        currentUserNotifier.value = null;
      }
    } catch (e) {
      debugPrint('Failed to initialize auth: $e');
      currentUserNotifier.value = null;
    }
  }

  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel(); // ✅ ADDED: Cancel auth state listener
    currentUserNotifier.dispose();
  }
}