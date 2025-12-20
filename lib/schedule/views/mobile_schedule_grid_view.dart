import 'package:flutter/material.dart';
import 'package:my_app/schedule/viewmodels/schedule_view_model.dart';
import 'package:my_app/schedule/widgets/days_header_row.dart';
import 'package:my_app/schedule/widgets/profession_row.dart';

class MobileScheduleGridView extends StatefulWidget {
  final ScheduleViewModel viewModel;

  const MobileScheduleGridView({
    required this.viewModel,
    super.key,
  });

  @override
  State<MobileScheduleGridView> createState() => _MobileScheduleGridViewState();
}

class _MobileScheduleGridViewState extends State<MobileScheduleGridView> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dates = widget.viewModel.getDateRange();
    final professions = widget.viewModel.getUniqueProfessionsWithOpenShifts();

    if (professions.isEmpty) {
      return _buildEmptyState();
    }

    return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: EdgeInsets.zero, // Strict boundaries - no scrolling beyond content
      minScale: 1.0,
      maxScale: 1.0, // Disable zoom, only pan
      constrained: false, // Allow child to be larger than viewport
      panEnabled: true,
      scaleEnabled: false, // Disable pinch-to-zoom
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Days Header
          DaysHeaderRow(
            dates: dates,
            scrollController: null,
          ),

          // Professions Rows (including "Свободные смены" if present)
          ...List.generate(professions.length, (index) {
            return ProfessionRow(
              profession: professions[index],
              dates: dates,
              viewModel: widget.viewModel,
              scrollController: null,
            );
          }),
        ],
      ),
    );
  }

  /// Empty state when no professions/shifts available
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Нет смен для отображения',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите + чтобы создать смену',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
