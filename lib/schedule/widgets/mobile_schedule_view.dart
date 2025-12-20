import 'package:flutter/material.dart';
import 'package:my_app/schedule/viewmodels/schedule_view_model.dart';
import 'package:my_app/schedule/views/mobile_schedule_grid_view.dart';

class MobileScheduleView {
  static Widget build({
    required BuildContext context,
    required ScheduleViewModel viewModel,
    required VoidCallback onFiltersTap,
  }) {
    return SafeArea(
      top: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'График смен',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: onFiltersTap,
                    icon: ListenableBuilder(
                      listenable: viewModel,
                      builder: (context, _) {
                        return Badge(
                          isLabelVisible: viewModel.activeFiltersCount > 0,
                          label: Text('${viewModel.activeFiltersCount}'),
                          child: const Icon(Icons.filter_list, size: 16),
                        );
                      },
                    ),
                    label: const Text('Фильтры', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Поиск...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 16),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: viewModel.setSearchQuery,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) {
                  return MobileScheduleGridView(viewModel: viewModel);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
