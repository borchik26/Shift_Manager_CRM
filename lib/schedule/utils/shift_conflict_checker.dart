import 'package:my_app/data/models/employee.dart';
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

  /// Employee has too many shifts on the same day
  tooManyShiftsPerDay,

  /// Shift is scheduled in the past
  shiftInPast,

  /// Not enough rest time between shifts
  insufficientRest,
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

  /// Maximum number of shifts per day for one employee
  static const int maxShiftsPerDay = 2;

  /// Minimum rest time between shifts in hours
  static const int minRestHours = 8;

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
  /// - [employeeDesiredDaysOff]: Optional map of employee ID to their desired days off
  /// - [excludeShiftId]: Optional ID of shift to exclude (for updates)
  ///
  /// Returns a list of conflicts found (empty if no conflicts)
  static List<ShiftConflict> checkConflicts({
    required ShiftModel newShift,
    required List<ShiftModel> existingShifts,
    Map<String, List<DesiredDayOff>>? employeeDesiredDaysOff,
    String? excludeShiftId,
  }) {
    final conflicts = <ShiftConflict>[];

    // 1. Check shift duration
    final duration = newShift.durationInHours;
    if (duration < minShiftDuration) {
      conflicts.add(
        ShiftConflict(
          type: ConflictType.invalidDuration,
          message:
              'Смена слишком короткая. Минимум ${minShiftDuration.toStringAsFixed(0)} ч',
          isWarning: false,
        ),
      );
    } else if (duration > maxShiftDuration) {
      conflicts.add(
        ShiftConflict(
          type: ConflictType.invalidDuration,
          message:
              'Смена слишком длинная. Максимум ${maxShiftDuration.toStringAsFixed(0)} ч',
          isWarning: false,
        ),
      );
    }

    // 2. Check if shift is in the past
    final now = DateTime.now();
    if (newShift.startTime.isBefore(now)) {
      conflicts.add(
        ShiftConflict(
          type: ConflictType.shiftInPast,
          message: 'Нельзя создавать смены в прошлом',
          isWarning: true, // Soft warning - can be overridden
        ),
      );
    }

    // 3. Check desired days off
    if (employeeDesiredDaysOff != null &&
        employeeDesiredDaysOff.containsKey(newShift.employeeId)) {
      final desiredDaysOff = employeeDesiredDaysOff[newShift.employeeId]!;

      // Extract date only from shift start time
      final shiftDate = DateTime(
        newShift.startTime.year,
        newShift.startTime.month,
        newShift.startTime.day,
      );

      // Check if any desired day off matches the shift date
      for (final desiredDayOff in desiredDaysOff) {
        final requestedDate = DateTime(
          desiredDayOff.date.year,
          desiredDayOff.date.month,
          desiredDayOff.date.day,
        );

        if (shiftDate.isAtSameMomentAs(requestedDate)) {
          final message = desiredDayOff.comment != null
              ? 'Сотрудник просил выходной: "${desiredDayOff.comment}"'
              : 'Сотрудник просил выходной в этот день';

          conflicts.add(
            ShiftConflict(
              type: ConflictType.timeOffRequest,
              message: message,
              isWarning: true, // Soft warning - can be overridden
            ),
          );
          break; // Only show one warning per shift
        }
      }
    }

    // 4. Check maximum shifts per day
    final shiftDate = DateTime(
      newShift.startTime.year,
      newShift.startTime.month,
      newShift.startTime.day,
    );

    int shiftsOnSameDay = 0;
    for (final existingShift in existingShifts) {
      // Skip if this is the same shift (for updates)
      if (excludeShiftId != null && existingShift.id == excludeShiftId) {
        continue;
      }

      // Only check shifts for the same employee
      if (existingShift.employeeId != newShift.employeeId) {
        continue;
      }

      // Check if shifts are on the same date
      final existingDate = DateTime(
        existingShift.startTime.year,
        existingShift.startTime.month,
        existingShift.startTime.day,
      );

      if (shiftDate.isAtSameMomentAs(existingDate)) {
        shiftsOnSameDay++;
      }
    }

    if (shiftsOnSameDay >= maxShiftsPerDay) {
      conflicts.add(
        ShiftConflict(
          type: ConflictType.tooManyShiftsPerDay,
          message:
              'Сотрудник уже имеет $shiftsOnSameDay ${_getShiftWordForm(shiftsOnSameDay)} в этот день. Максимум: $maxShiftsPerDay',
          isWarning: true, // Soft warning - can be overridden
        ),
      );
    }

    // 5. Check minimum rest time between shifts
    for (final existingShift in existingShifts) {
      // Skip if this is the same shift (for updates)
      if (excludeShiftId != null && existingShift.id == excludeShiftId) {
        continue;
      }

      // Only check shifts for the same employee
      if (existingShift.employeeId != newShift.employeeId) {
        continue;
      }

      // Check rest time before the new shift
      final restBefore = newShift.startTime.difference(existingShift.endTime);
      if (restBefore.isNegative == false &&
          restBefore.inHours < minRestHours &&
          restBefore.inHours >= 0) {
        final restHours = restBefore.inHours;
        final restMinutes = restBefore.inMinutes % 60;
        conflicts.add(
          ShiftConflict(
            type: ConflictType.insufficientRest,
            message:
                'Недостаточно отдыха после смены ${existingShift.timeRange}. Отдых: $restHours ч $restMinutes мин. Минимум: $minRestHours ч',
            conflictingShift: existingShift,
            isWarning: true, // Soft warning - can be overridden
          ),
        );
      }

      // Check rest time after the new shift
      final restAfter = existingShift.startTime.difference(newShift.endTime);
      if (restAfter.isNegative == false &&
          restAfter.inHours < minRestHours &&
          restAfter.inHours >= 0) {
        final restHours = restAfter.inHours;
        final restMinutes = restAfter.inMinutes % 60;
        conflicts.add(
          ShiftConflict(
            type: ConflictType.insufficientRest,
            message:
                'Недостаточно отдыха перед сменой ${existingShift.timeRange}. Отдых: $restHours ч $restMinutes мин. Минимум: $minRestHours ч',
            conflictingShift: existingShift,
            isWarning: true, // Soft warning - can be overridden
          ),
        );
      }
    }

    // 6. Check for overlapping shifts with the same employee
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

        conflicts.add(
          ShiftConflict(
            type: isLocationConflict
                ? ConflictType.locationConflict
                : ConflictType.timeOverlap,
            message: isLocationConflict
                ? 'Конфликт: сотрудник уже работает в "${existingShift.location}" в это время'
                : 'Конфликт: сотрудник уже работает с ${existingShift.timeRange}',
            conflictingShift: existingShift,
            isWarning: false, // Hard error - cannot be overridden
          ),
        );
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

  /// Helper method to get correct word form for "shift" in Russian
  /// Returns proper declension based on the count:
  /// - 1: "смену" (one shift)
  /// - 2-4: "смены" (two-four shifts)
  /// - 5+: "смен" (five or more shifts)
  static String _getShiftWordForm(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'смену';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'смены';
    } else {
      return 'смен';
    }
  }
}
