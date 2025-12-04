import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/utils/validators.dart';

void main() {
  group('Validators - Email', () {
    test('email validator returns null for valid email', () {
      expect(Validators.email('test@example.com'), isNull);
      expect(Validators.email('user.name@domain.co.uk'), isNull);
      expect(Validators.email('user+tag@example.org'), isNull);
    });

    test('email validator returns error for invalid email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.email('test@'), isNotNull);
      expect(Validators.email('@example.com'), isNotNull);
      expect(Validators.email('test.example.com'), isNotNull);
    });

    test('email validator returns error for empty email', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email(null), 'Email is required');
    });
  });

  group('Validators - Required', () {
    test('required validator returns null for non-empty value', () {
      expect(Validators.required('test'), isNull);
      expect(Validators.required('   test   '), isNull);
    });

    test('required validator returns error for empty value', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
      expect(Validators.required(null), isNotNull);
    });

    test('required validator uses custom field name', () {
      expect(Validators.required('', fieldName: 'Name'), 'Name is required');
      expect(Validators.required('', fieldName: 'Password'), 'Password is required');
    });
  });

  group('Validators - Min Length', () {
    test('minLength validator returns null for valid length', () {
      expect(Validators.minLength('test', 4), isNull);
      expect(Validators.minLength('testing', 4), isNull);
    });

    test('minLength validator returns error for short value', () {
      expect(Validators.minLength('test', 5), isNotNull);
      expect(Validators.minLength('ab', 3), isNotNull);
    });

    test('minLength validator returns error for empty value', () {
      expect(Validators.minLength('', 5), isNotNull);
      expect(Validators.minLength(null, 5), isNotNull);
    });

    test('minLength validator uses custom field name', () {
      expect(Validators.minLength('ab', 5, fieldName: 'Username'), 'Username must be at least 5 characters');
    });
  });

  group('Validators - Password', () {
    test('password validator returns null for valid password', () {
      expect(Validators.password('password123'), isNull);
      expect(Validators.password('secret'), isNull);
      expect(Validators.password('123456'), isNull);
    });

    test('password validator returns error for short password', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('abc'), isNotNull);
    });

    test('password validator returns error for empty password', () {
      expect(Validators.password(''), 'Password is required');
      expect(Validators.password(null), 'Password is required');
    });
  });

  group('Validators - Phone', () {
    test('phone validator returns null for valid phone', () {
      expect(Validators.phone('+1234567890'), isNull);
      expect(Validators.phone('123-456-7890'), isNull);
      expect(Validators.phone('(123) 456-7890'), isNull);
      expect(Validators.phone('+7 (999) 123-45-67'), isNull);
    });

    test('phone validator returns error for invalid phone', () {
      expect(Validators.phone('invalid-phone'), isNotNull);
      expect(Validators.phone('abc'), isNotNull);
      expect(Validators.phone('12345'), isNotNull); // Too short - less than 6 digits
    });

    test('phone validator returns error for empty phone', () {
      expect(Validators.phone(''), 'Phone number is required');
      expect(Validators.phone(null), 'Phone number is required');
    });
  });

  group('Validators - Date Range', () {
    test('dateRange validator returns null for valid range', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 2);
      
      expect(Validators.dateRange(start, end), isNull);
    });

    test('dateRange validator returns error when end is before start', () {
      final start = DateTime(2025, 1, 2);
      final end = DateTime(2025, 1, 1);
      
      expect(Validators.dateRange(start, end), 'End date must be after start date');
    });

    test('dateRange validator returns error for null dates', () {
      expect(Validators.dateRange(null, DateTime.now()), 'Both dates are required');
      expect(Validators.dateRange(DateTime.now(), null), 'Both dates are required');
      expect(Validators.dateRange(null, null), 'Both dates are required');
    });
  });

  group('Validators - Time Range', () {
    test('timeRange validator returns null for valid range', () {
      final start = DateTime(2025, 1, 1, 9, 0);
      final end = DateTime(2025, 1, 1, 17, 0);
      
      expect(Validators.timeRange(start, end), isNull);
    });

    test('timeRange validator returns error when end is before start', () {
      final start = DateTime(2025, 1, 1, 17, 0);
      final end = DateTime(2025, 1, 1, 9, 0);
      
      expect(Validators.timeRange(start, end), 'End time must be after start time');
    });

    test('timeRange validator returns error when end equals start', () {
      final start = DateTime(2025, 1, 1, 9, 0);
      final end = DateTime(2025, 1, 1, 9, 0);
      
      expect(Validators.timeRange(start, end), 'End time must be after start time');
    });
  });
}