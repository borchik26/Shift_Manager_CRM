import 'package:flutter/material.dart';
import 'package:my_app/branches/branch_view_model.dart';
import 'package:my_app/data/models/branch.dart';

/// Dialog for editing an existing branch
class EditBranchDialog extends StatefulWidget {
  final BranchViewModel viewModel;
  final Branch branch;

  const EditBranchDialog({
    super.key,
    required this.viewModel,
    required this.branch,
  });

  @override
  State<EditBranchDialog> createState() => _EditBranchDialogState();
}

class _EditBranchDialogState extends State<EditBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if name actually changed
    if (_nameController.text.trim() == widget.branch.name) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isSaving = true);

    final success = await widget.viewModel.updateBranch(
      widget.branch,
      _nameController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSaving = false);
      // Error message is handled by ViewModel and shown in parent
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.errorMessage ?? 'Ошибка обновления филиала'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать филиал'),
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

              // Check for duplicate branch name (excluding current branch)
              final trimmedValue = value.trim();
              final isDuplicate = widget.viewModel.branches.any(
                (b) => b.name.toLowerCase() == trimmedValue.toLowerCase() &&
                       b.id != widget.branch.id,
              );

              if (isDuplicate) {
                return 'Филиал с таким названием уже существует';
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
