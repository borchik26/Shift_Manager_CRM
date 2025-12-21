import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/branches/branch_view_model.dart';
import 'package:my_app/branches/widgets/create_branch_dialog.dart';
import 'package:my_app/branches/widgets/edit_branch_dialog.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/data/models/branch.dart';
import 'package:my_app/data/repositories/branch_repository.dart';

/// Main view for managing branches
class BranchView extends StatefulWidget {
  const BranchView({super.key});

  @override
  State<BranchView> createState() => _BranchViewState();
}

class _BranchViewState extends State<BranchView> {
  late final BranchViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BranchViewModel(
      branchRepository: locator<BranchRepository>(),
    );
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    await _viewModel.loadBranches();
  }

  Future<void> _showCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateBranchDialog(viewModel: _viewModel),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Филиал успешно создан'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showEditDialog(Branch branch) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditBranchDialog(
        viewModel: _viewModel,
        branch: branch,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Филиал успешно обновлен'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Branch branch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить филиал?'),
        content: Text(
          'Вы уверены, что хотите удалить филиал "${branch.name}"?\n\nЭто действие нельзя отменить.',
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
      final success = await _viewModel.deleteBranch(branch.id);
      if (mounted) {
        final operationError = _viewModel.operationState.errorOrNull;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Филиал успешно удален'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(operationError ?? 'Ошибка удаления филиала'),
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
        title: const Text('Филиалы'),
        actions: [
          // Desktop: Add button in AppBar
          if (MediaQuery.of(context).size.width >= 600)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Добавить филиал'),
              ),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return _viewModel.branchesState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadBranches,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ),
            data: (branches) {
              if (branches.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Филиалы отсутствуют',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Добавьте первый филиал',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _showCreateDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить филиал'),
                      ),
                    ],
                  ),
                );
              }

              final isDesktop = MediaQuery.of(context).size.width >= 600;
              return RefreshIndicator(
                onRefresh: _loadBranches,
                child: isDesktop ? _buildDesktopLayout(branches) : _buildMobileLayout(branches),
              );
            },
          );
        },
      ),
      // Mobile: FloatingActionButton
      floatingActionButton: MediaQuery.of(context).size.width < 600
          ? FloatingActionButton(
              onPressed: _showCreateDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildMobileLayout(List<Branch> branches) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: branches.length,
      itemBuilder: (context, index) {
        final branch = branches[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.business,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              branch.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Создан: ${_formatDate(branch.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(branch);
                } else if (value == 'delete') {
                  _confirmDelete(branch);
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

  Widget _buildDesktopLayout(List<Branch> branches) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Table Header
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
                      'Дата создания',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(width: 100), // Actions column width
                ],
              ),
            ),
            // Table Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: branches.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final branch = branches[index];
                return InkWell(
                  onTap: () => _showEditDialog(branch),
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
                            branch.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(_formatDate(branch.createdAt)),
                        ),
                        SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                tooltip: 'Редактировать',
                                onPressed: () => _showEditDialog(branch),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                tooltip: 'Удалить',
                                color: Colors.red,
                                onPressed: () => _confirmDelete(branch),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
