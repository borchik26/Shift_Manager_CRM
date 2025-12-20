import 'package:flutter/material.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/schedule/viewmodels/schedule_view_model.dart';
import 'package:my_app/schedule/widgets/employee_filter_dropdown.dart';
import 'package:my_app/schedule/widgets/date_range_filter_dropdown.dart';
import 'package:my_app/schedule/widgets/status_filter_dropdown.dart';
import 'package:my_app/schedule/widgets/role_legend.dart';
import 'package:my_app/schedule/widgets/summary_bar.dart';
import 'package:my_app/schedule/constants/schedule_view_type.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:my_app/schedule/models/shift_model.dart';

class DesktopScheduleView extends StatefulWidget {
  final ScheduleViewModel viewModel;
  final void Function(ShiftModel) onShiftTap;
  final VoidCallback onCreateShift;

  const DesktopScheduleView({
    super.key,
    required this.viewModel,
    required this.onShiftTap,
    required this.onCreateShift,
  });

  @override
  State<DesktopScheduleView> createState() => _DesktopScheduleViewState();
}

class _DesktopScheduleViewState extends State<DesktopScheduleView> {
  String? _selectedBranch;
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchFilterBar(),
        RoleLegend(viewModel: widget.viewModel),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  final visibleCount = (availableHeight / 40).floor();
                  final isMonthView = widget.viewModel.currentViewType == ScheduleViewType.month;
                  return isMonthView
                      ? _buildMonthCalendar()
                      : _buildTimelineCalendar(visibleCount);
                },
              );
            },
          ),
        ),
        ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            return SummaryBar(statistics: widget.viewModel.statistics);
          },
        ),
      ],
    );
  }

  Widget _buildSearchFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
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
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: widget.viewModel.setSearchQuery,
            ),
          ),
          const SizedBox(width: 8),
          _buildSortButton(),
          const SizedBox(width: 12),
          _buildBranchDropdown(),
          const SizedBox(width: 12),
          _buildRoleDropdown(),
          const SizedBox(width: 12),
          if (widget.viewModel.isManager)
            ValueListenableBuilder<AsyncValue<List<Employee>>>(
              valueListenable: widget.viewModel.employeesState,
              builder: (context, employeesState, _) {
                if (employeesState.isLoading) return const SizedBox();
                if (employeesState is! AsyncData<List<Employee>>) return const SizedBox();
                return EmployeeFilterDropdown(
                  employees: employeesState.data,
                  selectedEmployeeId: widget.viewModel.employeeFilter,
                  onEmployeeSelected: widget.viewModel.setEmployeeFilter,
                );
              },
            ),
          if (widget.viewModel.isManager) const SizedBox(width: 12),
          ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              return DateRangeFilterDropdown(
                selectedFilter: widget.viewModel.dateRangeFilter,
                onFilterChanged: widget.viewModel.setDateRangeFilter,
              );
            },
          ),
          const SizedBox(width: 12),
          ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              return StatusFilterDropdown(
                selectedFilter: widget.viewModel.statusFilter,
                onFilterChanged: widget.viewModel.setStatusFilter,
              );
            },
          ),
          const SizedBox(width: 12),
          _buildClearFiltersButton(),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: widget.onCreateShift,
            icon: const Icon(Icons.add),
            label: const Text('Добавить смену'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return ValueListenableBuilder<AsyncValue<List<Employee>>>(
      valueListenable: widget.viewModel.employeesState,
      builder: (context, employeesState, _) {
        if (employeesState.isLoading) {
          return const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        return PopupMenuButton<String>(
          icon: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              return Badge(
                isLabelVisible: widget.viewModel.activeFiltersCount > 0,
                label: Text('${widget.viewModel.activeFiltersCount}'),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: const Icon(Icons.filter_alt_outlined, size: 18),
                ),
              );
            },
          ),
          tooltip: 'Сортировка сотрудников',
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
          ],
          onSelected: (value) {
            widget.viewModel.sortEmployees(value);
          },
        );
      },
    );
  }

  Widget _buildBranchDropdown() {
    return ValueListenableBuilder<AsyncValue<List<String>>>(
      valueListenable: widget.viewModel.branchesState,
      builder: (context, state, _) {
        final isDisabled = state.isLoading || state.hasError || (state.dataOrNull?.isEmpty ?? true);
        final items = state.dataOrNull ?? const <String>[];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: DropdownButton<String>(
            value: isDisabled ? null : _selectedBranch,
            isDense: true,
            onTap: widget.viewModel.refreshBranches,
            hint: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏢', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  state.isLoading ? 'Загрузка...' : state.hasError ? 'Ошибка' : 'Филиал',
                  style: TextStyle(
                    fontSize: 14,
                    color: state.hasError ? Colors.red : Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            underline: const SizedBox(),
            icon: const SizedBox(),
            items: items.map((branch) {
              return DropdownMenuItem(value: branch, child: Text(branch));
            }).toList(),
            onChanged: isDisabled
                ? null
                : (value) {
                    setState(() => _selectedBranch = value);
                    widget.viewModel.setLocationFilter(value);
                  },
          ),
        );
      },
    );
  }

  Widget _buildRoleDropdown() {
    return ValueListenableBuilder<AsyncValue<List<String>>>(
      valueListenable: widget.viewModel.rolesState,
      builder: (context, state, _) {
        final isDisabled = state.isLoading || state.hasError || (state.dataOrNull?.isEmpty ?? true);
        final items = state.dataOrNull ?? const <String>[];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: DropdownButton<String>(
            value: isDisabled ? null : _selectedRole,
            isDense: true,
            onTap: widget.viewModel.refreshRoles,
            hint: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👔', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  state.isLoading ? 'Загрузка...' : state.hasError ? 'Ошибка' : 'Должность',
                  style: TextStyle(
                    fontSize: 14,
                    color: state.hasError ? Colors.red : Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            underline: const SizedBox(),
            icon: const SizedBox(),
            items: items.map((role) {
              return DropdownMenuItem(value: role, child: Text(role));
            }).toList(),
            onChanged: isDisabled
                ? null
                : (value) {
                    setState(() => _selectedRole = value);
                    widget.viewModel.setRoleFilter(value);
                  },
          ),
        );
      },
    );
  }

  Widget _buildClearFiltersButton() {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.activeFiltersCount == 0) return const SizedBox();
        return TextButton.icon(
          onPressed: () {
            setState(() {
              _selectedBranch = null;
              _selectedRole = null;
            });
            widget.viewModel.clearFilters();
          },
          icon: const Icon(Icons.clear, size: 18),
          label: Text('Сбросить (${widget.viewModel.activeFiltersCount})'),
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
        );
      },
    );
  }

  Widget _buildMonthCalendar() {
    return SfCalendar(
      key: const ValueKey('month'),
      view: CalendarView.month,
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
      dataSource: widget.viewModel.getMonthDataSource(),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        showAgenda: false,
        appointmentDisplayCount: 4,
      ),
      appointmentBuilder: _buildAppointment,
      onTap: (details) {
        if (details.appointments != null && details.appointments!.isNotEmpty) {
          widget.onShiftTap(details.appointments!.first as ShiftModel);
        }
      },
      onDragEnd: (details) {
        if (details.appointment is! ShiftModel) return;
        final shift = details.appointment as ShiftModel;
        widget.viewModel.updateShiftTime(
          shift.id,
          details.droppingTime!,
          details.droppingTime!.add(shift.endTime.difference(shift.startTime)),
          newResourceId: details.targetResource?.id as String?,
        );
      },
      onAppointmentResizeEnd: (details) {
        if (details.appointment is! ShiftModel) return;
        final shift = details.appointment as ShiftModel;
        widget.viewModel.updateShiftTime(shift.id, details.startTime!, details.endTime!);
      },
    );
  }

  Widget _buildTimelineCalendar(int visibleCount) {
    return SfCalendar(
      key: ValueKey(widget.viewModel.currentViewType),
      view: widget.viewModel.currentViewType.calendarView,
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
      dataSource: widget.viewModel.dataSource,
      resourceViewSettings: ResourceViewSettings(
        visibleResourceCount: visibleCount > 0 ? visibleCount : 1,
        showAvatar: false,
        size: 200,
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
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
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
                      image: DecorationImage(image: resource.image!, fit: BoxFit.cover),
                    ),
                  )
                else
                  CircleAvatar(
                    backgroundColor: resource.color,
                    radius: 14,
                    child: Text(
                      resource.displayName.isNotEmpty ? resource.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resource.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
      timeSlotViewSettings: TimeSlotViewSettings(
        timelineAppointmentHeight: 40,
        timeInterval: widget.viewModel.currentViewType == ScheduleViewType.day
            ? const Duration(minutes: 30)
            : const Duration(hours: 2),
        timeFormat: 'HH:mm',
        dateFormat: 'd',
        dayFormat: 'EEE',
        startHour: 0,
        endHour: 24,
        timeTextStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      appointmentBuilder: _buildAppointment,
      onTap: (details) {
        if (details.appointments != null && details.appointments!.isNotEmpty) {
          widget.onShiftTap(details.appointments!.first as ShiftModel);
        }
      },
      onDragEnd: (details) {
        if (details.appointment is! ShiftModel) return;
        final shift = details.appointment as ShiftModel;
        widget.viewModel.updateShiftTime(
          shift.id,
          details.droppingTime!,
          details.droppingTime!.add(shift.endTime.difference(shift.startTime)),
          newResourceId: details.targetResource?.id as String?,
        );
      },
      onAppointmentResizeEnd: (details) {
        if (details.appointment is! ShiftModel) return;
        final shift = details.appointment as ShiftModel;
        widget.viewModel.updateShiftTime(shift.id, details.startTime!, details.endTime!);
      },
    );
  }

  Widget _buildAppointment(BuildContext context, CalendarAppointmentDetails details) {
    final shift = details.appointments.first as ShiftModel;
    final backgroundColor = shift.color.withOpacity(0.15);
    final borderColor = shift.color;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: borderColor, width: 4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showDetails = constraints.maxHeight > 40;
            return ClipRect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          shift.timeRange,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (shift.employeePreferences != null && shift.employeePreferences!.isNotEmpty) ...[
                        const SizedBox(width: 2),
                        Icon(Icons.comment, size: 9, color: Colors.blue.shade700),
                      ],
                    ],
                  ),
                  if (showDetails) ...[
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: shift.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              shift.roleTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.place,
                          size: 8,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                        const SizedBox(width: 1),
                        Flexible(
                          child: Text(
                            shift.location,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black54,
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
