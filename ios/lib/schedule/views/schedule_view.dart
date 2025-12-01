import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/data/models/employee.dart';
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Фильтры',
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                child: Text('Фильтр по локации:', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...['ТЦ Мега', 'Центр', 'Аэропорт'].map(
                (location) => PopupMenuItem(
                  value: 'loc_$location',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        color: _viewModel.locationFilter == location
                            ? Colors.blue
                            : Colors.transparent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(location),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text('Сбросить фильтры', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'clear') {
                _viewModel.clearFilters();
              } else if (value.startsWith('loc_')) {
                final location = value.substring(4);
                if (_viewModel.locationFilter == location) {
                  _viewModel.setLocationFilter(null);
                } else {
                  _viewModel.setLocationFilter(location);
                }
              }
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

          return Column(
            children: [
              // Search Filter Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 250,
                      height: 36,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Поиск сотрудника...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (value) {
                          _viewModel.setSearchQuery(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<AsyncValue<List<Employee>>>(
                      valueListenable: _viewModel.employeesState,
                      builder: (context, employeesState, _) {
                        if (employeesState.isLoading) {
                          return const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        
                        return PopupMenuButton<String>(
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: const Icon(Icons.filter_alt_outlined, size: 18),
                          ),
                          tooltip: 'Фильтр сотрудников',
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              enabled: false,
                              child: Text('Сортировка сотрудников:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const PopupMenuItem(
                              value: 'name_asc',
                              child: Row(
                                children: [
                                  Icon(Icons.sort_by_alpha, size: 18),
                                  SizedBox(width: 8),
                                  Text('По имени (А-Я)'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'name_desc',
                              child: Row(
                                children: [
                                  Icon(Icons.sort_by_alpha, size: 18),
                                  SizedBox(width: 8),
                                  Text('По имени (Я-А)'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'role',
                              child: Row(
                                children: [
                                  Icon(Icons.work, size: 18),
                                  SizedBox(width: 8),
                                  Text('По позиции'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'branch',
                              child: Row(
                                children: [
                                  Icon(Icons.location_city, size: 18),
                                  SizedBox(width: 8),
                                  Text('По филиалу'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'show_all',
                              child: Row(
                                children: [
                                  Icon(Icons.people, size: 18),
                                  SizedBox(width: 8),
                                  Text('Показать всех'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'name_asc':
                                _viewModel.sortEmployees('name_asc');
                                break;
                              case 'name_desc':
                                _viewModel.sortEmployees('name_desc');
                                break;
                              case 'role':
                                _viewModel.sortEmployees('role');
                                break;
                              case 'branch':
                                _viewModel.sortEmployees('branch');
                                break;
                              case 'show_all':
                                _viewModel.clearEmployeeFilter();
                                break;
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate visible count to force 40px row height
                    // Subtract header height approximation (roughly 60-80px for time ruler)
                    final double availableHeight = constraints.maxHeight;
                    final int visibleCount = (availableHeight / 40).floor();

                    return SfCalendar(
                      view: CalendarView.timelineWeek,
                      firstDayOfWeek: 1,
                      showCurrentTimeIndicator: true,
                      allowDragAndDrop: true,
                      allowAppointmentResize: true,
                      dragAndDropSettings: DragAndDropSettings(
                        showTimeIndicator: true,
                        indicatorTimeFormat: 'HH:mm',
                        timeIndicatorStyle: TextStyle(
                          backgroundColor: Colors.blueAccent.withOpacity(0.5),
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      dataSource: _viewModel.dataSource!,
                      resourceViewSettings: ResourceViewSettings(
                        visibleResourceCount: visibleCount > 0 ? visibleCount : 1,
                        showAvatar: false, // Disable default avatar to use custom builder
                        size: 200, // Increased size for better visibility
                        displayNameTextStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      resourceViewHeaderBuilder: (context, details) {
                        final resource = details.resource;
                        return RepaintBoundary(
                          child: Container(
                            height: 40, // Explicitly match timelineAppointmentHeight
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade300, width: 1),
                                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (resource.image != null)
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: resource.image!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                else
                                  CircleAvatar(
                                    backgroundColor: resource.color,
                                    radius: 14,
                                    child: Text(
                                      resource.displayName.isNotEmpty
                                          ? resource.displayName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    resource.displayName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      timeSlotViewSettings: const TimeSlotViewSettings(
                        timelineAppointmentHeight: 40, // Reduced height to 40px
                        timeInterval: Duration(hours: 2), // More granular
                        timeFormat: 'HH:mm',
                        dateFormat: 'd',
                        dayFormat: 'EEE',
                        startHour: 0,
                        endHour: 24,
                        timeTextStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      appointmentBuilder: (context, details) {
                        final shift = details.appointments.first as ShiftModel;
                        // Pastel background color
                        final backgroundColor = shift.color.withOpacity(0.15);
                        final borderColor = shift.color;

                        return RepaintBoundary(
                          child: GestureDetector(
                            onSecondaryTapUp: (details) {
                              // Right click context menu
                              _showContextMenu(context, details.globalPosition, shift);
                            },
                            onLongPressStart: (details) {
                              // Long press context menu (mobile)
                              _showContextMenu(context, details.globalPosition, shift);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border(
                                  left: BorderSide(color: borderColor, width: 4),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Adaptive content based on height
                                  final showDetails = constraints.maxHeight > 40;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            shift.timeRange,
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (showDetails) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${shift.roleTitle} • ${shift.location}',
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ),
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
                      onDragEnd: (details) {
                        if (details.appointment != null) {
                          final shift = details.appointment as ShiftModel;
                          final newStartTime = details.droppingTime;

                          if (newStartTime != null) {
                            final newEndTime = newStartTime.add(
                              shift.endTime.difference(shift.startTime),
                            );
                            final newResourceId = details.targetResource?.id as String?;

                            _viewModel.updateShiftTime(
                              shift.id,
                              newStartTime,
                              newEndTime,
                              newResourceId: newResourceId,
                            );
                          }
                        }
                      },
                      onAppointmentResizeEnd: (details) {
                        if (details.appointment != null &&
                            details.startTime != null &&
                            details.endTime != null) {
                          final shift = details.appointment as ShiftModel;
                          _viewModel.updateShiftTime(
                            shift.id,
                            details.startTime!,
                            details.endTime!,
                            newResourceId: shift.employeeId, // Resource doesn't change on resize
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
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
              _viewModel.deleteShift(shift.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset globalPosition, ShiftModel shift) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Изменить'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 8),
              Text('Копировать'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Удалить', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        _showShiftDetails(shift);
      } else if (value == 'copy') {
        _viewModel.copyShift(shift);
      } else if (value == 'delete') {
        _viewModel.deleteShift(shift.id);
      }
    });
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