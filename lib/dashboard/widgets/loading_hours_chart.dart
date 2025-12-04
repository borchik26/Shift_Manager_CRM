import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Chart widget showing weekly hours loading
class LoadingHoursChart extends StatelessWidget {
  final List<double> weeklyHours; // Monday-Sunday

  const LoadingHoursChart({
    super.key,
    required this.weeklyHours,
  });

  @override
  Widget build(BuildContext context) {
    final chartData = _buildChartData();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'График загрузки',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelStyle: const TextStyle(fontSize: 12),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(
                    text: 'Часы',
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  labelStyle: const TextStyle(fontSize: 12),
                ),
                series: <CartesianSeries<ChartData, String>>[
                  ColumnSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.day,
                    yValueMapper: (ChartData data, _) => data.hours,
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ChartData> _buildChartData() {
    final days = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    return List.generate(7, (index) {
      return ChartData(
        day: days[index],
        hours: weeklyHours[index],
      );
    });
  }
}

class ChartData {
  final String day;
  final double hours;

  ChartData({required this.day, required this.hours});
}

