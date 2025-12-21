import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';
import 'package:my_app/data/repositories/auth_repository.dart';
import 'package:my_app/employees_syncfusion/viewmodels/user_approval_view_model.dart';
import 'package:intl/intl.dart';

class UserApprovalTab extends StatefulWidget {
  const UserApprovalTab({super.key});

  @override
  State<UserApprovalTab> createState() => _UserApprovalTabState();
}

class _UserApprovalTabState extends State<UserApprovalTab> {
  late final UserApprovalViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UserApprovalViewModel(
      authRepository: locator<AuthRepository>(),
    );
    _viewModel.loadUsers();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showApproveDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение активации'),
        content: Text('Активировать пользователя "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _approveUser(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Активировать'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение отклонения'),
        content: Text('Отклонить пользователя "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectUser(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Удалить пользователя "$userName"? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveUser(String userId) async {
    try {
      await _viewModel.approveUser(userId);
      if (mounted) {
        locator<NotifyService>().setToastEvent(
          ToastEventSuccess(message: 'Пользователь активирован'),
        );
      }
    } catch (e) {
      if (mounted) {
        locator<NotifyService>().setToastEvent(
          ToastEventError(message: 'Ошибка активации: $e'),
        );
      }
    }
  }

  Future<void> _rejectUser(String userId) async {
    try {
      await _viewModel.rejectUser(userId);
      if (mounted) {
        locator<NotifyService>().setToastEvent(
          ToastEventSuccess(message: 'Пользователь отклонен'),
        );
      }
    } catch (e) {
      if (mounted) {
        locator<NotifyService>().setToastEvent(
          ToastEventError(message: 'Ошибка отклонения: $e'),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await _viewModel.deleteUser(userId);
      if (mounted) {
        locator<NotifyService>().setToastEvent(
          ToastEventSuccess(message: 'Пользователь удален'),
        );
      }
    } catch (e) {
      if (mounted) {
        locator<NotifyService>().setToastEvent(
          ToastEventError(message: 'Ошибка удаления: $e'),
        );
      }
    }
  }

  String _getStatusBadge(String status) {
    switch (status) {
      case 'active':
        return 'Активен';
      case 'inactive':
        return 'Неактивен';
      case 'pending':
        return 'Ожидание';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.usersState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_viewModel.usersState.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Ошибка: ${_viewModel.usersState.errorOrNull}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _viewModel.loadUsers,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Фильтр по статусу - всегда видимый
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Все'),
                    selected: _viewModel.statusFilter.isEmpty,
                    onSelected: (_) => _viewModel.setStatusFilter(''),
                  ),
                  FilterChip(
                    label: const Text('Ожидание'),
                    selected: _viewModel.statusFilter == 'pending',
                    onSelected: (_) => _viewModel.setStatusFilter('pending'),
                  ),
                  FilterChip(
                    label: const Text('Активные'),
                    selected: _viewModel.statusFilter == 'active',
                    onSelected: (_) => _viewModel.setStatusFilter('active'),
                  ),
                  FilterChip(
                    label: const Text('Неактивные'),
                    selected: _viewModel.statusFilter == 'inactive',
                    onSelected: (_) => _viewModel.setStatusFilter('inactive'),
                  ),
                ],
              ),
            ),
            // Список пользователей или сообщение о пустом списке
            Expanded(
              child: _viewModel.filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Нет пользователей',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _viewModel.filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _viewModel.filteredUsers[index];
                        final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              child: Text(
                                user.firstName?.isNotEmpty == true
                                    ? user.firstName![0].toUpperCase()
                                    : user.email[0].toUpperCase(),
                              ),
                            ),
                            title: Text(user.displayName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  'Email: ${user.email}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Роль: ${user.role == 'manager' ? 'Менеджер' : 'Сотрудник'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Регистрация: ${dateFormat.format(user.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                Chip(
                                  label: Text(_getStatusBadge(user.status)),
                                  backgroundColor: _getStatusColor(
                                    user.status,
                                  ).withValues(alpha: 0.2),
                                  labelStyle: TextStyle(
                                    color: _getStatusColor(user.status),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                if (user.isPending)
                                  PopupMenuItem(
                                    child: const Text('Активировать'),
                                    onTap: () => _showApproveDialog(
                                      user.id,
                                      user.displayName,
                                    ),
                                  ),
                                if (user.isPending)
                                  PopupMenuItem(
                                    child: const Text('Отклонить'),
                                    onTap: () => _showRejectDialog(
                                      user.id,
                                      user.displayName,
                                    ),
                                  ),
                                if (!user.isPending)
                                  PopupMenuItem(
                                    child: const Text('Удалить'),
                                    onTap: () => _showDeleteDialog(
                                      user.id,
                                      user.displayName,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
