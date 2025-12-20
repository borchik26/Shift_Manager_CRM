import 'package:flutter/material.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/viewmodels/schedule_view_model.dart';
import 'package:my_app/schedule/widgets/shift_card.dart';

/// Shift cell for mobile schedule grid
/// Displays either empty state (+ icon) or list of shift cards
///
/// Behavior:
/// - Empty (0 shifts): Shows "+" icon, light gray background, tappable
/// - With shifts: Shows all shift cards stacked vertically, expandable height
/// - Min height: 60px, Max height: unlimited (expands)
class ShiftCell extends StatelessWidget {
  final DateTime date;
  final String profession;
  final List<ShiftModel> shifts;
  final ScheduleViewModel viewModel;
  final VoidCallback onTap;

  const ShiftCell({
    required this.date,
    required this.profession,
    required this.shifts,
    required this.viewModel,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: shifts.isEmpty ? _buildEmptyCell(context) : _buildShiftsList(context),
    );
  }

  /// Empty cell with "+" icon for adding new shift
  Widget _buildEmptyCell(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Icon(
          Icons.add_circle_outline,
          size: 16, // Changed from 24 to match filled cells
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// List of shift cards stacked vertically with add button at bottom
  Widget _buildShiftsList(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max, // Changed from min to max
      children: [
        // Existing shift cards - padding only on sides and top
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0), // No bottom padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: shifts.map((shift) {
              return ShiftCard(
                shift: shift,
                viewModel: viewModel,
              );
            }).toList(),
          ),
        ),

        // Spacer to push add button to bottom of cell
        const Spacer(),

        // Compact add button at bottom (minimal height)
        InkWell(
          onTap: onTap,
          child: Container(
            height: 24, // Very compact height
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add_circle_outline,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
