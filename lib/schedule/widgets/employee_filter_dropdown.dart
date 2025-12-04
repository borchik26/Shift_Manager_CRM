import 'package:flutter/material.dart';
import 'package:my_app/data/models/employee.dart';

/// Dropdown фильтр для выбора сотрудника с поиском
class EmployeeFilterDropdown extends StatelessWidget {
  const EmployeeFilterDropdown({
    super.key,
    required this.employees,
    required this.selectedEmployeeId,
    required this.onEmployeeSelected,
  });

  final List<Employee> employees;
  final String? selectedEmployeeId;
  final void Function(String?) onEmployeeSelected;

  @override
  Widget build(BuildContext context) {
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
      child: DropdownButton<String?>(
        value: selectedEmployeeId,
        isDense: true,
        hint: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Сотрудник',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        items: [
          // Опция "Все сотрудники"
          DropdownMenuItem<String?>(
            value: null,
            child: Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Все сотрудники',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          // Список сотрудников
          ...employees.map((employee) {
            return DropdownMenuItem<String?>(
              value: employee.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Аватар или инициал
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: employee.avatarUrl != null
                        ? NetworkImage(employee.avatarUrl!)
                        : null,
                    child: employee.avatarUrl == null
                        ? Text(
                            employee.fullName.isNotEmpty
                                ? employee.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  // Имя
                  Flexible(
                    child: Text(
                      employee.fullName,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        onChanged: onEmployeeSelected,
        selectedItemBuilder: (context) {
          return [
            // Для "Все сотрудники"
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Все',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            // Для выбранного сотрудника
            ...employees.map((employee) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    employee.fullName.split(' ').first, // Только имя
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }),
          ];
        },
      ),
    );
  }
}
