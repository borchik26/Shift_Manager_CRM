import 'package:flutter/material.dart';
import 'package:my_app/branches/branch_view_model.dart';

/// Dialog for creating a new branch
class CreateBranchDialog extends StatefulWidget {
  final BranchViewModel viewModel;

  const CreateBranchDialog({
    super.key,
    required this.viewModel,
  });

  @override
  State<CreateBranchDialog> createState() => _CreateBranchDialogState();
}

class _CreateBranchDialogState extends State<CreateBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final success = await widget.viewModel.createBranch(_nameController.text);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSaving = false);
      // Error message is handled by ViewModel and shown in parent
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.errorMessage ?? 'Ошибка создания филиала'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить филиал'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Название филиала',
              hintText: 'Например: ТЦ Мега',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            enabled: !_isSaving,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите название филиала';
              }
              if (value.trim().length < 2) {
                return 'Название должно содержать минимум 2 символа';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleSave(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}
