import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/data/repositories/employee_repository.dart';
import 'package:my_app/data/repositories/shift_repository.dart';
import 'package:my_app/employees_syncfusion/viewmodels/employee_syncfusion_view_model.dart';
import 'package:my_app/employees_syncfusion/models/employee_syncfusion_model.dart';
import 'package:my_app/employees_syncfusion/widgets/create_employee_dialog.dart';

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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Сотрудники',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
            const SizedBox(height: 24),

            // Filters and Search
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildBranchDropdown(),
                        const SizedBox(width: 12),
                        _buildRoleDropdown(),
                        const SizedBox(width: 12),
                        _buildStatusDropdown(),
                        const SizedBox(width: 12),
                        // Кнопка сброса фильтров
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

                        const Spacer(),

                        // Search
                        Container(
                          width: 300,
                          height: 40,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Поиск',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              suffixIcon: const Icon(Icons.search, size: 18),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
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
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Счетчик отфильтрованных сотрудников
                    AnimatedBuilder(
                      animation: _viewModel,
                      builder: (context, _) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Показано: ${_viewModel.filteredCount} из ${_viewModel.totalCount} сотрудников',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Table
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _viewModel,
                        builder: (context, _) {
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
                            ),
                          );
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

  Widget _buildBranchDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
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
            const Text(
              '🏢',
              style: TextStyle(fontSize: 14),
            ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
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
            const Text(
              '👔',
              style: TextStyle(fontSize: 14),
            ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
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
            const Text(
              '📊',
              style: TextStyle(fontSize: 14),
            ),
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

  List<GridColumn> _buildColumns() {
    return [
      // ID (скрытая колонка)
      GridColumn(
        columnName: 'id',
        label: Container(),
        visible: false,
      ),

      // Name
      GridColumn(
        columnName: 'name',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            '«Сотрудник»',
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
            '«Должность»',
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
            '«Филиал»',
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
            '«Статус смены»',
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
            '«Отработано часов»',
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
      GridColumn(
        columnName: 'avatarUrl',
        label: Container(),
        visible: false,
      ),
    ];
  }
}
