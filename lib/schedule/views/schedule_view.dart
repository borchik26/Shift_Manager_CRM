import 'package:flutter/material.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/responsive_helper.dart';
import 'package:my_app/core/utils/color_generator.dart';
import 'package:my_app/data/models/employee.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/data/repositories/branch_repository.dart';
import 'package:my_app/data/repositories/position_repository.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/viewmodels/schedule_view_model.dart';
import 'package:my_app/schedule/views/mobile_schedule_grid_view.dart';
import 'package:my_app/schedule/widgets/create_shift_dialog.dart';
import 'package:my_app/schedule/widgets/view_switcher.dart';
import 'package:my_app/schedule/widgets/summary_bar.dart';
import 'package:my_app/schedule/widgets/employee_filter_dropdown.dart';
import 'package:my_app/schedule/widgets/date_range_filter_dropdown.dart';
import 'package:my_app/schedule/widgets/status_filter_dropdown.dart';
import 'package:my_app/schedule/constants/schedule_view_type.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  late final ScheduleViewModel _viewModel;
  String? _selectedBranch;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _viewModel = ScheduleViewModel(
      authService: locator<AuthService>(),
      shiftRepository: locator<ShiftRepository>(),
      employeeRepository: locator<EmployeeRepository>(),
      branchRepository: locator<BranchRepository>(),
      positionRepository: locator<PositionRepository>(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      // Remove AppBar on mobile for more space
      appBar: isMobile
          ? null
          : AppBar(
              title: const Text('График смен'),
              actions: [
                ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) {
                    return ViewSwitcher(
                      currentView: _viewModel.currentViewType,
                      onViewChanged: _viewModel.changeViewType,
                    );
                  },
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

          // ADAPTIVE: Mobile vs Desktop
          return isMobile ? _buildMobileView() : _buildDesktopView();
        },
      ),
    );
  }

  /// Mobile view with Deputy-style grid
  Widget _buildMobileView() {
    return SafeArea(
      top: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Column(
          children: [
            // Compact header with title, filters and search in one row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              // Title
              const Text(
                'График смен',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),

              // Filter button
              OutlinedButton.icon(
                onPressed: () {
                  _viewModel.refreshBranches();
                  _viewModel.refreshRoles();
                  _showMobileFiltersSheet(context);
                },
                icon: ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) {
                    return Badge(
                      isLabelVisible: _viewModel.activeFiltersCount > 0,
                      label: Text('${_viewModel.activeFiltersCount}'),
                      child: const Icon(Icons.filter_list, size: 16),
                    );
                  },
                ),
                label: const Text(
                  'Фильтры',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Compact search field
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: _viewModel.setSearchQuery,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Mobile Grid
        Expanded(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return MobileScheduleGridView(viewModel: _viewModel);
            },
          ),
        ),
          ],
        ),
      ),
    );
  }

  /// Desktop view with existing Syncfusion Calendar
  Widget _buildDesktopView() {
    return Column(
      children: [
        // Search Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
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
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                    ),
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
                    icon: ListenableBuilder(
                      listenable: _viewModel,
                      builder: (context, _) {
                        return Badge(
                          isLabelVisible: _viewModel.activeFiltersCount > 0,
                          label: Text('${_viewModel.activeFiltersCount}'),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            child: const Icon(
                              Icons.filter_alt_outlined,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                    tooltip: 'Сортировка сотрудников',
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        enabled: false,
                        child: Text(
                          'Сортировка сотрудников:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                      }
                    },
                  );
                },
              ),
              const SizedBox(width: 12),
              // Фильтр по филиалу
              _buildBranchDropdown(),
              const SizedBox(width: 12),
              // Фильтр по должности
              _buildRoleDropdown(),
              const SizedBox(width: 12),
              // Фильтр по сотруднику (только для менеджера)
              if (locator<AuthService>().isManager)
                ValueListenableBuilder<AsyncValue<List<Employee>>>(
                  valueListenable: _viewModel.employeesState,
                  builder: (context, employeesState, _) {
                    if (employeesState.isLoading) return const SizedBox();
                    if (employeesState is! AsyncData<List<Employee>>) {
                      return const SizedBox();
                    }

                    return EmployeeFilterDropdown(
                      employees: employeesState.data,
                      selectedEmployeeId: _viewModel.employeeFilter,
                      onEmployeeSelected: _viewModel.setEmployeeFilter,
                    );
                  },
                ),
              if (locator<AuthService>().isManager) const SizedBox(width: 12),
              // Фильтр по периоду
              ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return DateRangeFilterDropdown(
                    selectedFilter: _viewModel.dateRangeFilter,
                    onFilterChanged: _viewModel.setDateRangeFilter,
                  );
                },
              ),
              const SizedBox(width: 12),
              // Фильтр по статусу
              ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return StatusFilterDropdown(
                    selectedFilter: _viewModel.statusFilter,
                    onFilterChanged: _viewModel.setStatusFilter,
                  );
                },
              ),
              const SizedBox(width: 12),
              // Кнопка сброса фильтров
              ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  if (_viewModel.activeFiltersCount == 0) {
                    return const SizedBox();
                  }
                  return TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedBranch = null;
                        _selectedRole = null;
                      });
                      _viewModel.clearFilters();
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    label: Text(
                      'Сбросить (${_viewModel.activeFiltersCount})',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  );
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => CreateShiftDialog(
                      key: ValueKey(
                        'create_${DateTime.now().millisecondsSinceEpoch}',
                      ),
                    ),
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
            ],
          ),
        ),
        // Role Legend
        _buildRoleLegend(),
        Expanded(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate visible count to force 40px row height
                  // Subtract header height approximation (roughly 60-80px for time ruler)
                  final double availableHeight = constraints.maxHeight;
                  final int visibleCount = (availableHeight / 40).floor();

                  // Force rebuild when view type changes
                  final isMonthView =
                      _viewModel.currentViewType == ScheduleViewType.month;

                  // Use different calendar configuration for Month vs Day/Week
                  return isMonthView
                      ? _buildMonthCalendar()
                      : _buildTimelineCalendar(visibleCount);
                },
              );
            },
          ),
        ),
        // Summary bar at the bottom
        ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return SummaryBar(statistics: _viewModel.statistics);
          },
        ),
      ],
    );
  }

  /// Show mobile filters bottom sheet
  void _showMobileFiltersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          // TODO: Create FilterChipsBottomSheet widget
          // For now, show basic filter UI
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Фильтры',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                // Branch filter (mobile)
                ValueListenableBuilder<AsyncValue<List<String>>>(
                  valueListenable: _viewModel.branchesState,
                  builder: (context, state, _) {
                    final items = state.dataOrNull ?? const <String>[];
                    final disabled = state.isLoading || state.hasError || items.isEmpty;
                    return DropdownButtonFormField<String>(
                      onTap: _viewModel.refreshBranches,
                      value: disabled ? null : _selectedBranch,
                      decoration: InputDecoration(
                        labelText: state.isLoading
                            ? 'Загрузка...'
                            : state.hasError
                                ? 'Ошибка загрузки'
                                : 'Филиал',
                        border: const OutlineInputBorder(),
                      ),
                      items: items
                          .map((branch) => DropdownMenuItem(
                                value: branch,
                                child: Text(branch),
                              ))
                          .toList(),
                      onChanged: disabled
                          ? null
                          : (value) {
                              setState(() => _selectedBranch = value);
                              _viewModel.setLocationFilter(value);
                            },
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Role filter (mobile)
                ValueListenableBuilder<AsyncValue<List<String>>>(
                  valueListenable: _viewModel.rolesState,
                  builder: (context, state, _) {
                    final items = state.dataOrNull ?? const <String>[];
                    final disabled = state.isLoading || state.hasError || items.isEmpty;
                    return DropdownButtonFormField<String>(
                      onTap: _viewModel.refreshRoles,
                      value: disabled ? null : _selectedRole,
                      decoration: InputDecoration(
                        labelText: state.isLoading
                            ? 'Загрузка...'
                            : state.hasError
                                ? 'Ошибка загрузки'
                                : 'Должность',
                        border: const OutlineInputBorder(),
                      ),
                      items: items
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ))
                          .toList(),
                      onChanged: disabled
                          ? null
                          : (value) {
                              setState(() => _selectedRole = value);
                              _viewModel.setRoleFilter(value);
                            },
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Clear filters button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedBranch = null;
                      _selectedRole = null;
                    });
                    _viewModel.clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Сбросить фильтры'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build Month view calendar without resources
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
      dataSource: _viewModel.getMonthDataSource(),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        showAgenda: false,
        appointmentDisplayCount: 4,
      ),
      appointmentBuilder: _buildAppointment,
      onTap: _onCalendarTap,
      onDragEnd: (details) {
        if (details.appointment is! ShiftModel) return;
        final shift = details.appointment as ShiftModel;
        _viewModel.updateShiftTime(
          shift.id,
          details.droppingTime!,
          details.droppingTime!.add(shift.endTime.difference(shift.startTime)),
          newResourceId: details.targetResource?.id as String?,
        );
      },
      onAppointmentResizeEnd: (details) {
        if (details.appointment is! ShiftModel) return;
        final shift = details.appointment as ShiftModel;
        _viewModel.updateShiftTime(
          shift.id,
          details.startTime!,
          details.endTime!,
        );
      },
    );
  }

  /// Build Day/Week timeline calendar with resources
  Widget _buildTimelineCalendar(int visibleCount) {
    return SfCalendar(
      key: ValueKey(_viewModel.currentViewType),
      view: _viewModel.currentViewType.calendarView,
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
      dataSource: _viewModel.dataSource,
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
            height: 40, // Explicitly match timelineAppointmentHeight
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
        // 30 minutes for Day, 2 hours for Week
        timeInterval: _viewModel.currentViewType == ScheduleViewType.day
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
      onTap: _onCalendarTap,
      onDragEnd: (details) {
        if (details.appointment is! ShiftModel) return;
        final shift = details.appointment as ShiftModel;
        _viewModel.updateShiftTime(
          shift.id,
          details.droppingTime!,
          details.droppingTime!.add(shift.endTime.difference(shift.startTime)),
          newResourceId: details.targetResource?.id as String?,
        );
      },
      onAppointmentResizeEnd: (details) {
        if (details.appointment is! ShiftModel) return;
        final shift = details.appointment as ShiftModel;
        _viewModel.updateShiftTime(
          shift.id,
          details.startTime!,
          details.endTime!,
        );
      },
    );
  }

  /// Build appointment widget - used by both Month and Timeline views
  Widget _buildAppointment(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
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
            border: Border(left: BorderSide(color: borderColor, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Adaptive content based on height
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
                        if (shift.employeePreferences != null &&
                            shift.employeePreferences!.isNotEmpty) ...[
                          const SizedBox(width: 2),
                          Icon(
                            Icons.comment,
                            size: 9,
                            color: Colors.blue.shade700,
                          ),
                        ],
                      ],
                    ),
                    if (showDetails) ...[
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
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
      ),
    );
  }

  /// Handle calendar tap events
  void _onCalendarTap(CalendarTapDetails details) {
    if (details.appointments != null && details.appointments!.isNotEmpty) {
      final shift = details.appointments!.first as ShiftModel;
      _showShiftDetails(shift);
    }
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
            if (shift.employeePreferences != null &&
                shift.employeePreferences!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.comment, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Пожелания сотрудника:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shift.employeePreferences!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditShiftDialog(shift);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Редактировать'),
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

  void _showEditShiftDialog(ShiftModel shift) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => CreateShiftDialog(
        key: ValueKey(
          'edit_${shift.id}_${DateTime.now().millisecondsSinceEpoch}',
        ),
        existingShift: shift,
      ),
    );
    if (result == true && mounted) {
      _viewModel.refreshShifts();
    }
  }

  void _showContextMenu(
    BuildContext context,
    Offset globalPosition,
    ShiftModel shift,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

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
        _showEditShiftDialog(shift);
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

  Widget _buildRoleLegend() {
    return ValueListenableBuilder<AsyncValue<List<String>>>(
      valueListenable: _viewModel.rolesState,
      builder: (context, state, _) {
        // Скрыть легенду при загрузке или ошибке
        if (state.isLoading || state.hasError) {
          return const SizedBox.shrink();
        }

        final roles = state.dataOrNull ?? [];

        // Скрыть легенду если нет должностей
        if (roles.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              Text(
                'ДОЛЖНОСТИ:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 16),
              ...roles.map((role) {
                final color = ColorGenerator.generateColor(role);
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBranchDropdown() {
    return ValueListenableBuilder<AsyncValue<List<String>>>(
      valueListenable: _viewModel.branchesState,
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
            onTap: _viewModel.refreshBranches,
            hint: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏢', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  state.isLoading
                      ? 'Загрузка...'
                      : state.hasError
                          ? 'Ошибка'
                          : 'Филиал',
                  style: TextStyle(
                    fontSize: 14,
                    color: state.hasError
                        ? Colors.red
                        : Colors.blue.shade700,
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
                    _viewModel.setLocationFilter(value);
                  },
          ),
        );
      },
    );
  }

  Widget _buildRoleDropdown() {
    return ValueListenableBuilder<AsyncValue<List<String>>>(
      valueListenable: _viewModel.rolesState,
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
            onTap: _viewModel.refreshRoles,
            hint: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👔', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  state.isLoading
                      ? 'Загрузка...'
                      : state.hasError
                          ? 'Ошибка'
                          : 'Должность',
                  style: TextStyle(
                    fontSize: 14,
                    color: state.hasError
                        ? Colors.red
                        : Colors.blue.shade700,
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
                    _viewModel.setRoleFilter(value);
                  },
          ),
        );
      },
    );
  }
}
