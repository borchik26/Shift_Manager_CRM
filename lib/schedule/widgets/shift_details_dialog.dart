import 'package:flutter/material.dart';
import 'package:my_app/schedule/models/shift_model.dart';

void showShiftDetailsDialog(BuildContext context, ShiftModel shift, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
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
          _buildDetailRow(Icons.timer, '${shift.durationInHours.toStringAsFixed(1)} ч'),
          if (shift.employeePreferences != null && shift.employeePreferences!.isNotEmpty) ...[
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
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
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
            onEdit();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
          child: const Text('Редактировать'),
        ),
        TextButton(
          onPressed: () {
            onDelete();
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
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
