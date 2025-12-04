import 'package:flutter/material.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/utils/navigation/route_data.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';

/// Widget with quick action buttons
class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
              'Быстрые действия',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _navigateToSchedule(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Создать смену'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _navigateToEmployees(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Добавить сотрудника'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showReportMessage(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Скачать отчёт'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSchedule(BuildContext context) {
    locator<RouterService>().replace(Path(name: '/dashboard/schedule'));
  }

  void _navigateToEmployees(BuildContext context) {
    locator<RouterService>().replace(Path(name: '/dashboard/employees'));
  }

  void _showReportMessage(BuildContext context) {
    locator<NotifyService>().setToastEvent(
      ToastEventInfo(message: 'Функция в разработке'),
    );
  }
}

