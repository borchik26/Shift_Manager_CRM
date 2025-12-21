import 'package:flutter/material.dart';
import 'package:my_app/core/ui/widgets/confirmation_dialog.dart';
import 'package:my_app/core/ui/widgets/filter_dropdown.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/responsive_helper.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/data/repositories/branch_repository.dart';
import 'package:my_app/data/repositories/position_repository.dart';
import 'package:my_app/employees_syncfusion/viewmodels/employee_syncfusion_view_model.dart';
import 'package:my_app/employees_syncfusion/models/employee_syncfusion_model.dart';
import 'package:my_app/employees_syncfusion/widgets/create_employee_dialog.dart';
import 'package:my_app/employees_syncfusion/widgets/employee_filters_dialog.dart';
import 'package:my_app/employees_syncfusion/widgets/user_approval_tab.dart';
import 'package:my_app/employees_syncfusion/widgets/employee_desktop_grid.dart';
import 'package:my_app/employees_syncfusion/widgets/employee_card.dart';

class EmployeeSyncfusionView extends StatefulWidget {
  const EmployeeSyncfusionView({super.key});

  @override
  State<EmployeeSyncfusionView> createState() => _EmployeeSyncfusionViewState();
}

class _EmployeeSyncfusionViewState extends State<EmployeeSyncfusionView>
    with SingleTickerProviderStateMixin {
  EmployeeSyncfusionViewModel? _viewModel;
  late final RouterService _routerService;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedBranch;
  String? _selectedRole;
  EmployeeStatus? _selectedStatus;
  TabController? _tabController;
  bool _isEmployee = false;

  @override
  void initState() {
    super.initState();

    _routerService = locator<RouterService>();
    final authService = locator<AuthService>();

    // If employee - redirect to own profile
    if (authService.isEmployee) {
      _isEmployee = true;
      final currentUserId = authService.currentUser?.id;
      if (currentUserId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _routerService.replace(
              Path(name: '/dashboard/employees/$currentUserId'),
            );
          }
        });
      }
      return; // Skip ViewModel initialization
    }

    // For manager - normal initialization
    _tabController = TabController(length: 2, vsync: this);
    _viewModel = EmployeeSyncfusionViewModel(
      employeeRepository: locator<EmployeeRepository>(),
      shiftRepository: locator<ShiftRepository>(),
      branchRepository: locator<BranchRepository>(),
      positionRepository: locator<PositionRepository>(),
      routerService: _routerService,
      notifyService: locator<NotifyService>(),
    );
    _viewModel!.setDeleteCallback(_onDeleteEmployee);
  }

  Future<void> _onDeleteEmployee(String employeeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Подтверждение удаления',
        message:
            'Вы уверены, что хотите удалить этого сотрудника? '
            'Это действие нельзя отменить.',
        confirmText: 'Удалить',
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _viewModel!.deleteEmployee(employeeId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Сотрудник успешно удален'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showCreateEmployeeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateEmployeeDialog(),
    );

    if (result == true && mounted) {
      // Dialog returned true - employee was created
      // Reload the employee list to show the new employee
      await _viewModel!.reloadEmployees();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    // If employee and redirecting, show loading
    if (_isEmployee) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            // Header - адаптивный
            Padding(
              padding: isMobile
                ? const EdgeInsets.fromLTRB(8, 4, 8, 0)
                : const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Управление сотрудниками',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isMobile)
                    // Mobile: IconButton
                    IconButton(
                      onPressed: _showCreateEmployeeDialog,
                      icon: const Icon(Icons.add_circle, size: 28),
                      color: Theme.of(context).colorScheme.primary,
                      tooltip: 'Добавить сотрудника',
                    )
                  else
                    // Desktop: Full button
                    ElevatedButton(
                      onPressed: _showCreateEmployeeDialog,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Добавить сотрудника'),
                    ),
                ],
              ),
            ),

            // TabBar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Сотрудники'),
                  Tab(text: 'Подтверждение пользователей'),
                ],
              ),
            ),

            // TabBarView with employee list and user approval
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Employee list
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 0 : 24.0),
                    child: Padding(
                      padding: EdgeInsets.only(top: isMobile ? 4.0 : 0),
                      child: _buildEmployeeContent(isMobile),
                    ),
                  ),
                  // Tab 2: User approval
                  const UserApprovalTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the employee list content
  Widget _buildEmployeeContent(bool isMobile) {
    // Ensure _viewModel is initialized
    if (_viewModel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: EdgeInsets.only(
        left: isMobile ? 12 : 16,
        right: isMobile ? 12 : 16,
        top: isMobile ? 12 : 16,
        bottom: 0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Filters Row - адаптивный
          AnimatedBuilder(
            animation: _viewModel!,
            builder: (context, _) {
              final isMobile = ResponsiveHelper.isMobile(context);

              return Row(
                children: [
                  if (isMobile)
                    // Mobile: кнопка фильтров
                    OutlinedButton.icon(
                      onPressed: _showFiltersDialog,
                      icon: const Icon(
                        Icons.filter_list,
                        size: 18,
                      ),
                      label: const Text(
                        'Фильтры',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    )
                  else
                  // Desktop: все фильтры
                  ...[
                    FilterDropdown<String>(
                      value: _selectedBranch,
                      emoji: '🏢',
                      label: 'Филиал',
                      items: _viewModel!.availableBranches,
                      itemLabel: (branch) => branch,
                      onChanged: (value) {
                        setState(() => _selectedBranch = value);
                        _viewModel!.filterByBranch(value);
                      },
                    ),
                    const SizedBox(width: 12),
                    FilterDropdown<String>(
                      value: _selectedRole,
                      emoji: '👔',
                      label: 'Должность',
                      items: _viewModel!.availableRoles,
                      itemLabel: (role) => role,
                      onChanged: (value) {
                        setState(() => _selectedRole = value);
                        _viewModel!.filterByRole(value);
                      },
                    ),
                    const SizedBox(width: 12),
                    FilterDropdown<EmployeeStatus>(
                      value: _selectedStatus,
                      emoji: '📊',
                      label: 'Статус',
                      items: EmployeeStatus.values,
                      itemLabel: (status) => status.displayName,
                      itemBuilder: (status) => Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(status.displayName),
                        ],
                      ),
                      onChanged: (value) {
                        setState(() => _selectedStatus = value);
                        _viewModel!.filterByStatus(value);
                      },
                    ),
                    const SizedBox(width: 12),
                    if (_selectedBranch != null ||
                        _selectedRole != null ||
                        _selectedStatus != null ||
                        _searchController.text.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedBranch = null;
                            _selectedRole = null;
                            _selectedStatus = null;
                            _searchController.clear();
                          });
                          _viewModel!.clearFilters();
                        },
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Сбросить'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                        ),
                      ),
                  ],
                  const SizedBox(width: 8),
                  // Search - адаптивный
                  Expanded(
                    child: Container(
                      width: isMobile ? null : 300,
                      height: 40,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.6),
                          ),
                          suffixIcon: const Icon(
                            Icons.search,
                            size: 18,
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: (value) {
                          _viewModel!.searchByName(value);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Builder(
            builder: (context) {
              final isMobile = ResponsiveHelper.isMobile(context);
              return SizedBox(height: isMobile ? 0 : 12);
            },
          ),

          // Счетчик отфильтрованных сотрудников
          AnimatedBuilder(
            animation: _viewModel!,
            builder: (context, _) {
              final isMobile = ResponsiveHelper.isMobile(context);

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 0 : 12,
                ),
                child: Text(
                  'Показано: ${_viewModel!.filteredCount} из ${_viewModel!.totalCount} сотрудников',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
          Builder(
            builder: (context) {
              final isMobile = ResponsiveHelper.isMobile(context);
              return SizedBox(height: isMobile ? 0 : 12);
            },
          ),

          // Table or Mobile List - ADAPTIVE
          Expanded(
            child: AnimatedBuilder(
              animation: _viewModel!,
              builder: (context, _) {
                final isMobile = ResponsiveHelper.isMobile(
                  context,
                );

                return isMobile ? _buildMobileList() : _buildDataGrid();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFiltersDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EmployeeFiltersDialog(
        initialBranch: _selectedBranch,
        initialRole: _selectedRole,
        initialStatus: _selectedStatus,
        availableBranches: _viewModel!.availableBranches,
        availableRoles: _viewModel!.availableRoles,
      ),
    );

    if (result != null && mounted) {
      if (result['reset'] == true) {
        setState(() {
          _selectedBranch = null;
          _selectedRole = null;
          _selectedStatus = null;
          _searchController.clear();
        });
        _viewModel!.clearFilters();
      } else {
        setState(() {
          _selectedBranch = result['branch'];
          _selectedRole = result['role'];
          _selectedStatus = result['status'];
        });
        _viewModel!.filterByBranch(_selectedBranch);
        _viewModel!.filterByRole(_selectedRole);
        _viewModel!.filterByStatus(_selectedStatus);
      }
    }
  }

  // Desktop DataGrid
  Widget _buildDataGrid() {
    return EmployeeDesktopGrid(viewModel: _viewModel!);
  }

  // Mobile List View with Cards
  Widget _buildMobileList() {
    return _viewModel!.employeesState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _viewModel!.reloadEmployees(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
      data: (_) {
        final employees = _viewModel!.filteredEmployees;

        if (employees.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Сотрудники не найдены',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 0),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            return EmployeeCard(
              employee: employee,
              onTap: () => _onEmployeeTap(employee.id),
              onDelete: () => _onDeleteEmployee(employee.id),
            );
          },
        );
      },
    );
  }

  // Navigate to employee profile
  void _onEmployeeTap(String employeeId) {
    _routerService.goTo(
      Path(name: '/dashboard/employees/$employeeId'),
    );
  }
}
