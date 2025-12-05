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
  // Horizontal and vertical scroll controllers
  late final ScrollController _horizontalController;
  late final ScrollController _verticalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dates = widget.viewModel.getDateRange();
    final professions = widget.viewModel.getUniqueProfessions();

    if (professions.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      controller: _verticalController,
      scrollDirection: Axis.vertical,
      physics: const AlwaysScrollableScrollPhysics(), // Enable diagonal scroll
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(), // Enable diagonal scroll
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Days Header (sticky would require complex logic, so just scrolling)
            DaysHeaderRow(
              dates: dates,
              scrollController: null, // Not using individual controller
            ),

            // Professions Rows
            ...List.generate(professions.length, (index) {
              return ProfessionRow(
                profession: professions[index],
                dates: dates,
                viewModel: widget.viewModel,
                scrollController: null, // Not using individual controller
              );
            }),
          ],
        ),
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
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет смен для отображения',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите + чтобы создать смену',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
