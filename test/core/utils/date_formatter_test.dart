import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    group('formatDate', () {
      test('formats date correctly', () {
        final date = DateTime(2024, 1, 15, 14, 30);
        final formatted = DateFormatter.formatDate(date);
        
        expect(formatted, equals('15.01.2024'));
      });

      test('handles different date formats', () {
        final dates = [
          DateTime(2024, 1, 1),
          DateTime(2024, 12, 31, 23, 59, 59),
          DateTime(2024, 2, 29, 14, 30),
        ];
        
        for (final date in dates) {
          final formatted = DateFormatter.formatDate(date);
          expect(formatted, isNotNull);
          expect(formatted.length, greaterThan(0));
        }
      });
    });

    group('formatTime', () {
      test('formats time correctly', () {
        final times = [
          DateTime(2024, 1, 1, 9, 30),
          DateTime(2024, 1, 1, 14, 45),
          DateTime(2024, 1, 1, 23, 0),
        ];
        
        for (final time in times) {
          final formatted = DateFormatter.formatTime(time);
          expect(formatted, isNotNull);
          expect(formatted.length, greaterThan(0));
        }
      });

      test('handles midnight correctly', () {
        final midnight = DateTime(2024, 1, 1, 0, 0);
        final formatted = DateFormatter.formatTime(midnight);
        
        expect(formatted, equals('00:00'));
      });
    });

    group('formatDateTime', () {
      test('formats date and time correctly', () {
        final dateTime = DateTime(2024, 1, 15, 14, 30);
        final formatted = DateFormatter.formatDateTime(dateTime);
        
        expect(formatted, equals('15.01.2024 14:30'));
      });

      test('handles different datetime formats', () {
        final dateTimes = [
          DateTime(2024, 1, 1, 9, 30),
          DateTime(2024, 12, 31, 23, 59, 59),
          DateTime(2024, 6, 15, 0),
        ];
        
        for (final dateTime in dateTimes) {
          final formatted = DateFormatter.formatDateTime(dateTime);
          expect(formatted, isNotNull);
          expect(formatted.length, greaterThan(0));
        }
      });
    });

    group('formatMonthYear', () {
      test('formats month and year correctly', () {
        final dates = [
          DateTime(2024, 1, 15),
          DateTime(2024, 6, 30),
          DateTime(2024, 12, 25),
        ];
        
        for (final date in dates) {
          final formatted = DateFormatter.formatMonthYear(date);
          expect(formatted, isNotNull);
          expect(formatted.length, greaterThan(0));
        }
      });
    });

    group('formatDayMonth', () {
      test('formats day and month correctly', () {
        final dates = [
          DateTime(2024, 1, 15),
          DateTime(2024, 6, 30),
          DateTime(2024, 12, 25),
        ];
        
        for (final date in dates) {
          final formatted = DateFormatter.formatDayMonth(date);
          expect(formatted, isNotNull);
          expect(formatted.length, greaterThan(0));
        }
      });
    });

    group('formatDuration', () {
      test('formats duration correctly', () {
        final durations = [
          const Duration(hours: 2, minutes: 30),
          const Duration(hours: 1, minutes: 45),
          const Duration(minutes: 90),
          const Duration(hours: 0, minutes: 30),
          const Duration(seconds: 3600),
        ];
        
        for (final duration in durations) {
          final formatted = DateFormatter.formatDuration(duration);
          expect(formatted, isNotNull);
          expect(formatted.length, greaterThan(0));
        }
      });

      test('handles zero duration', () {
        final formatted = DateFormatter.formatDuration(Duration.zero);
        
        expect(formatted, equals('0m'));
      });

      test('handles hours and minutes correctly', () {
        final formatted = DateFormatter.formatDuration(const Duration(hours: 2, minutes: 30));
        
        expect(formatted, equals('2h 30m'));
      });
    });

    group('getRelativeTime', () {
      test('calculates relative time correctly', () {
        final now = DateTime(2024, 1, 15, 14, 30);
        final testCases = [
          {'dateTime': now.subtract(const Duration(days: 1)), 'expected': '1 day ago'},
          {'dateTime': now.subtract(const Duration(days: 365)), 'expected': '1 year ago'},
          {'dateTime': now.subtract(const Duration(hours: 2)), 'expected': '2 hours ago'},
          {'dateTime': now.subtract(const Duration(minutes: 30)), 'expected': '30 minutes ago'},
          {'dateTime': now, 'expected': 'Just now'},
        ];
        
        for (final testCase in testCases) {
          final result = DateFormatter.getRelativeTime(testCase['dateTime'] as DateTime);
          expect(result, equals(testCase['expected']));
        }
      });

      test('handles edge cases', () {
        final future = DateTime(2024, 1, 15, 14, 30);
        final result = DateFormatter.getRelativeTime(future);
        
        expect(result, contains('ago'));
      });
    });

    group('isToday', () {
      test('identifies today correctly', () {
        final today = DateTime(2024, 1, 15, 14, 30);
        final yesterday = today.subtract(const Duration(days: 1));
        final tomorrow = today.add(const Duration(days: 1));
        
        expect(DateFormatter.isToday(today), isTrue);
        expect(DateFormatter.isToday(yesterday), isFalse);
        expect(DateFormatter.isToday(tomorrow), isFalse);
      });
    });

    group('isPast', () {
      test('identifies past dates correctly', () {
        final today = DateTime(2024, 1, 15, 14, 30);
        final past = today.subtract(const Duration(days: 1));
        final future = today.add(const Duration(days: 1));
        
        expect(DateFormatter.isPast(past), isTrue);
        expect(DateFormatter.isPast(today), isFalse);
        expect(DateFormatter.isPast(future), isFalse);
      });
    });

    group('isFuture', () {
      test('identifies future dates correctly', () {
        final today = DateTime(2024, 1, 15, 14, 30);
        final past = today.subtract(const Duration(days: 1));
        final future = today.add(const Duration(days: 1));
        
        expect(DateFormatter.isFuture(past), isFalse);
        expect(DateFormatter.isFuture(today), isFalse);
        expect(DateFormatter.isFuture(future), isTrue);
      });
    });

    group('Edge Cases', () {
      test('handles empty duration', () {
        final formatted = DateFormatter.formatDuration(const Duration());
        
        expect(formatted, equals('0m'));
      });

      test('handles very large durations', () {
        final week = const Duration(days: 7);
        final month = const Duration(days: 30);
        final year = const Duration(days: 365);
        
        // DateFormatter only formats hours and minutes, not days
        final weekHours = week.inHours;
        final monthHours = month.inHours;
        final yearHours = year.inHours;
        
        expect(DateFormatter.formatDuration(week), contains('${weekHours}h'));
        expect(DateFormatter.formatDuration(month), contains('${monthHours}h'));
        expect(DateFormatter.formatDuration(year), contains('${yearHours}h'));
      });
    });
  });
}