import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/data/repositories/audit_log_repository.dart';
import 'package:my_app/audit_logs/viewmodels/audit_logs_view_model.dart';
import 'package:my_app/audit_logs/viewmodels/audit_log_data_source.dart';
import 'package:my_app/audit_logs/widgets/audit_log_filter_dialog.dart';
import 'package:my_app/audit_logs/widgets/audit_log_detail_dialog.dart';

/// Main audit logs screen for managers
/// Displays system-wide audit logs with filtering and search
class AuditLogsView extends StatefulWidget {
  const AuditLogsView({super.key});

  @override
  State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  late final AuditLogsViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();
  late AuditLogDataSource _dataSource;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = AuditLogsViewModel(
      repository: locator<AuditLogRepository>(),
      authService: locator<AuthService>(),
    );
    _dataSource = AuditLogDataSource([]);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _viewModel.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Логи системы'),
        actions: [
          // Search field
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по описанию или email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _viewModel.setSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
              ),
              onChanged: (query) {
                // Debounce search to avoid too many queries
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == query) {
                    _viewModel.setSearchQuery(query);
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 16),

          // Filter button
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => _showFilterDialog(context),
                    tooltip: 'Фильтры',
                  ),
                  if (_viewModel.activeFiltersCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_viewModel.activeFiltersCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Clear filters button
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.activeFiltersCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () {
                    _searchController.clear();
                    _viewModel.clearFilters();
                  },
                  tooltip: 'Очистить фильтры',
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _viewModel.refresh,
            tooltip: 'Обновить',
          ),

          // Delete all logs button
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _showDeleteConfirmationDialog(context),
            tooltip: 'Очистить все логи',
            color: Colors.red,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ValueListenableBuilder<AsyncValue<dynamic>>(
        valueListenable: _viewModel.state,
        builder: (context, state, _) {
          return state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки логов',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _viewModel.refresh,
                    child: const Text('Попробовать снова'),
                  ),
                ],
              ),
            ),
            data: (_) {
              if (_viewModel.logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Логи не найдены',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Попробуйте изменить фильтры'),
                    ],
                  ),
                );
              }

              // Update data source
              _dataSource.updateData(_viewModel.logs);

              return Column(
                children: [
                  // Info bar
                  ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Row(
                          children: [
                            Text(
                              'Показано: ${_viewModel.logs.length} логов',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            if (_viewModel.isLoadingMore)
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Загрузка...'),
                                ],
                              ),
                            if (!_viewModel.hasMore && !_viewModel.isLoadingMore)
                              const Text('Все логи загружены'),
                          ],
                        ),
                      );
                    },
                  ),

                  // DataGrid
                  Expanded(
                    child: SfDataGrid(
                      source: _dataSource,
                      controller: DataGridController(),
                      columnWidthMode: ColumnWidthMode.fill,
                      allowSorting: true,
                      allowMultiColumnSorting: false,
                      allowFiltering: false,
                      gridLinesVisibility: GridLinesVisibility.both,
                      headerGridLinesVisibility: GridLinesVisibility.both,
                      selectionMode: SelectionMode.single,
                      navigationMode: GridNavigationMode.row,
                      onCellTap: (details) {
                        if (details.rowColumnIndex.rowIndex > 0) {
                          final rowIndex = details.rowColumnIndex.rowIndex - 1;
                          if (rowIndex >= 0 &&
                              rowIndex < _viewModel.logs.length) {
                            final log = _viewModel.logs[rowIndex];
                            _showDetailDialog(context, log);
                          }
                        }
                      },
                      columns: [
                        GridColumn(
                          columnName: 'created_at',
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Дата и время',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          width: 150,
                        ),
                        GridColumn(
                          columnName: 'user_email',
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Пользователь',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          width: 200,
                        ),
                        GridColumn(
                          columnName: 'user_name',
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Имя',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          width: 150,
                        ),
                        GridColumn(
                          columnName: 'action',
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Действие',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          width: 130,
                        ),
                        GridColumn(
                          columnName: 'entity',
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Сущность',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          width: 120,
                        ),
                        GridColumn(
                          columnName: 'description',
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Описание',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        GridColumn(
                          columnName: 'status',
                          label: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: const Text(
                              'Статус',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          width: 100,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AuditLogFilterDialog(
        currentFilter: _viewModel.currentFilter,
        onApply: (filter) {
          _viewModel.applyFilter(filter);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showDetailDialog(BuildContext context, log) {
    showDialog(
      context: context,
      builder: (context) => AuditLogDetailDialog(log: log),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Подтверждение удаления'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вы уверены, что хотите удалить ВСЕ логи системы?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Это действие необратимо! Все записи аудита будут безвозвратно удалены.',
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 12),
            Text(
              'Это может повлиять на отслеживание изменений и безопасность системы.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _viewModel.deleteAllLogs();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Все логи успешно удалены'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить все логи'),
          ),
        ],
      ),
    );
  }
}
