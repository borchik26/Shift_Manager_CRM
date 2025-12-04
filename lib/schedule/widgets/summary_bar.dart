import 'package:flutter/material.dart';
import 'package:my_app/schedule/utils/schedule_statistics.dart';

/// Панель суммарной статистики смен (отображается внизу экрана)
/// Показывает: отработанные часы, количество смен, количество сотрудников, затраты на оплату
class SummaryBar extends StatelessWidget {
  final ScheduleStatistics statistics;

  const SummaryBar({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            icon: Icons.schedule,
            label: 'Отработано часов',
            value: statistics.hoursFormatted,
            color: Colors.blue,
          ),
          _SummaryItem(
            icon: Icons.event_note,
            label: 'Количество смен',
            value: '${statistics.shiftsCount}',
            color: Colors.green,
          ),
          _SummaryItem(
            icon: Icons.people,
            label: 'Сотрудников',
            value: '${statistics.employeesCount}',
            color: Colors.orange,
          ),
          _SummaryItem(
            icon: Icons.attach_money,
            label: 'Затраты на оплату',
            value: statistics.costFormatted,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

/// Отдельный элемент статистики (иконка, лейбл, значение)
class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
