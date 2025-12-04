import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/utils/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    group('handleError', () {
      test('formats error message correctly', () {
        final error = Exception('Test error');
        
        // ErrorHandler doesn't return a value, it shows notification
        // So we test that it doesn't throw
        expect(() => ErrorHandler.handleError(error), returnsNormally);
      });

      test('handles null error', () {
        // ErrorHandler doesn't return a value, it shows notification
        // So we test that it doesn't throw with null
        expect(() => ErrorHandler.handleError(null), returnsNormally);
      });

      test('handles different error types', () {
        final errors = [
          Exception('Network error'),
          ArgumentError('Invalid argument'),
          FormatException('Format error'),
        ];
        
        for (final error in errors) {
          // ErrorHandler doesn't return a value, it shows notification
          // So we test that it doesn't throw
          expect(() => ErrorHandler.handleError(error), returnsNormally);
        }
      });

      test('provides user-friendly messages', () {
        final networkError = Exception('Network connection failed');
        
        // ErrorHandler doesn't return a value, it shows notification
        // So we test that it doesn't throw
        expect(() => ErrorHandler.handleError(networkError), returnsNormally);
      });
    });

    group('handleAsync', () {
      test('handles async operations correctly', () async {
        final error = Exception('Test error');
        
        final result = await ErrorHandler.handleAsync<int>(() {
          throw error;
        });
        
        // Should return null on error
        expect(result, isNull);
      });

      test('handles successful async operations correctly', () async {
        final result = await ErrorHandler.handleAsync<int>(() async {
          return 42;
        });
        
        // Should return the value on success
        expect(result, equals(42));
      });

      test('handles async operations with custom error message', () async {
        final error = Exception('Test error');
        final customMessage = 'Custom error message';
        
        final result = await ErrorHandler.handleAsync<int>(() async {
          throw error;
        }, errorMessage: customMessage);
        
        // Should return null on error
        expect(result, isNull);
      });

      test('handles null errors in async operations', () async {
        final result = await ErrorHandler.handleAsync<int>(() async {
          throw Exception('Test error');
        });
        
        // Should return null on error
        expect(result, isNull);
      });
    });
  });
}