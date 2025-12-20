import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShiftFormDateTimeSection extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double duration;
  final VoidCallback onSelectDate;
  final void Function(bool) onSelectTime;

  const ShiftFormDateTimeSection({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.onSelectDate,
    required this.onSelectTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onSelectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Дата',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => onSelectTime(true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Начало',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(startTime.format(context)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => onSelectTime(false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Конец',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(endTime.format(context)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Длительность: ${duration.toStringAsFixed(1)} ч',
          style: TextStyle(
            color: duration < 2 ? Colors.red : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
