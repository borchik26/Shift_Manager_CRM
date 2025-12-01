import 'package:my_app/schedule/models/shift_model.dart';

/// Types of conflicts that can occur when scheduling shifts
enum ConflictType {
  /// Employee is scheduled for overlapping time periods
  timeOverlap,

  /// Employee is at different locations at the same time
  locationConflict,

  /// Employee requested time off
  timeOffRequest,

  /// Shift duration is too short or too long
  invalidDuration,
}

/// Represents a scheduling conflict with details
class ShiftConflict {
  final ConflictType type;
  final String message;
  final ShiftModel? conflictingShift;
  final bool isWarning; // true for soft warnings, false for hard errors

  const ShiftConflict({
    required this.type,
    required this.message,
    this.conflictingShift,
    this.isWarning = false,
  });
}

/// Utility class for checking shift scheduling conflicts
class ShiftConflictChecker {
  /// Minimum shift duration in hours
  static const double minShiftDuration = 2.0;

  /// Maximum shift duration in hours
  static const double maxShiftDuration = 12.0;

  /// Check if two time ranges overlap
  /// Returns true if [start1, end1] overlaps with [start2, end2]
  static bool doTimeRangesOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    // Two ranges overlap if:
    // - start1 is before end2 AND
    // - end1 is after start2
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  /// Check all possible conflicts for a new or updated shift
  ///
  /// Parameters:
  /// - [newShift]: The shift to check for conflicts
  /// - [existingShifts]: List of all existing shifts
  /// - [timeOffRequests]: Optional list of employee IDs who requested time off
  /// - [excludeShiftId]: Optional ID of shift to exclude (for updates)
  ///
  /// Returns a list of conflicts found (empty if no conflicts)
  static List<ShiftConflict> checkConflicts({
    required ShiftModel newShift,
    required List<ShiftModel> existingShifts,
    List<String>? timeOffRequests,
    String? excludeShiftId,
  }) {
    final conflicts = <ShiftConflict>[];

    // 1. Check shift duration
    final duration = newShift.durationInHours;
    if (duration < minShiftDuration) {
      conflicts.add(ShiftConflict(
        type: ConflictType.invalidDuration,
        message: 'Смена слишком короткая. Минимум ${minShiftDuration.toStringAsFixed(0)} ч',
        isWarning: false,
      ));
    } else if (duration > maxShiftDuration) {
      conflicts.add(ShiftConflict(
        type: ConflictType.invalidDuration,
        message: 'Смена слишком длинная. Максимум ${maxShiftDuration.toStringAsFixed(0)} ч',
        isWarning: false,
      ));
    }

    // 2. Check time off requests
    if (timeOffRequests != null && timeOffRequests.contains(newShift.employeeId)) {
      conflicts.add(ShiftConflict(
        type: ConflictType.timeOffRequest,
        message: 'Сотрудник просил выходной в этот день',
        isWarning: true, // Soft warning - can be overridden
      ));
    }

    // 3. Check for overlapping shifts with the same employee
    for (final existingShift in existingShifts) {
      // Skip if this is the same shift (for updates)
      if (excludeShiftId != null && existingShift.id == excludeShiftId) {
        continue;
      }

      // Only check shifts for the same employee
      if (existingShift.employeeId != newShift.employeeId) {
        continue;
      }

      // Check for time overlap
      if (doTimeRangesOverlap(
        newShift.startTime,
        newShift.endTime,
        existingShift.startTime,
        existingShift.endTime,
      )) {
        // Check if it's also a location conflict
        final isLocationConflict = existingShift.location != newShift.location;

        conflicts.add(ShiftConflict(
          type: isLocationConflict
              ? ConflictType.locationConflict
              : ConflictType.timeOverlap,
          message: isLocationConflict
              ? 'Конфликт: сотрудник уже работает в "${existingShift.location}" в это время'
              : 'Конфликт: сотрудник уже работает с ${existingShift.timeRange}',
          conflictingShift: existingShift,
          isWarning: false, // Hard error - cannot be overridden
        ));
      }
    }

    return conflicts;
  }

  /// Check if there are any hard errors (non-warning conflicts)
  static bool hasHardErrors(List<ShiftConflict> conflicts) {
    return conflicts.any((c) => !c.isWarning);
  }

  /// Check if there are any soft warnings
  static bool hasWarnings(List<ShiftConflict> conflicts) {
    return conflicts.any((c) => c.isWarning);
  }

  /// Get all hard errors from conflict list
  static List<ShiftConflict> getHardErrors(List<ShiftConflict> conflicts) {
    return conflicts.where((c) => !c.isWarning).toList();
  }

  /// Get all warnings from conflict list
  static List<ShiftConflict> getWarnings(List<ShiftConflict> conflicts) {
    return conflicts.where((c) => c.isWarning).toList();
  }
}
