import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/viewmodels/schedule_view_model.dart';
import 'package:my_app/schedule/widgets/create_shift_dialog.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  late final ScheduleViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ScheduleViewModel(
      shiftRepository: locator<ShiftRepository>(),
      employeeRepository: locator<EmployeeRepository>(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('График смен'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filters
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (ctx) => const CreateShiftDialog(),
              );
              if (result == true && mounted) {
                _viewModel.refreshShifts();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Добавить смену'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ValueListenableBuilder<AsyncValue<void>>(
        valueListenable: _viewModel.state,
        builder: (context, state, child) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.hasError) {
            return Center(child: Text('Ошибка: ${state.errorOrNull}'));
          }

          return SfCalendar(
            view: CalendarView.timelineWeek,
            firstDayOfWeek: 1,
            showCurrentTimeIndicator: true,
            dataSource: _viewModel.dataSource!,
            resourceViewSettings: const ResourceViewSettings(
              visibleResourceCount: 5,
              showAvatar: true,
              size: 150,
              displayNameTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            timeSlotViewSettings: const TimeSlotViewSettings(
              timelineAppointmentHeight: 60,
              timeInterval: Duration(hours: 4),
              dateFormat: 'd',
              dayFormat: 'EEE',
              startHour: 0,
              endHour: 24,
            ),
            appointmentBuilder: (context, details) {
              final shift = details.appointments.first as ShiftModel;
              return Container(
                decoration: BoxDecoration(
                  color: shift.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: shift.color, width: 4),
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      shift.timeRange,
                      style: TextStyle(
                        color: shift.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      shift.roleTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      shift.location,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
            onTap: (details) {
              if (details.appointments != null &&
                  details.appointments!.isNotEmpty) {
                final shift = details.appointments!.first as ShiftModel;
                _showShiftDetails(shift);
              }
            },
          );
        },
      ),
    );
  }

  void _showShiftDetails(ShiftModel shift) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(shift.roleTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.access_time, shift.timeRange),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.location_on, shift.location),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.timer,
              '${shift.durationInHours.toStringAsFixed(1)} ч',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement delete
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}