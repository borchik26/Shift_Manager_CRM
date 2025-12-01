import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/employees_syncfusion/models/employee_syncfusion_model.dart';

class EmployeeDataSource extends DataGridSource {
  EmployeeDataSource({required List<EmployeeSyncfusionModel> employees}) {
    _employees = employees;
    _buildDataGridRows();
  }

  List<EmployeeSyncfusionModel> _employees = [];
  List<DataGridRow> _dataGridRows = [];

  @override
  List<DataGridRow> get rows => _dataGridRows;

  void _buildDataGridRows() {
    _dataGridRows = _employees.map<DataGridRow>((employee) {
      return DataGridRow(cells: [
        DataGridCell<String>(columnName: 'id', value: employee.id),
        DataGridCell<String>(columnName: 'name', value: employee.name),
        DataGridCell<String>(columnName: 'role', value: employee.role),
        DataGridCell<String>(columnName: 'branch', value: employee.branch),
        DataGridCell<String>(columnName: 'status', value: employee.status.name),
        DataGridCell<int>(columnName: 'hours', value: employee.workedHours),
        DataGridCell<String>(columnName: 'actions', value: 'История'),
        DataGridCell<String>(columnName: 'avatarUrl', value: employee.avatarUrl),
      ]);
    }).toList();
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final String name = row.getCells()[1].value;
    final String role = row.getCells()[2].value;
    final String branch = row.getCells()[3].value;
    final String statusName = row.getCells()[4].value;
    final int hours = row.getCells()[5].value;
    final String avatarUrl = row.getCells()[7].value;
    final String employeeId = row.getCells()[0].value;

    final status = EmployeeStatus.values.firstWhere((e) => e.name == statusName);

    return DataGridRowAdapter(
      cells: [
        // ID (скрытая колонка)
        Container(),
        
        // Name с аватаром
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                foregroundImage: NetworkImage(avatarUrl),
                onForegroundImageError: (_, __) {},
                child: Text(name.isNotEmpty ? name[0] : '?'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        // Role
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            role,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        
        // Branch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            branch,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        
        // Status с цветным бейджем
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status.displayName,
              style: const TextStyle(
                color: Colors.white, // Белый текст на цветном фоне
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        // Hours
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(
            '$hours ч',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        // Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: ElevatedButton(
            onPressed: () {
              _onHistoryPressed(employeeId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0088CC), // Цвет кнопки как на скриншоте
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'История',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        
        // Avatar URL (скрытая колонка)
        Container(),
      ],
    );
  }

  void _onHistoryPressed(String employeeId) {
    locator<RouterService>().goTo(Path(name: '/dashboard/employees/$employeeId'));
  }

  // Сортировка
  @override
  Future<void> handleSort(String columnName, DataGridSortDirection direction) async {
    if (columnName == 'name') {
      _employees.sort((a, b) {
        final result = a.name.compareTo(b.name);
        return direction == DataGridSortDirection.ascending ? result : -result;
      });
    } else if (columnName == 'role') {
      _employees.sort((a, b) {
        final result = a.role.compareTo(b.role);
        return direction == DataGridSortDirection.ascending ? result : -result;
      });
    } else if (columnName == 'branch') {
      _employees.sort((a, b) {
        final result = a.branch.compareTo(b.branch);
        return direction == DataGridSortDirection.ascending ? result : -result;
      });
    } else if (columnName == 'hours') {
      _employees.sort((a, b) {
        final result = a.workedHours.compareTo(b.workedHours);
        return direction == DataGridSortDirection.ascending ? result : -result;
      });
    }

    _buildDataGridRows();
    notifyListeners();
  }

  // Обновление данных
  void updateDataSource(List<EmployeeSyncfusionModel> employees) {
    _employees = employees;
    _buildDataGridRows();
    notifyListeners();
  }
}