import 'package:flutter/material.dart';
import 'package:my_app/audit_logs/viewmodels/audit_logs_view_model.dart';
import 'package:my_app/audit_logs/widgets/audit_log_filter_dialog.dart';
import 'package:my_app/audit_logs/widgets/audit_log_detail_dialog.dart';
import 'package:intl/intl.dart';

class MobileAuditLogsView {
  static Widget build({
    required BuildContext context,
    required AuditLogsViewModel viewModel,
    required TextEditingController searchController,
    required ScrollController scrollController,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Логи системы',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: viewModel.refresh,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showFilterDialog(context, viewModel),
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
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 16),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    searchController.clear();
                                    viewModel.setSearchQuery('');
                                  },
                                )
                              : null,
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
                        onChanged: (query) {
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (searchController.text == query) {
                              viewModel.setSearchQuery(query);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Text(
                    'Показано: ${viewModel.logs.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  if (viewModel.isLoadingMore)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (!viewModel.hasMore && !viewModel.isLoadingMore)
                    const Text('Все загружено', style: TextStyle(fontSize: 11)),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) {
              if (viewModel.logs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Логи не найдены', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Попробуйте изменить фильтры', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: viewModel.logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final log = viewModel.logs[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () => _showDetailDialog(context, log),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(log.status),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.status ?? 'N/A',
                                    style: const TextStyle(fontSize: 10, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    log.actionType ?? 'N/A',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  DateFormat('dd.MM HH:mm').format(log.createdAt),
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              log.description ?? 'Нет описания',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    log.userName ?? log.userEmail ?? 'N/A',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (log.entityType != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      log.entityType!,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  static Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static void _showFilterDialog(BuildContext context, AuditLogsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AuditLogFilterDialog(
        currentFilter: viewModel.currentFilter,
        onApply: (filter) {
          viewModel.applyFilter(filter);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  static void _showDetailDialog(BuildContext context, log) {
    showDialog(
      context: context,
      builder: (context) => AuditLogDetailDialog(log: log),
    );
  }
}
