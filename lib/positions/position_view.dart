import 'package:flutter/material.dart';
import 'package:my_app/positions/position_view_model.dart';
import 'package:my_app/positions/widgets/create_position_dialog.dart';
import 'package:my_app/positions/widgets/edit_position_dialog.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/data/models/position.dart';
import 'package:my_app/data/repositories/position_repository.dart';

/// Main view for managing job positions
class PositionView extends StatefulWidget {
  const PositionView({super.key});

  @override
  State<PositionView> createState() => _PositionViewState();
}

class _PositionViewState extends State<PositionView> {
  late final PositionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PositionViewModel(
      positionRepository: locator<PositionRepository>(),
    );
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    await _viewModel.loadPositions();
  }

  Future<void> _showCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreatePositionDialog(viewModel: _viewModel),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Должность успешно создана'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showEditDialog(Position position) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditPositionDialog(
        viewModel: _viewModel,
        position: position,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Должность успешно обновлена'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Position position) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить должность?'),
        content: Text(
          'Вы уверены, что хотите удалить должность "${position.name}"?\n\nЭто действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _viewModel.deletePosition(position.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Должность успешно удалена'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_viewModel.errorMessage ?? 'Ошибка удаления должности'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Должности'),
        actions: [
          if (MediaQuery.of(context).size.width >= 600)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Добавить должность'),
              ),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.positions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.hasError && _viewModel.positions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _viewModel.errorMessage ?? 'Произошла ошибка',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadPositions,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (_viewModel.positions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.badge_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Должности отсутствуют',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Добавьте первую должность',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить должность'),
                  ),
                ],
              ),
            );
          }

          final isDesktop = MediaQuery.of(context).size.width >= 600;

          return RefreshIndicator(
            onRefresh: _loadPositions,
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          );
        },
      ),
      floatingActionButton: MediaQuery.of(context).size.width < 600
          ? FloatingActionButton(
              onPressed: _showCreateDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildMobileLayout() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _viewModel.positions.length,
      itemBuilder: (context, index) {
        final position = _viewModel.positions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.badge,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              position.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Ставка: ${_formatRate(position.hourlyRate)} ₽/ч',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(position);
                } else if (value == 'delete') {
                  _confirmDelete(position);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 12),
                      Text('Редактировать'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Удалить', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Название',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Ставка (₽/ч)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(width: 100),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _viewModel.positions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final position = _viewModel.positions[index];
                return InkWell(
                  onTap: () => _showEditDialog(position),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            position.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(_formatRate(position.hourlyRate)),
                        ),
                        SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                tooltip: 'Редактировать',
                                onPressed: () => _showEditDialog(position),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                tooltip: 'Удалить',
                                color: Colors.red,
                                onPressed: () => _confirmDelete(position),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatRate(double rate) {
    return rate.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '');
  }
}
