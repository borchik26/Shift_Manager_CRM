import 'package:my_app/data/models/employee.dart';

class EmployeeSorter {
  static List<Employee> sort(List<Employee> employees, String sortType) {
    final sorted = List<Employee>.from(employees);

    switch (sortType) {
      case 'name_asc':
        sorted.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'name_desc':
        sorted.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
      case 'role':
        sorted.sort((a, b) => a.position.compareTo(b.position));
        break;
      case 'branch':
        sorted.sort((a, b) => a.branch.compareTo(b.branch));
        break;
    }

    return sorted;
  }
}
