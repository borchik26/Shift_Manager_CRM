import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/responsive_helper.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/employees_syncfusion/viewmodels/employee_syncfusion_view_model.dart';
import 'package:my_app/employees_syncfusion/models/employee_syncfusion_model.dart';
import 'package:my_app/employees_syncfusion/widgets/create_employee_dialog.dart';
import 'package:my_app/employees_syncfusion/widgets/employee_filters_dialog.dart';

class EmployeeSyncfusionView extends StatefulWidget {
  const EmployeeSyncfusionView({super.key});

  @override
  State<EmployeeSyncfusionView> createState() => _EmployeeSyncfusionViewState();
}

class _EmployeeSyncfusionViewState extends State<EmployeeSyncfusionView> {
  late final EmployeeSyncfusionViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedBranch;
  String? _selectedRole;
  EmployeeStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _viewModel = EmployeeSyncfusionViewModel(
      employeeRepository: locator<EmployeeRepository>(),
      shiftRepository: locator<ShiftRepository>(),
      context: context,
    );
    _viewModel.setDeleteCallback(_onDeleteEmployee);
  }

  Future<void> _onDeleteEmployee(String employeeId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: const Text(
          'Вы уверены, что хотите удалить этого сотрудника? '
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _viewModel.deleteEmployee(employeeId);
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
      await _viewModel.reloadEmployees();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - адаптивный
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Сотрудники',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isMobile)
                  // Mobile: IconButton
                  IconButton(
                    onPressed: _showCreateEmployeeDialog,
                    icon: const Icon(Icons.add_circle, size: 32),
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
            SizedBox(height: isMobile ? 0 : 24),

            // Filters and Search
            Expanded(
              child: Container(
                padding: EdgeInsets.only(
                  left: isMobile ? 12 : 16,
                  right: isMobile ? 12 : 16,
                  top: isMobile ? 12 : 16,
                  bottom: 0, // Убираем нижний padding
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Filters Row - адаптивный
                    AnimatedBuilder(
                      animation: _viewModel,
                      builder: (context, _) {
                        final isMobile = ResponsiveHelper.isMobile(context);

                        return Row(
                          children: [
                            if (isMobile)
                              // Mobile: кнопка фильтров
                              OutlinedButton.icon(
                                onPressed: _showFiltersDialog,
                                icon: const Icon(Icons.filter_list, size: 18),
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
                              _buildBranchDropdown(),
                              const SizedBox(width: 12),
                              _buildRoleDropdown(),
                              const SizedBox(width: 12),
                              _buildStatusDropdown(),
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
                                    _viewModel.clearFilters();
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
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Поиск',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.search,
                                      size: 18,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                  onChanged: (value) {
                                    _viewModel.searchByName(value);
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
                      animation: _viewModel,
                      builder: (context, _) {
                        final isMobile = ResponsiveHelper.isMobile(context);

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 0 : 12,
                          ),
                          child: Text(
                            'Показано: ${_viewModel.filteredCount} из ${_viewModel.totalCount} сотрудников',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              color: Colors.grey.shade600,
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
                        animation: _viewModel,
                        builder: (context, _) {
                          final isMobile = ResponsiveHelper.isMobile(context);

                          return isMobile
                              ? _buildMobileList()
                              : _buildDataGrid();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        availableBranches: _viewModel.availableBranches,
        availableRoles: _viewModel.availableRoles,
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
        _viewModel.clearFilters();
      } else {
        setState(() {
          _selectedBranch = result['branch'];
          _selectedRole = result['role'];
          _selectedStatus = result['status'];
        });
        _viewModel.filterByBranch(_selectedBranch);
        _viewModel.filterByRole(_selectedRole);
        _viewModel.filterByStatus(_selectedStatus);
      }
    }
  }

  Widget _buildBranchDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: _selectedBranch,
        isDense: true,
        hint: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏢', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              'Филиал',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        underline: const SizedBox(),
        icon: const SizedBox(),
        items: _viewModel.availableBranches.map((branch) {
          return DropdownMenuItem(value: branch, child: Text(branch));
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedBranch = value);
          _viewModel.filterByBranch(value);
        },
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: _selectedRole,
        isDense: true,
        hint: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👔', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              'Должность',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        underline: const SizedBox(),
        icon: const SizedBox(),
        items: _viewModel.availableRoles.map((role) {
          return DropdownMenuItem(value: role, child: Text(role));
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedRole = value);
          _viewModel.filterByRole(value);
        },
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<EmployeeStatus>(
        value: _selectedStatus,
        isDense: true,
        hint: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              'Статус',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        underline: const SizedBox(),
        icon: const SizedBox(),
        items: EmployeeStatus.values.map((status) {
          return DropdownMenuItem(
            value: status,
            child: Row(
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
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedStatus = value);
          _viewModel.filterByStatus(value);
        },
      ),
    );
  }

  // Desktop DataGrid
  Widget _buildDataGrid() {
    return SfDataGridTheme(
      data: SfDataGridThemeData(
        headerColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        gridLineColor: Colors.transparent,
        rowHoverColor: Colors.grey.shade50,
        selectionColor: Colors.transparent,
      ),
      child: SfDataGrid(
        source: _viewModel.dataSource,
        columns: _buildColumns(),
        columnWidthMode: ColumnWidthMode.fill,
        rowHeight: 72,
        headerRowHeight: 56,
        allowSorting: true,
        gridLinesVisibility: GridLinesVisibility.none,
        headerGridLinesVisibility: GridLinesVisibility.none,
        horizontalScrollPhysics: const AlwaysScrollableScrollPhysics(),
      ),
    );
  }

  List<GridColumn> _buildColumns() {
    return [
      // ID (скрытая колонка)
      GridColumn(columnName: 'id', label: Container(), visible: false),

      // Name
      GridColumn(
        columnName: 'name',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            'Сотрудник',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ),

      // Role
      GridColumn(
        columnName: 'role',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            'Должность',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ),

      // Branch
      GridColumn(
        columnName: 'branch',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            'Филиал',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ),

      // Status
      GridColumn(
        columnName: 'status',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            'Статус смены',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        allowSorting: false,
      ),

      // Hours
      GridColumn(
        columnName: 'hours',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            'Отработано часов',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ),

      // Actions
      GridColumn(
        columnName: 'actions',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: const Text(
            '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        allowSorting: false,
      ),

      // Avatar URL (скрытая колонка)
      GridColumn(columnName: 'avatarUrl', label: Container(), visible: false),
    ];
  }

  // Mobile List View with Cards
  Widget _buildMobileList() {
    final employees = _viewModel.filteredEmployees;

    if (employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Сотрудники не найдены',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
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

        return Card(
          margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _onEmployeeTap(employee.id),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Avatar + Name + Actions
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        foregroundImage: NetworkImage(employee.avatarUrl),
                        onForegroundImageError: (_, __) {},
                        child: Text(
                          employee.name.isNotEmpty ? employee.name[0] : '?',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              employee.role,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'history',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                const Text('История'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Удалить',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'history') {
                            _onEmployeeTap(employee.id);
                          } else if (value == 'delete') {
                            _onDeleteEmployee(employee.id);
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Divider(height: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 8),

                  // Details Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.business,
                          label: employee.branch,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.access_time,
                          label: '${employee.workedHours} ч',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: employee.status.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          employee.status.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper widget for info chips
  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to employee profile
  void _onEmployeeTap(String employeeId) {
    // Using RouterService from data_source
    locator<RouterService>().goTo(
      Path(name: '/dashboard/employees/$employeeId'),
    );
  }
}
