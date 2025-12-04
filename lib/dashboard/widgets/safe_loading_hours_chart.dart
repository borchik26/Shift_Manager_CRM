import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/dashboard/widgets/loading_hours_chart.dart';

/// Безопасная обертка для LoadingHoursChart, предотвращающая ошибку
/// "A disposed RenderObject was mutated" при навигации.
/// 
/// **ПРОБЛЕМА**: Syncfusion Charts пытается выполнить layout операции
/// во время unmount, если parent виджет (ValueListenableBuilder) 
/// отправляет обновления во время dispose.
/// 
/// **РЕШЕНИЕ**: Этот wrapper НЕМЕДЛЕННО отписывается от ValueNotifier
/// в deactivate(), гарантируя что chart не получит никаких обновлений
/// во время unmount процесса.
class SafeLoadingHoursChart extends StatefulWidget {
  final ValueNotifier<AsyncValue<List<Shift>>> weeklyShiftsState;
  final List<double> Function() getWeeklyHours;

  const SafeLoadingHoursChart({
    super.key,
    required this.weeklyShiftsState,
    required this.getWeeklyHours,
  });

  @override
  State<SafeLoadingHoursChart> createState() => _SafeLoadingHoursChartState();
}

class _SafeLoadingHoursChartState extends State<SafeLoadingHoursChart> {
  late List<double> _frozenData;
  bool _isListening = true;

  @override
  void initState() {
    super.initState();
    _frozenData = widget.getWeeklyHours();
    widget.weeklyShiftsState.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    // Обновляем данные только если мы еще слушаем
    if (_isListening && mounted) {
      setState(() {
        _frozenData = widget.getWeeklyHours();
      });
    }
  }

  @override
  void deactivate() {
    // КРИТИЧНО: НЕМЕДЛЕННО прекращаем слушать ValueNotifier.
    // Это гарантирует, что chart не получит обновления во время unmount.
    _isListening = false;
    widget.weeklyShiftsState.removeListener(_onDataChanged);
    super.deactivate();
  }

  @override
  void dispose() {
    // На всякий случай - хотя уже отписались в deactivate
    if (_isListening) {
      widget.weeklyShiftsState.removeListener(_onDataChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncShifts = widget.weeklyShiftsState.value;

    return asyncShifts.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      data: (_) => LoadingHoursChart(
        weeklyHours: _frozenData,
      ),
      error: (message) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Ошибка: $message'),
        ),
      ),
    );
  }
}

