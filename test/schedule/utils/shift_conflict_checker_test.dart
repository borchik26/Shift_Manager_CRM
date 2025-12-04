import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/utils/shift_conflict_checker.dart';

void main() {
  group('ShiftConflictChecker - Time Overlap', () {
    test('doTimeRangesOverlap returns true for overlapping ranges', () {
      final start1 = DateTime(2025, 1, 1, 9, 0);
      final end1 = DateTime(2025, 1, 1, 17, 0);
      final start2 = DateTime(2025, 1, 1, 15, 0);
      final end2 = DateTime(2025, 1, 1, 23, 0);

      expect(
        ShiftConflictChecker.doTimeRangesOverlap(start1, end1, start2, end2),
        isTrue,
      );
    });

    test('doTimeRangesOverlap returns false for non-overlapping ranges', () {
      final start1 = DateTime(2025, 1, 1, 9, 0);
      final end1 = DateTime(2025, 1, 1, 17, 0);
      final start2 = DateTime(2025, 1, 1, 18, 0);
      final end2 = DateTime(2025, 1, 1, 23, 0);

      expect(
        ShiftConflictChecker.doTimeRangesOverlap(start1, end1, start2, end2),
        isFalse,
      );
    });

    test('doTimeRangesOverlap returns true when one range contains another', () {
      final start1 = DateTime(2025, 1, 1, 9, 0);
      final end1 = DateTime(2025, 1, 1, 17, 0);
      final start2 = DateTime(2025, 1, 1, 10, 0);
      final end2 = DateTime(2025, 1, 1, 12, 0);

      expect(
        ShiftConflictChecker.doTimeRangesOverlap(start1, end1, start2, end2),
        isTrue,
      );
    });
  });

  group('ShiftConflictChecker - Duration Validation', () {
    test('checkConflicts returns error for shift duration < 2 hours', () {
      final shift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 10, 0), // 1 hour
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: shift,
        existingShifts: [],
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].type, ConflictType.invalidDuration);
      expect(conflicts[0].isWarning, isFalse);
    });

    test('checkConflicts returns error for shift duration > 12 hours', () {
      final shift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 22, 0), // 13 hours
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: shift,
        existingShifts: [],
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].type, ConflictType.invalidDuration);
      expect(conflicts[0].isWarning, isFalse);
    });

    test('checkConflicts returns no error for valid shift duration', () {
      final shift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0), // 8 hours
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: shift,
        existingShifts: [],
      );

      expect(conflicts.isEmpty, isTrue);
    });
  });

  group('ShiftConflictChecker - Time Off Requests', () {
    test('checkConflicts returns warning for desired day off', () {
      final shift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final desiredDaysOff = {
        'emp1': [
          DesiredDayOff(
            date: DateTime(2025, 1, 1),
            comment: 'Хочу побыть с семьей',
          ),
        ],
      };

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: shift,
        existingShifts: [],
        employeeDesiredDaysOff: desiredDaysOff,
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].type, ConflictType.timeOffRequest);
      expect(conflicts[0].isWarning, isTrue);
      expect(conflicts[0].message, contains('Хочу побыть с семьей'));
    });

    test('checkConflicts returns warning for desired day off without comment', () {
      final shift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final desiredDaysOff = {
        'emp1': [
          DesiredDayOff(date: DateTime(2025, 1, 1)),
        ],
      };

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: shift,
        existingShifts: [],
        employeeDesiredDaysOff: desiredDaysOff,
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].type, ConflictType.timeOffRequest);
      expect(conflicts[0].isWarning, isTrue);
      expect(conflicts[0].message, contains('Сотрудник просил выходной в этот день'));
    });

    test('checkConflicts ignores desired day off for different employee', () {
      final shift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final desiredDaysOff = {
        'emp2': [
          DesiredDayOff(date: DateTime(2025, 1, 1)),
        ],
      };

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: shift,
        existingShifts: [],
        employeeDesiredDaysOff: desiredDaysOff,
      );

      expect(conflicts.isEmpty, isTrue);
    });
  });

  group('ShiftConflictChecker - Overlapping Shifts', () {
    test('checkConflicts detects time overlap for same employee', () {
      final newShift = ShiftModel(
        id: '2',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 15, 0),
        endTime: DateTime(2025, 1, 1, 23, 0),
        roleTitle: 'Test',
        location: 'Location A',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Location A',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [existingShift],
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].type, ConflictType.timeOverlap);
      expect(conflicts[0].isWarning, isFalse);
      expect(conflicts[0].conflictingShift, existingShift);
    });

    test('checkConflicts detects location conflict for overlapping shifts', () {
      final newShift = ShiftModel(
        id: '2',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 15, 0),
        endTime: DateTime(2025, 1, 1, 23, 0),
        roleTitle: 'Test',
        location: 'Location B',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Location A',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [existingShift],
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].type, ConflictType.locationConflict);
      expect(conflicts[0].isWarning, isFalse);
    });

    test('checkConflicts ignores shifts for different employees', () {
      final newShift = ShiftModel(
        id: '2',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 15, 0),
        endTime: DateTime(2025, 1, 1, 23, 0),
        roleTitle: 'Test',
        location: 'Location A',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp2', // Different employee
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Location A',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [existingShift],
      );

      expect(conflicts.isEmpty, isTrue);
    });

    test('checkConflicts excludes shift with excludeShiftId', () {
      final newShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 15, 0),
        endTime: DateTime(2025, 1, 1, 23, 0),
        roleTitle: 'Test',
        location: 'Location A',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Location A',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [existingShift],
        excludeShiftId: '1', // Exclude this shift
      );

      expect(conflicts.isEmpty, isTrue);
    });
  });

  group('ShiftConflictChecker - Helper Methods', () {
    final hardError = ShiftConflict(
      type: ConflictType.timeOverlap,
      message: 'Hard error',
      isWarning: false,
    );

    final warning = ShiftConflict(
      type: ConflictType.timeOffRequest,
      message: 'Warning',
      isWarning: true,
    );

    test('hasHardErrors returns true when there are hard errors', () {
      expect(ShiftConflictChecker.hasHardErrors([hardError, warning]), isTrue);
    });

    test('hasHardErrors returns false when there are only warnings', () {
      expect(ShiftConflictChecker.hasHardErrors([warning]), isFalse);
    });

    test('hasWarnings returns true when there are warnings', () {
      expect(ShiftConflictChecker.hasWarnings([hardError, warning]), isTrue);
    });

    test('hasWarnings returns false when there are only hard errors', () {
      expect(ShiftConflictChecker.hasWarnings([hardError]), isFalse);
    });

    test('getHardErrors filters only hard errors', () {
      final errors = ShiftConflictChecker.getHardErrors([hardError, warning]);
      expect(errors.length, 1);
      expect(errors[0].isWarning, isFalse);
    });

    test('getWarnings filters only warnings', () {
      final warnings = ShiftConflictChecker.getWarnings([hardError, warning]);
      expect(warnings.length, 1);
      expect(warnings[0].isWarning, isTrue);
    });
  });

  group('ShiftConflictChecker - Additional Edge Cases', () {
    test('checkConflicts should handle empty existing shifts list', () {
      final newShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [],
      );

      expect(conflicts.isEmpty, isTrue);
    });

    test('checkConflicts should handle minimum rest time edge case', () {
      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      // New shift starts exactly 8 hours after existing shift ends
      final newShift = ShiftModel(
        id: '2',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 2, 1, 0), // Next day 1:00 AM
        endTime: DateTime(2025, 1, 2, 9, 0),   // Next day 9:00 AM
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [existingShift],
      );

      expect(conflicts.isEmpty, isTrue);
    });

    test('checkConflicts should detect insufficient rest time edge case', () {
      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      // New shift starts less than 8 hours after existing shift ends
      final newShift = ShiftModel(
        id: '2',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 23, 0), // Same day 11:00 PM
        endTime: DateTime(2025, 1, 2, 7, 0),   // Next day 7:00 AM
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [existingShift],
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].type, ConflictType.insufficientRest);
      expect(conflicts[0].isWarning, isTrue);
    });

    test('checkConflicts should handle multiple desired days off', () {
      final newShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final desiredDaysOff = {
        'emp1': [
          DesiredDayOff(date: DateTime(2025, 1, 1), // Same day as shift
            comment: 'Personal day off',
          ),
          DesiredDayOff(date: DateTime(2025, 1, 2)), // Different day
        ],
      };

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [],
        employeeDesiredDaysOff: desiredDaysOff,
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].type, ConflictType.timeOffRequest);
      expect(conflicts[0].isWarning, isTrue);
      expect(conflicts[0].message, contains('Personal day off'));
    });

    test('checkConflicts should handle maximum shifts per day edge case', () {
      final existingShifts = [
        ShiftModel(
          id: '1',
          employeeId: 'emp1',
          startTime: DateTime(2025, 1, 1, 9, 0),
          endTime: DateTime(2025, 1, 1, 17, 0),
          roleTitle: 'Test',
          location: 'Test Location',
          color: Colors.blue,
          hourlyRate: 100.0,
        ),
        ShiftModel(
          id: '2',
          employeeId: 'emp1',
          startTime: DateTime(2025, 1, 1, 18, 0),
          endTime: DateTime(2025, 1, 1, 23, 0),
          roleTitle: 'Test',
          location: 'Test Location',
          color: Colors.blue,
          hourlyRate: 100.0,
        ),
      ];

      // Third shift on same day
      final newShift = ShiftModel(
        id: '3',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 23, 30),
        endTime: DateTime(2025, 1, 2, 7, 0),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: existingShifts,
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].type, ConflictType.tooManyShiftsPerDay);
      expect(conflicts[0].isWarning, isTrue);
    });

    test('checkConflicts should handle exact time overlap edge case', () {
      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      // New shift starts exactly when existing shift ends
      final newShift = ShiftModel(
        id: '2',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 17, 0), // Same time as existing end
        endTime: DateTime(2025, 1, 2, 1, 0),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [existingShift],
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].type, ConflictType.timeOverlap);
      expect(conflicts[0].isWarning, isFalse);
    });

    test('checkConflicts should handle boundary time overlap', () {
      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      // New shift overlaps by 1 minute
      final newShift = ShiftModel(
        id: '2',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 16, 59), // 1 minute before existing ends
        endTime: DateTime(2025, 1, 2, 0, 0),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [existingShift],
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].type, ConflictType.timeOverlap);
      expect(conflicts[0].isWarning, isFalse);
    });

    test('checkConflicts should handle shift exactly at minimum duration', () {
      final newShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 11, 0), // Exactly 2 hours
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [],
      );

      expect(conflicts.isEmpty, isTrue);
    });

    test('checkConflicts should handle shift exactly at maximum duration', () {
      final newShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 21, 0), // Exactly 12 hours
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [],
      );

      expect(conflicts.isEmpty, isTrue);
    });

    test('checkConflicts should handle shift in distant past', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 30));
      final newShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: pastDate,
        endTime: pastDate.add(const Duration(hours: 8)),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [],
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].type, ConflictType.shiftInPast);
      expect(conflicts[0].isWarning, isTrue);
    });

    test('checkConflicts should handle multiple conflicts of different types', () {
      final existingShifts = [
        ShiftModel(
          id: '1',
          employeeId: 'emp1',
          startTime: DateTime(2025, 1, 1, 9, 0),
          endTime: DateTime(2025, 1, 1, 17, 0),
          roleTitle: 'Test',
          location: 'Location A',
          color: Colors.blue,
          hourlyRate: 100.0,
        ),
      ];

      final desiredDaysOff = {
        'emp1': [
          DesiredDayOff(date: DateTime(2025, 1, 1)),
        ],
      };

      // New shift with multiple issues: too short, overlaps, on requested day off
      final newShift = ShiftModel(
        id: '2',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 10, 0), // Overlaps with existing
        endTime: DateTime(2025, 1, 1, 11, 0),    // Too short (1 hour)
        roleTitle: 'Test',
        location: 'Location B', // Different location
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: existingShifts,
        employeeDesiredDaysOff: desiredDaysOff,
      );

      expect(conflicts.length, 3);
      
      final conflictTypes = conflicts.map((c) => c.type).toSet();
      expect(conflictTypes, contains(ConflictType.invalidDuration));
      expect(conflictTypes, contains(ConflictType.locationConflict));
      expect(conflictTypes, contains(ConflictType.timeOffRequest));
    });
  });

  group('ShiftConflictChecker - Multiple Conflicts', () {
    test('checkConflicts returns multiple conflicts', () {
      final newShift = ShiftModel(
        id: '3',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 15, 0),
        endTime: DateTime(2025, 1, 1, 16, 0), // Too short (1 hour)
        roleTitle: 'Test',
        location: 'Location B',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Location A',
        color: Colors.blue,
        hourlyRate: 100.0,
      );

      final desiredDaysOff = {
        'emp1': [
          DesiredDayOff(date: DateTime(2025, 1, 1)),
        ],
      };

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [existingShift],
        employeeDesiredDaysOff: desiredDaysOff,
      );

      // Should have 3 conflicts: duration, time off, location
      expect(conflicts.length, 3);
      expect(
        conflicts.any((c) => c.type == ConflictType.invalidDuration),
        isTrue,
      );
      expect(
        conflicts.any((c) => c.type == ConflictType.timeOffRequest),
        isTrue,
      );
      expect(
        conflicts.any((c) => c.type == ConflictType.locationConflict),
        isTrue,
      );
    });
  });
}