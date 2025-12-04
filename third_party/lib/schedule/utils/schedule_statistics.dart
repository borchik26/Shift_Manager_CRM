import 'package:my_app/schedule/models/shift_model.dart';
import 'package:intl/intl.dart';

/// Утилита для расчета статистики по сменам
class ScheduleStatistics {
  /// Общее количество отработанных часов
  final double totalHours;

  /// Количество смен
  final int shiftsCount;

  /// Количество уникальных сотрудников
  final int employeesCount;

  /// Общие затраты на оплату труда (Labor Cost)
  final double laborCost;

  const ScheduleStatistics({
    required this.totalHours,
    required this.shiftsCount,
    required this.employeesCount,
    required this.laborCost,
  });

  /// Создает статистику из списка смен
  factory ScheduleStatistics.calculate(List<ShiftModel> shifts) {
    if (shifts.isEmpty) {
      return const ScheduleStatistics(
        totalHours: 0,
        shiftsCount: 0,
        employeesCount: 0,
        laborCost: 0,
      );
    }

    // Суммируем часы
    final totalHours = shifts.fold<double>(
      0,
      (sum, shift) => sum + shift.durationInHours,
    );

    // Считаем уникальных сотрудников
    final uniqueEmployees = shifts.map((shift) => shift.employeeId).toSet().length;

    // Суммируем затраты (используем getter cost из ShiftModel)
    final laborCost = shifts.fold<double>(
      0,
      (sum, shift) => sum + shift.cost,
    );

    return ScheduleStatistics(
      totalHours: totalHours,
      shiftsCount: shifts.length,
      employeesCount: uniqueEmployees,
      laborCost: laborCost,
    );
  }

  /// Форматированное отображение часов (56.0 ч)
  String get hoursFormatted {
    final formatter = NumberFormat('#,##0.0', 'ru_RU');
    return '${formatter.format(totalHours)} ч';
  }

  /// Форматированное отображение затрат (45 000 ₽)
  String get costFormatted {
    final formatter = NumberFormat('#,##0', 'ru_RU');
    return '${formatter.format(laborCost)} ₽';
  }

  /// Пустая статистика (все нули)
  static const ScheduleStatistics empty = ScheduleStatistics(
    totalHours: 0,
    shiftsCount: 0,
    employeesCount: 0,
    laborCost: 0,
  );

  @override
  String toString() {
    return 'ScheduleStatistics(hours: $hoursFormatted, shifts: $shiftsCount, employees: $employeesCount, cost: $costFormatted)';
  }
}
