import 'package:my_app/data/models/employee.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/models/date_range_filter.dart';
import 'package:my_app/schedule/models/shift_status_filter.dart';
import 'package:my_app/schedule/utils/shift_conflict_checker.dart';

class ShiftFilter {
  static List<ShiftModel> apply({
    required List<ShiftModel> shifts,
    required List<Employee> employees,
    String? searchQuery,
    String? employeeFilter,
    String? locationFilter,
    String? roleFilter,
    DateTime? dateFilter,
    DateRangeFilter dateRangeFilter = DateRangeFilter.all,
    ShiftStatusFilter statusFilter = ShiftStatusFilter.all,
    bool isEmployee = false,
    String? currentUserId,
  }) {
    var filteredShifts = shifts;

    if (isEmployee && currentUserId != null) {
      filteredShifts = filteredShifts.where((s) => s.employeeId == currentUserId).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final filteredEmployees = employees.where((e) {
        return e.fullName.toLowerCase().contains(query);
      }).toList();

      filteredShifts = filteredShifts.where((s) {
        final matchesShift = s.roleTitle.toLowerCase().contains(query) ||
            s.location.toLowerCase().contains(query);
        final matchesEmployee = filteredEmployees.any((e) => e.id == s.employeeId);
        return matchesShift || matchesEmployee;
      }).toList();
    }

    if (employeeFilter != null) {
      filteredShifts = filteredShifts.where((s) => s.employeeId == employeeFilter).toList();
    }

    if (locationFilter != null) {
      filteredShifts = filteredShifts.where((s) => s.location == locationFilter).toList();
    }

    if (roleFilter != null) {
      filteredShifts = filteredShifts.where((s) => s.roleTitle == roleFilter).toList();
    }

    if (dateFilter != null) {
      filteredShifts = filteredShifts.where((s) {
        final shiftDate = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
        final filterDate = DateTime(dateFilter.year, dateFilter.month, dateFilter.day);
        return shiftDate.isAtSameMomentAs(filterDate);
      }).toList();
    }

    if (dateRangeFilter != DateRangeFilter.all) {
      final startDate = dateRangeFilter.getStartDate();
      final endDate = dateRangeFilter.getEndDate();

      if (startDate != null && endDate != null) {
        filteredShifts = filteredShifts.where((s) {
          return s.startTime.isAfter(startDate) && s.startTime.isBefore(endDate);
        }).toList();
      }
    }

    if (statusFilter != ShiftStatusFilter.all) {
      filteredShifts = filteredShifts.where((s) {
        final conflicts = ShiftConflictChecker.checkConflicts(
          newShift: s,
          existingShifts: shifts,
          excludeShiftId: s.id,
        );

        switch (statusFilter) {
          case ShiftStatusFilter.withConflicts:
            return ShiftConflictChecker.hasHardErrors(conflicts);
          case ShiftStatusFilter.withWarnings:
            return ShiftConflictChecker.hasWarnings(conflicts);
          case ShiftStatusFilter.normal:
            return !ShiftConflictChecker.hasHardErrors(conflicts) &&
                !ShiftConflictChecker.hasWarnings(conflicts);
          case ShiftStatusFilter.all:
            return true;
        }
      }).toList();
    }

    return filteredShifts;
  }
}
