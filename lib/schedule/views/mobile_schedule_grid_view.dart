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
  // Create separate scroll controllers for each row
  late final ScrollController _headerScrollController;
  late final List<ScrollController> _rowScrollControllers;
  final ScrollController _verticalScrollController = ScrollController();

  // Track which controller is currently scrolling to avoid infinite loops
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _headerScrollController = ScrollController();

    // Initialize row controllers based on number of professions
    final professionsCount = widget.viewModel.getUniqueProfessions().length;
    _rowScrollControllers = List.generate(
      professionsCount,
      (_) => ScrollController(),
    );
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    for (final controller in _rowScrollControllers) {
      controller.dispose();
    }
    _verticalScrollController.dispose();
    super.dispose();
  }

  /// Sync all scroll controllers to the given offset
  void _syncScrollControllers(double offset, ScrollController source) {
    if (_isScrolling) return;
    _isScrolling = true;

    // Sync header if source is not header
    if (source != _headerScrollController &&
        _headerScrollController.hasClients) {
      _headerScrollController.jumpTo(offset);
    }

    // Sync all rows if source is not this row
    for (final controller in _rowScrollControllers) {
      if (controller != source && controller.hasClients) {
        controller.jumpTo(offset);
      }
    }

    _isScrolling = false;
  }

  @override
  Widget build(BuildContext context) {
    final dates = widget.viewModel.getDateRange();
    final professions = widget.viewModel.getUniqueProfessions();

    // Recreate controllers if profession count changed
    if (_rowScrollControllers.length != professions.length) {
      for (final controller in _rowScrollControllers) {
        controller.dispose();
      }
      _rowScrollControllers.clear();
      _rowScrollControllers.addAll(
        List.generate(professions.length, (_) => ScrollController()),
      );
    }

    return Column(
      children: [
        // Days Header (sticky) with NotificationListener
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              _syncScrollControllers(
                notification.metrics.pixels,
                _headerScrollController,
              );
            }
            return false;
          },
          child: DaysHeaderRow(
            dates: dates,
            scrollController: _headerScrollController,
          ),
        ),

        // Professions Grid (vertical scroll)
        Expanded(
          child: professions.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  controller: _verticalScrollController,
                  child: Column(
                    children: List.generate(professions.length, (index) {
                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification) {
                            _syncScrollControllers(
                              notification.metrics.pixels,
                              _rowScrollControllers[index],
                            );
                          }
                          return false;
                        },
                        child: ProfessionRow(
                          profession: professions[index],
                          dates: dates,
                          viewModel: widget.viewModel,
                          scrollController: _rowScrollControllers[index],
                        ),
                      );
                    }),
                  ),
                ),
        ),
      ],
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
