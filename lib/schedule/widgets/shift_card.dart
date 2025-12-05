import 'package:flutter/material.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/viewmodels/schedule_view_model.dart';
import 'package:my_app/schedule/widgets/create_shift_dialog.dart';

/// Individual shift card for mobile schedule grid cells
/// Displays: Employee name, time range, location, duration
/// Size: 92px width × 70-80px height (compact for mobile)
class ShiftCard extends StatelessWidget {
  final ShiftModel shift;
  final ScheduleViewModel viewModel;

  const ShiftCard({
    required this.shift,
    required this.viewModel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final employeeName = viewModel.getEmployeeNameById(shift.employeeId) ??
        'Свободная смена';

    return GestureDetector(
      onTap: () => _showEditShiftDialog(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: shift.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: shift.color,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee name - with text wrapping
            Text(
              employeeName,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Time range - with Expanded to prevent overflow
            Row(
              children: [
                Icon(Icons.access_time, size: 9, color: Colors.grey.shade600),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    shift.timeRange,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 2),

            // Location - already has Expanded
            Row(
              children: [
                Icon(Icons.place, size: 9, color: Colors.grey.shade600),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    shift.location,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 2),

            // Duration badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: shift.color,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '${shift.durationInHours.toStringAsFixed(0)}ч',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show edit shift dialog on tap
  void _showEditShiftDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => CreateShiftDialog(
        existingShift: shift,
      ),
    );

    if (result == true) {
      // Dialog returned true - shift was updated/deleted
      // Trigger viewModel refresh via notifyListeners
      viewModel.refreshShifts();
    }
  }
}
