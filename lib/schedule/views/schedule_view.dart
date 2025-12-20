import 'package:flutter/material.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/responsive_helper.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/data/repositories/branch_repository.dart';
import 'package:my_app/data/repositories/position_repository.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/viewmodels/schedule_view_model.dart';
import 'package:my_app/schedule/widgets/create_shift_dialog.dart';
import 'package:my_app/schedule/widgets/view_switcher.dart';
import 'package:my_app/schedule/widgets/desktop_schedule_view.dart';
import 'package:my_app/schedule/widgets/mobile_schedule_view.dart';
import 'package:my_app/schedule/widgets/shift_details_dialog.dart';

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

          return isMobile
              ? MobileScheduleView.build(
                  context: context,
                  viewModel: _viewModel,
                  onFiltersTap: () {
                    _viewModel.refreshBranches();
                    _viewModel.refreshRoles();
                    _showMobileFiltersSheet(context);
                  },
                )
              : DesktopScheduleView(
                  viewModel: _viewModel,
                  onShiftTap: _showShiftDetails,
                  onCreateShift: _handleCreateShift,
                );
        },
      ),
    );
  }

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
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Фильтры', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ValueListenableBuilder<AsyncValue<List<String>>>(
                  valueListenable: _viewModel.branchesState,
                  builder: (context, state, _) {
                    final items = state.dataOrNull ?? const <String>[];
                    final disabled = state.isLoading || state.hasError || items.isEmpty;
                    return DropdownButtonFormField<String>(
                      onTap: _viewModel.refreshBranches,
                      initialValue: disabled ? null : _selectedBranch,
                      decoration: InputDecoration(
                        labelText: state.isLoading
                            ? 'Загрузка...'
                            : state.hasError
                                ? 'Ошибка загрузки'
                                : 'Филиал',
                        border: const OutlineInputBorder(),
                      ),
                      items: items
                          .map((branch) => DropdownMenuItem(value: branch, child: Text(branch)))
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
                ValueListenableBuilder<AsyncValue<List<String>>>(
                  valueListenable: _viewModel.rolesState,
                  builder: (context, state, _) {
                    final items = state.dataOrNull ?? const <String>[];
                    final disabled = state.isLoading || state.hasError || items.isEmpty;
                    return DropdownButtonFormField<String>(
                      onTap: _viewModel.refreshRoles,
                      initialValue: disabled ? null : _selectedRole,
                      decoration: InputDecoration(
                        labelText: state.isLoading
                            ? 'Загрузка...'
                            : state.hasError
                                ? 'Ошибка загрузки'
                                : 'Должность',
                        border: const OutlineInputBorder(),
                      ),
                      items: items
                          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
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

  void _showShiftDetails(ShiftModel shift) {
    showShiftDetailsDialog(
      context,
      shift,
      onEdit: () => _showEditShiftDialog(shift),
      onDelete: () => _viewModel.deleteShift(shift.id),
    );
  }

  void _handleCreateShift() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => CreateShiftDialog(
        key: ValueKey('create_${DateTime.now().millisecondsSinceEpoch}'),
      ),
    );
    if (result == true && mounted) {
      _viewModel.refreshShifts();
    }
  }

  void _showEditShiftDialog(ShiftModel shift) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => CreateShiftDialog(
        key: ValueKey('edit_${shift.id}_${DateTime.now().millisecondsSinceEpoch}'),
        existingShift: shift,
      ),
    );
    if (result == true && mounted) {
      _viewModel.refreshShifts();
    }
  }
}
