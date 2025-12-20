import 'package:flutter/material.dart';
import 'package:my_app/employees_syncfusion/models/employee_syncfusion_model.dart';

/// Dialog widget for filtering employees on mobile
class EmployeeFiltersDialog extends StatefulWidget {
  final String? initialBranch;
  final String? initialRole;
  final EmployeeStatus? initialStatus;
  final List<String> availableBranches;
  final List<String> availableRoles;

  const EmployeeFiltersDialog({
    super.key,
    this.initialBranch,
    this.initialRole,
    this.initialStatus,
    required this.availableBranches,
    required this.availableRoles,
  });

  @override
  State<EmployeeFiltersDialog> createState() => _EmployeeFiltersDialogState();
}

class _EmployeeFiltersDialogState extends State<EmployeeFiltersDialog> {
  String? _selectedBranch;
  String? _selectedRole;
  EmployeeStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.initialBranch;
    _selectedRole = widget.initialRole;
    _selectedStatus = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Фильтры',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Branch dropdown
            const Text(
              'Филиал',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _selectedBranch,
              hint: 'Все филиалы',
              items: widget.availableBranches,
              onChanged: (value) => setState(() => _selectedBranch = value),
            ),
            const SizedBox(height: 16),

            // Role dropdown
            const Text(
              'Должность',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _selectedRole,
              hint: 'Все должности',
              items: widget.availableRoles,
              onChanged: (value) => setState(() => _selectedRole = value),
            ),
            const SizedBox(height: 16),

            // Status dropdown
            const Text(
              'Статус',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildStatusDropdown(),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, {
                      'branch': null,
                      'role': null,
                      'status': null,
                      'reset': true
                    }),
                    child: const Text('Сбросить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, {
                      'branch': _selectedBranch,
                      'role': _selectedRole,
                      'status': _selectedStatus,
                      'reset': false,
                    }),
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        hint: Text(hint),
        underline: const SizedBox(),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item.toString()),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButton<EmployeeStatus>(
        value: _selectedStatus,
        isExpanded: true,
        hint: const Text('Все статусы'),
        underline: const SizedBox(),
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
        onChanged: (value) => setState(() => _selectedStatus = value),
      ),
    );
  }
}
