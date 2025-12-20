import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/models/employee.dart';

class ShiftFormEmployeeSection extends StatelessWidget {
  final ValueNotifier<AsyncValue<List<Employee>>> employeesState;
  final String? selectedEmployeeId;
  final void Function(String?) onEmployeeSelected;

  const ShiftFormEmployeeSection({
    super.key,
    required this.employeesState,
    required this.selectedEmployeeId,
    required this.onEmployeeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AsyncValue<List<Employee>>>(
      valueListenable: employeesState,
      builder: (context, state, child) {
        if (state.isLoading) {
          return const LinearProgressIndicator();
        }

        final employees = state.dataOrNull ?? [];

        return DropdownButtonFormField<String>(
          initialValue: (state.hasError || employees.isEmpty) ? null : selectedEmployeeId,
          decoration: const InputDecoration(
            labelText: 'Сотрудник',
            hintText: 'Выберите сотрудника',
            border: OutlineInputBorder(),
          ),
          items: employees.map((e) {
            return DropdownMenuItem(
              value: e.id,
              child: Text('${e.firstName} ${e.lastName}'),
            );
          }).toList(),
          onChanged: (state.hasError || employees.isEmpty) ? null : onEmployeeSelected,
          validator: null,
        );
      },
    );
  }
}
