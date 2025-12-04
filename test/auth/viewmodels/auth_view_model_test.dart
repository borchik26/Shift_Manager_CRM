import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/auth/viewmodels/auth_view_model.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';
import 'package:my_app/data/models/user.dart';

// Fake implementation for testing
class FakeAuthService implements AuthService {
  bool _shouldThrowError = false;
  String _requiredEmail = 'admin@example.com';
  String _requiredPassword = 'password123';
  User? _currentUser;
  
  @override
  bool get isAuthenticated => _currentUser != null;
  
  @override
  User? get currentUser => _currentUser;
  
  @override
  final ValueNotifier<User?> currentUserNotifier = ValueNotifier<User?>(null);
  
  @override
  Future<void> initializeAuth() async {
    await Future.delayed(const Duration(milliseconds: 50));
    currentUserNotifier.value = null;
  }
  
  @override
  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Authentication failed');
    }
    
    if (email != _requiredEmail || password != _requiredPassword) {
      throw Exception('Invalid credentials');
    }
    
    _currentUser = User(
      id: '1',
      username: email,
      role: 'admin',
    );
    currentUserNotifier.value = _currentUser;
  }
  
  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _currentUser = null;
    currentUserNotifier.value = null;
  }
  
  @override
  void dispose() {
    currentUserNotifier.dispose();
  }
  
  // Helper methods for testing
  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }
  
  void setCredentials(String email, String password) {
    _requiredEmail = email;
    _requiredPassword = password;
  }
}

class FakeNotifyService extends NotifyService {
  ToastEvent? lastEvent;
  
  @override
  void setToastEvent(ToastEvent? event) {
    lastEvent = event;
  }
}

void main() {
  group('AuthViewModel', () {
    late FakeAuthService fakeAuthService;
    late FakeNotifyService fakeNotifyService;
    late AuthViewModel viewModel;

    setUp(() {
      fakeAuthService = FakeAuthService();
      fakeNotifyService = FakeNotifyService();
      viewModel = AuthViewModel(authService: fakeAuthService);
    });

    tearDown(() {
      viewModel.dispose();
    });

    group('Initial State', () {
      test('should start with AsyncData state', () {
        expect(viewModel.loginState.value, isA<AsyncData<void>>());
      });

      test('should have AsyncData state initially', () {
        expect(viewModel.loginState.value, isA<AsyncData<void>>());
      });
    });

    group('Successful Login', () {
      test('should login successfully with correct credentials', () async {
        fakeAuthService.setCredentials('admin@example.com', 'password123');
        
        // Initially should be in data state
        expect(viewModel.loginState.value, isA<AsyncData<void>>());
        
        // Login
        await viewModel.login('admin@example.com', 'password123');
        
        // Should return to data state after successful login
        expect(viewModel.loginState.value, isA<AsyncData<void>>());
      });

      test('should show loading state during login', () async {
        fakeAuthService.setCredentials('admin@example.com', 'password123');
        
        // Start login
        final loginFuture = viewModel.login('admin@example.com', 'password123');
        
        // Should be in loading state
        expect(viewModel.loginState.value, isA<AsyncLoading<void>>());
        
        // Wait for completion
        await loginFuture;
        
        // Should return to data state
        expect(viewModel.loginState.value, isA<AsyncData<void>>());
      });
    });

    group('Failed Login', () {
      test('should handle invalid credentials error', () async {
        // Login with wrong credentials
        await viewModel.login('wrong@example.com', 'wrongpassword');
        
        // Should be in error state
        expect(viewModel.loginState.value, isA<AsyncError<void>>());
        
        final asyncError = viewModel.loginState.value as AsyncError<void>;
        expect(asyncError.message, contains('Invalid credentials'));
      });

      test('should handle authentication service error', () async {
        fakeAuthService.setShouldThrowError(true);
        
        // Login should fail
        await viewModel.login('admin@example.com', 'password123');
        
        // Should be in error state
        expect(viewModel.loginState.value, isA<AsyncError<void>>());
        
        final asyncError = viewModel.loginState.value as AsyncError<void>;
        expect(asyncError.message, contains('Authentication failed'));
      });

      test('should show toast notification on error', () async {
        fakeAuthService.setShouldThrowError(true);
        
        // Login should fail
        await viewModel.login('admin@example.com', 'password123');
        
        // Should show error toast
        expect(fakeNotifyService.lastEvent, isA<ToastEventError>());
        final toastEvent = fakeNotifyService.lastEvent as ToastEventError;
        expect(toastEvent.message, contains('Ошибка входа'));
      });
    });

    group('Multiple Login Attempts', () {
      test('should handle multiple login attempts', () async {
        fakeAuthService.setCredentials('admin@example.com', 'password123');
        
        // First failed attempt
        await viewModel.login('wrong@example.com', 'wrongpassword');
        expect(viewModel.loginState.value, isA<AsyncError<void>>());
        
        // Second successful attempt
        await viewModel.login('admin@example.com', 'password123');
        expect(viewModel.loginState.value, isA<AsyncData<void>>());
      });

      test('should clear previous error on new login attempt', () async {
        // First failed attempt
        await viewModel.login('wrong@example.com', 'wrongpassword');
        expect(viewModel.loginState.value, isA<AsyncError<void>>());
        
        fakeAuthService.setCredentials('admin@example.com', 'password123');
        
        // Second attempt should start with loading state
        final loginFuture = viewModel.login('admin@example.com', 'password123');
        expect(viewModel.loginState.value, isA<AsyncLoading<void>>());
        
        await loginFuture;
        expect(viewModel.loginState.value, isA<AsyncData<void>>());
      });
    });

    group('Edge Cases', () {
      test('should handle empty email', () async {
        await viewModel.login('', 'password123');
        
        expect(viewModel.loginState.value, isA<AsyncError<void>>());
        expect(fakeNotifyService.lastEvent, isA<ToastEventError>());
      });

      test('should handle empty password', () async {
        await viewModel.login('admin@example.com', '');
        
        expect(viewModel.loginState.value, isA<AsyncError<void>>());
        expect(fakeNotifyService.lastEvent, isA<ToastEventError>());
      });

      test('should handle null inputs gracefully', () async {
        await viewModel.login('', '');
        
        expect(viewModel.loginState.value, isA<AsyncError<void>>());
        expect(fakeNotifyService.lastEvent, isA<ToastEventError>());
      });
    });

    group('Disposal', () {
      test('should dispose without errors', () {
        final viewModel = AuthViewModel(authService: fakeAuthService);
        
        // Should not throw
        expect(() => viewModel.dispose(), returnsNormally);
      });

      test('should dispose loginState notifier', () {
        final viewModel = AuthViewModel(authService: fakeAuthService);
        
        // Access the notifier to ensure it's created
        final notifier = viewModel.loginState;
        expect(notifier, isNotNull);
        
        // Dispose should not throw
        viewModel.dispose();
      });
    });

    group('State Management', () {
      test('should maintain state consistency', () async {
        fakeAuthService.setCredentials('admin@example.com', 'password123');
        
        // Initial state
        expect(viewModel.loginState.value, isA<AsyncData<void>>());
        
        // Login
        await viewModel.login('admin@example.com', 'password123');
        
        // Should still be in data state
        expect(viewModel.loginState.value, isA<AsyncData<void>>());
        
        // Try to login again with wrong credentials
        await viewModel.login('wrong@example.com', 'wrongpassword');
        
        // Should be in error state
        expect(viewModel.loginState.value, isA<AsyncError<void>>());
      });
    });
  });
}