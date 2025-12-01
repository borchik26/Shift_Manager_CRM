import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: shift,
        existingShifts: [],
      );

      expect(conflicts.isEmpty, isTrue);
    });
  });

  group('ShiftConflictChecker - Time Off Requests', () {
    test('checkConflicts returns warning for time off request', () {
      final shift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Test Location',
        color: Colors.blue,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: shift,
        existingShifts: [],
        timeOffRequests: ['emp1'],
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].type, ConflictType.timeOffRequest);
      expect(conflicts[0].isWarning, isTrue);
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
      );

      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Location A',
        color: Colors.blue,
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
      );

      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Location A',
        color: Colors.blue,
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
      );

      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp2', // Different employee
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Location A',
        color: Colors.blue,
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
      );

      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Location A',
        color: Colors.blue,
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
      );

      final existingShift = ShiftModel(
        id: '1',
        employeeId: 'emp1',
        startTime: DateTime(2025, 1, 1, 9, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        roleTitle: 'Test',
        location: 'Location A',
        color: Colors.blue,
      );

      final conflicts = ShiftConflictChecker.checkConflicts(
        newShift: newShift,
        existingShifts: [existingShift],
        timeOffRequests: ['emp1'],
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
