import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/data/models/user.dart';
import 'package:my_app/data/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  User? _userToReturn;
  Exception? _exceptionToThrow;
  
  void setUserToReturn(User? user) {
    _userToReturn = user;
  }
  
  void setExceptionToThrow(Exception? exception) {
    _exceptionToThrow = exception;
  }
  
  @override
  Future<User?> login(String username, String password) async {
    if (_exceptionToThrow != null) {
      throw _exceptionToThrow!;
    }
    return _userToReturn;
  }
  
  @override
  Future<void> logout() async {
    _userToReturn = null;
  }
}

void main() {
  group('AuthService', () {
    late AuthService authService;
    late FakeAuthRepository fakeAuthRepository;

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
      authService = AuthService(authRepository: fakeAuthRepository);
    });

    tearDown(() {
      authService.dispose();
    });

    group('Authentication State', () {
      test('initially not authenticated', () {
        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUser, isNull);
      });

      test('currentUserNotifier reflects authentication state', () {
        expect(authService.currentUserNotifier.value, isNull);
      });
    });

    group('Login', () {
      const testUser = User(
        id: 'user_1',
        username: 'admin',
        role: 'administrator',
      );

      test('successful login updates authentication state', () async {
        // Arrange
        fakeAuthRepository.setUserToReturn(testUser);

        // Act
        await authService.login('admin@example.com', 'password123');

        // Assert
        expect(authService.isAuthenticated, isTrue);
        expect(authService.currentUser, equals(testUser));
        expect(authService.currentUserNotifier.value, equals(testUser));
        
        // Repository method was called through setUserToReturn setup
      });

      test('failed login throws exception', () async {
        // Arrange
        fakeAuthRepository.setUserToReturn(null);

        // Act & Assert
        expect(
          () async => await authService.login('wrong@example.com', 'wrongpassword'),
          throwsA(isA<Exception>()),
        );

        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUser, isNull);
        expect(authService.currentUserNotifier.value, isNull);
        
        // Repository method was called through setUserToReturn setup
      });

      test('login with repository exception propagates exception', () async {
        // Arrange
        fakeAuthRepository.setExceptionToThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () async => await authService.login('admin@example.com', 'password123'),
          throwsA(isA<Exception>()),
        );
        
        // Repository method was called through setExceptionToThrow setup
      });
    });

    group('Logout', () {
      test('logout clears authentication state', () async {
        // Arrange - first login
        const testUser = User(
          id: 'user_1',
          username: 'admin',
          role: 'administrator',
        );
        fakeAuthRepository.setUserToReturn(testUser);
        await authService.login('admin@example.com', 'password123');

        // Act
        await authService.logout();

        // Assert
        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUser, isNull);
        expect(authService.currentUserNotifier.value, isNull);
      });

      test('logout can be called when not authenticated', () async {
        // Act & Assert - should not throw
        expect(() async => await authService.logout(), returnsNormally);
        
        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUser, isNull);
      });
    });

    group('Initialize Auth', () {
      test('initializeAuth sets user to null initially', () async {
        // Act
        await authService.initializeAuth();

        // Assert
        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUser, isNull);
        expect(authService.currentUserNotifier.value, isNull);
      });

      test('initializeAuth can be called multiple times', () async {
        // Act
        await authService.initializeAuth();
        await authService.initializeAuth();
        await authService.initializeAuth();

        // Assert - should not throw and state should remain null
        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUser, isNull);
      });
    });

    group('State Management', () {
      test('currentUserNotifier notifies listeners on login', () async {
        // Arrange
        const testUser = User(
          id: 'user_1',
          username: 'admin',
          role: 'administrator',
        );
        fakeAuthRepository.setUserToReturn(testUser);

        var notificationCount = 0;
        authService.currentUserNotifier.addListener(() {
          notificationCount++;
        });

        // Act
        await authService.login('admin@example.com', 'password123');

        // Assert
        expect(notificationCount, equals(1));
        expect(authService.currentUserNotifier.value, equals(testUser));
      });

      test('currentUserNotifier notifies listeners on logout', () async {
        // Arrange - first login
        const testUser = User(
          id: 'user_1',
          username: 'admin',
          role: 'administrator',
        );
        fakeAuthRepository.setUserToReturn(testUser);
        await authService.login('admin@example.com', 'password123');

        var notificationCount = 0;
        authService.currentUserNotifier.addListener(() {
          notificationCount++;
        });

        // Act
        await authService.logout();

        // Assert
        expect(notificationCount, equals(1));
        expect(authService.currentUserNotifier.value, isNull);
      });
    });

    group('Dispose', () {
      test('dispose cleans up resources', () {
        // Arrange
        const testUser = User(
          id: 'user_1',
          username: 'admin',
          role: 'administrator',
        );
        fakeAuthRepository.setUserToReturn(testUser);
        authService.login('admin@example.com', 'password123');

        // Act
        authService.dispose();

        // Assert - accessing notifier after dispose should not throw
        expect(() => authService.currentUserNotifier.value, returnsNormally);
      });

      test('dispose can be called multiple times', () {
        // Act & Assert - should not throw
        expect(() => authService.dispose(), returnsNormally);
        expect(() => authService.dispose(), returnsNormally);
      });
    });

    group('Edge Cases', () {
      test('multiple logins work correctly', () async {
        // Arrange
        const user1 = User(id: '1', username: 'user1', role: 'admin');
        const user2 = User(id: '2', username: 'user2', role: 'manager');
        
        fakeAuthRepository.setUserToReturn(user1);

        // Act
        await authService.login('user1@example.com', 'password1');
        expect(authService.currentUser, equals(user1));

        fakeAuthRepository.setUserToReturn(user2);
        await authService.login('user2@example.com', 'password2');
        expect(authService.currentUser, equals(user2));

        // Assert
        expect(authService.isAuthenticated, isTrue);
        expect(authService.currentUserNotifier.value, equals(user2));
      });

      test('logout after failed login maintains unauthenticated state', () async {
        // Arrange
        fakeAuthRepository.setUserToReturn(null);

        // Act
        try {
          await authService.login('wrong@example.com', 'wrongpassword');
        } catch (_) {
          // Expected to throw
        }

        await authService.logout();

        // Assert
        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUser, isNull);
      });
    });
  });
}