import 'package:flutter/material.dart';
import 'package:my_app/schedule/constants/schedule_view_type.dart';

/// Переключатель видов календаря (День/Неделя/Месяц)
/// Использует Material 3 SegmentedButton
class ViewSwitcher extends StatelessWidget {
  final ScheduleViewType currentView;
  final ValueChanged<ScheduleViewType> onViewChanged;

  const ViewSwitcher({
    super.key,
    required this.currentView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ScheduleViewType>(
      segments: [
        ButtonSegment(
          value: ScheduleViewType.day,
          label: const Text('День'),
          icon: Icon(ScheduleViewType.day.icon),
        ),
        ButtonSegment(
          value: ScheduleViewType.week,
          label: const Text('Неделя'),
          icon: Icon(ScheduleViewType.week.icon),
        ),
        ButtonSegment(
          value: ScheduleViewType.month,
          label: const Text('Месяц'),
          icon: Icon(ScheduleViewType.month.icon),
        ),
      ],
      selected: {currentView},
      onSelectionChanged: (Set<ScheduleViewType> selected) {
        onViewChanged(selected.first);
      },
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
