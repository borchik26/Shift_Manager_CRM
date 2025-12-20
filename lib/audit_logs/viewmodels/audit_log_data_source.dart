import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:intl/intl.dart';
import 'package:my_app/data/models/audit_log.dart';
import 'package:my_app/audit_logs/models/audit_log_constants.dart';

/// DataSource for Syncfusion DataGrid displaying audit logs
class AuditLogDataSource extends DataGridSource {
  List<DataGridRow> _dataGridRows = [];
  final List<AuditLog> logs;

  AuditLogDataSource(this.logs) {
    _buildDataGridRows();
  }

  void _buildDataGridRows() {
    _dataGridRows = logs.map<DataGridRow>((log) {
      return DataGridRow(cells: [
        DataGridCell<DateTime>(columnName: 'created_at', value: log.createdAt),
        DataGridCell<String>(columnName: 'user_email', value: log.userEmail ?? 'unknown'),
        DataGridCell<String>(columnName: 'user_name', value: log.userName ?? '-'),
        DataGridCell<String>(columnName: 'action', value: log.actionType ?? 'unknown'),
        DataGridCell<String>(columnName: 'entity', value: log.entityType ?? 'unknown'),
        DataGridCell<String>(columnName: 'description', value: log.description ?? '-'),
        DataGridCell<String>(columnName: 'status', value: log.status ?? 'success'),
      ]);
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        if (cell.columnName == 'created_at') {
          return _buildDateCell(cell.value as DateTime);
        } else if (cell.columnName == 'status') {
          return _buildStatusCell(cell.value as String);
        } else if (cell.columnName == 'action') {
          return _buildActionCell(cell.value as String);
        } else if (cell.columnName == 'entity') {
          return _buildEntityCell(cell.value as String);
        }
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(8.0),
          child: Text(
            cell.value?.toString() ?? '-',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateCell(DateTime date) {
    final formatted = DateFormat('dd.MM.yyyy HH:mm').format(date);
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(8.0),
      child: Text(formatted),
    );
  }

  Widget _buildStatusCell(String status) {
    final color = status == 'success' ? Colors.green : Colors.red;
    final label = AuditLogStatus.getLabel(status);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActionCell(String action) {
    IconData icon;
    Color color;

    switch (action) {
      case AuditLogActionType.create:
        icon = Icons.add_circle_outline;
        color = Colors.green;
        break;
      case AuditLogActionType.update:
        icon = Icons.edit_outlined;
        color = Colors.blue;
        break;
      case AuditLogActionType.delete:
        icon = Icons.delete_outline;
        color = Colors.red;
        break;
      case AuditLogActionType.login:
        icon = Icons.login;
        color = Colors.teal;
        break;
      case AuditLogActionType.logout:
        icon = Icons.logout;
        color = Colors.orange;
        break;
      case AuditLogActionType.approve:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case AuditLogActionType.reject:
        icon = Icons.cancel_outlined;
        color = Colors.red;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    final label = AuditLogActionType.getLabel(action);

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildEntityCell(String entity) {
    final label = AuditLogEntityType.getLabel(entity);

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(8.0),
      child: Text(label),
    );
  }

  /// Update data source with new logs
  void updateData(List<AuditLog> newLogs) {
    logs.clear();
    logs.addAll(newLogs);
    _buildDataGridRows();
    notifyListeners();
  }
}
