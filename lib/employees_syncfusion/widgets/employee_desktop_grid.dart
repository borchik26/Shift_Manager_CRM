import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:my_app/employees_syncfusion/viewmodels/employee_syncfusion_view_model.dart';

class EmployeeDesktopGrid extends StatelessWidget {
  final EmployeeSyncfusionViewModel viewModel;

  const EmployeeDesktopGrid({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return SfDataGridTheme(
      data: SfDataGridThemeData(
        headerColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        gridLineColor: Colors.transparent,
        rowHoverColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        selectionColor: Colors.transparent,
      ),
      child: SfDataGrid(
        source: viewModel.dataSource,
        columns: _buildColumns(context),
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

  List<GridColumn> _buildColumns(BuildContext context) {
    return [
      GridColumn(columnName: 'id', label: Container(), visible: false),
      GridColumn(
        columnName: 'name',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            'Сотрудник',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
      GridColumn(
        columnName: 'role',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            'Должность',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
      GridColumn(
        columnName: 'branch',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            'Филиал',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
      GridColumn(
        columnName: 'status',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            'Статус смены',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        allowSorting: false,
      ),
      GridColumn(
        columnName: 'hours',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            'Отработано часов',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
      GridColumn(
        columnName: 'actions',
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        allowSorting: false,
      ),
      GridColumn(columnName: 'avatarUrl', label: Container(), visible: false),
    ];
  }
}
