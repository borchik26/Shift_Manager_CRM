import 'package:flutter/material.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/viewmodels/schedule_view_model.dart';
import 'package:my_app/schedule/widgets/shift_cell.dart';
import 'package:my_app/schedule/widgets/create_shift_dialog.dart';

/// Profession row for mobile schedule grid
/// Displays one profession with cells for each date
///
/// Layout: [Менеджер] | [Cell Day1] | [Cell Day2] | [Cell Day3] | ...
///           120px    |    100px    |    100px    |    100px    |
///
/// Features:
/// - First column: Profession name with role color indicator (sticky)
/// - Date cells: Dynamic height (expands if multiple shifts)
/// - Each cell contains 0-N shift cards stacked vertically
/// - Horizontal scroll synced with header
class ProfessionRow extends StatelessWidget {
  final String profession;
  final List<DateTime> dates;
  final ScheduleViewModel viewModel;
  final ScrollController scrollController;

  const ProfessionRow({
    required this.profession,
    required this.dates,
    required this.viewModel,
    required this.scrollController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profession name column (sticky) - VERTICAL TEXT
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Color indicator bar (horizontal, at top)
                Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: ShiftModel.getColorForRole(profession),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(height: 8),
                // Vertical text - each letter on new line
                Expanded(
                  child: Center(
                    child: Text(
                      profession.split('').join('\n'), // М\nе\nн\nе\nд\nж\nе\nр
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2, // Line height between letters
                      ),
                      maxLines: profession.length,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Date cells (horizontal scroll)
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: dates.map((date) {
                  final shifts = viewModel.getShiftsForProfessionAndDate(
                    profession,
                    date,
                  );

                  return ShiftCell(
                    date: date,
                    profession: profession,
                    shifts: shifts,
                    viewModel: viewModel,
                    onTap: () => _onCellTap(context, date, profession),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle tap on empty cell - open CreateShiftDialog with pre-filled data
  void _onCellTap(BuildContext context, DateTime date, String profession) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => CreateShiftDialog(
        initialDate: date,
        initialProfession: profession,
      ),
    );

    if (result == true) {
      // Dialog returned true - shift was created
      viewModel.refreshShifts();
    }
  }
}
