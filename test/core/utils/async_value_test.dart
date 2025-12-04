import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/utils/async_value.dart';

void main() {
  group('AsyncValue', () {
    group('AsyncLoading', () {
      test('should create loading state', () {
        const loading = AsyncLoading<String>();
        
        expect(loading, isA<AsyncLoading<String>>());
        expect(loading.isLoading, isTrue);
        expect(loading.hasData, isFalse);
        expect(loading.hasError, isFalse);
        expect(loading.dataOrNull, isNull);
        expect(loading.errorOrNull, isNull);
      });

      test('should work with different types', () {
        const intLoading = AsyncLoading<int>();
        const boolLoading = AsyncLoading<bool>();
        const listLoading = AsyncLoading<List<String>>();
        
        expect(intLoading, isA<AsyncLoading<int>>());
        expect(boolLoading, isA<AsyncLoading<bool>>());
        expect(listLoading, isA<AsyncLoading<List<String>>>());
      });
    });

    group('AsyncData', () {
      test('should create data state', () {
        const data = AsyncData('test data');
        
        expect(data, isA<AsyncData<String>>());
        expect(data.isLoading, isFalse);
        expect(data.hasData, isTrue);
        expect(data.hasError, isFalse);
        expect(data.data, 'test data');
        expect(data.dataOrNull, 'test data');
        expect(data.errorOrNull, isNull);
      });

      test('should handle null data', () {
        const data = AsyncData<String?>(null);
        
        expect(data, isA<AsyncData<String?>>());
        expect(data.isLoading, isFalse);
        expect(data.hasData, isTrue);
        expect(data.hasError, isFalse);
        expect(data.data, isNull);
        expect(data.dataOrNull, isNull);
        expect(data.errorOrNull, isNull);
      });

      test('should work with complex types', () {
        final user = User(id: '1', username: 'test', role: 'admin');
        final data = AsyncData(user);
        
        expect(data, isA<AsyncData<User>>());
        expect(data.data, user);
        expect(data.dataOrNull, user);
      });
    });

    group('AsyncError', () {
      test('should create error state', () {
        const error = AsyncError('Test error');
        
        expect(error, isA<AsyncError<String>>());
        expect(error.isLoading, isFalse);
        expect(error.hasData, isFalse);
        expect(error.hasError, isTrue);
        expect(error.message, 'Test error');
        expect(error.error, isNull);
        expect(error.stackTrace, isNull);
        expect(error.dataOrNull, isNull);
        expect(error.errorOrNull, 'Test error');
      });

      test('should create error state with exception and stack trace', () {
        final exception = Exception('Detailed error');
        final stackTrace = StackTrace.current;
        final error = AsyncError('Detailed error', exception, stackTrace);
        
        expect(error, isA<AsyncError<String>>());
        expect(error.message, 'Detailed error');
        expect(error.error, exception);
        expect(error.stackTrace, stackTrace);
      });
    });

    group('AsyncValueX Extensions', () {
      group('map method', () {
        test('should map data state', () {
          const data = AsyncData(42);
          final mapped = data.map((value) => value * 2);
          
          expect(mapped, isA<AsyncData<int>>());
          expect((mapped as AsyncData<int>).data, 84);
        });

        test('should preserve loading state through map', () {
          const loading = AsyncLoading<int>();
          final mapped = loading.map((value) => value * 2);
          
          expect(mapped, isA<AsyncLoading<int>>());
        });

        test('should preserve error state through map', () {
          final error = AsyncError<int>('Error', Exception('test'));
          final mapped = error.map((value) => value * 2);
          
          expect(mapped, isA<AsyncError<int>>());
          expect((mapped as AsyncError<int>).message, 'Error');
        });

        test('should handle transformation exceptions', () {
          const data = AsyncData('test');
          final mapped = data.map((value) {
            if (value == 'test') {
              throw Exception('Transform failed');
            }
            return 'transformed';
          });
          
          expect(mapped, isA<AsyncError<String>>());
          final errorState = mapped as AsyncError<String>;
          expect(errorState.message, 'Transform failed');
        });
      });

      group('when method', () {
        test('should execute loading callback for loading state', () {
          const loading = AsyncLoading<String>();
          var callbackExecuted = false;
          
          final result = loading.when(
            loading: () {
              callbackExecuted = true;
              return 'loading';
            },
            data: (data) => 'data: $data',
            error: (error) => 'error: $error',
          );
          
          expect(callbackExecuted, isTrue);
          expect(result, 'loading');
        });

        test('should execute data callback for data state', () {
          const data = AsyncData('test data');
          var callbackExecuted = false;
          String? capturedData;
          
          final result = data.when(
            loading: () => 'loading',
            data: (dataValue) {
              callbackExecuted = true;
              capturedData = dataValue;
              return 'data: $dataValue';
            },
            error: (error) => 'error: $error',
          );
          
          expect(callbackExecuted, isTrue);
          expect(capturedData, 'test data');
          expect(result, 'data: test data');
        });

        test('should execute error callback for error state', () {
          const error = AsyncError('test error');
          var callbackExecuted = false;
          String? capturedError;
          
          final result = error.when(
            loading: () => 'loading',
            data: (data) => 'data: $data',
            error: (errorValue) {
              callbackExecuted = true;
              capturedError = errorValue;
              return 'error: $errorValue';
            },
          );
          
          expect(callbackExecuted, isTrue);
          expect(capturedError, 'test error');
          expect(result, 'error: test error');
        });

        test('should work with complex return types', () {
          const data = AsyncData(42);
          final result = data.when(
            loading: () => 0,
            data: (value) => value * 2,
            error: (error) => -1,
          );
          
          expect(result, 84);
        });
      });

      group('Property getters', () {
        test('isLoading should work correctly', () {
          const loading = AsyncLoading<String>();
          const data = AsyncData('test');
          const error = AsyncError('error');
          
          expect(loading.isLoading, isTrue);
          expect(data.isLoading, isFalse);
          expect(error.isLoading, isFalse);
        });

        test('hasData should work correctly', () {
          const loading = AsyncLoading<String>();
          const data = AsyncData('test');
          const error = AsyncError('error');
          
          expect(loading.hasData, isFalse);
          expect(data.hasData, isTrue);
          expect(error.hasData, isFalse);
        });

        test('hasError should work correctly', () {
          const loading = AsyncLoading<String>();
          const data = AsyncData('test');
          const error = AsyncError('error');
          
          expect(loading.hasError, isFalse);
          expect(data.hasError, isFalse);
          expect(error.hasError, isTrue);
        });

        test('dataOrNull should work correctly', () {
          const loading = AsyncLoading<String>();
          const data = AsyncData('test');
          const error = AsyncError('error');
          
          expect(loading.dataOrNull, isNull);
          expect(data.dataOrNull, 'test');
          expect(error.dataOrNull, isNull);
        });

        test('errorOrNull should work correctly', () {
          const loading = AsyncLoading<String>();
          const data = AsyncData('test');
          const error = AsyncError('error message');
          
          expect(loading.errorOrNull, isNull);
          expect(data.errorOrNull, isNull);
          expect(error.errorOrNull, 'error message');
        });
      });
    });

    group('Type Safety', () {
      test('should maintain type safety through operations', () {
        const data = AsyncData<List<String>>(['item1', 'item2']);
        
        final mapped = data.map((list) => list.length);
        expect(mapped, isA<AsyncData<int>>());
        expect((mapped as AsyncData<int>).data, 2);
      });

      test('should handle nullable types correctly', () {
        const data = AsyncData<String?>(null);
        
        final result = data.when(
          loading: () => 'loading',
          data: (value) => value ?? 'default',
          error: (error) => 'error: $error',
        );
        
        expect(result, 'default');
      });
    });

    group('Edge Cases', () {
      test('should handle empty string data', () {
        const data = AsyncData('');
        
        expect(data.hasData, isTrue);
        expect(data.data, '');
        expect(data.dataOrNull, '');
      });

      test('should handle empty error message', () {
        const error = AsyncError('');
        
        expect(error.hasError, isTrue);
        expect(error.message, '');
        expect(error.errorOrNull, '');
      });

      test('should handle zero values', () {
        const data = AsyncData(0);
        
        expect(data.hasData, isTrue);
        expect(data.data, 0);
        
        final mapped = data.map((value) => value + 1);
        expect((mapped as AsyncData<int>).data, 1);
      });
    });
  });
}

// Helper class for testing
class User {
  final String id;
  final String username;
  final String role;
  
  const User({
    required this.id,
    required this.username,
    required this.role,
  });
}