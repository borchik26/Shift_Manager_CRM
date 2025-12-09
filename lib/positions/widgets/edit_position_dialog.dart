import 'package:flutter/material.dart';
import 'package:my_app/data/models/position.dart';
import 'package:my_app/positions/position_view_model.dart';

/// Dialog for editing an existing position
class EditPositionDialog extends StatefulWidget {
  final PositionViewModel viewModel;
  final Position position;

  const EditPositionDialog({
    super.key,
    required this.viewModel,
    required this.position,
  });

  @override
  State<EditPositionDialog> createState() => _EditPositionDialogState();
}

class _EditPositionDialogState extends State<EditPositionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _rateController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.position.name);
    _rateController = TextEditingController(
      text: widget.position.hourlyRate.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  double? _parseRate(String value) {
    try {
      return double.parse(value.replaceAll(',', '.'));
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final parsedRate = _parseRate(_rateController.text);
    if (parsedRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректную ставку'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If nothing changed, close dialog
    if (_nameController.text.trim() == widget.position.name &&
        parsedRate == widget.position.hourlyRate) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isSaving = true);

    final success = await widget.viewModel.updatePosition(
      widget.position,
      _nameController.text,
      parsedRate,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.errorMessage ?? 'Ошибка обновления должности'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать должность'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название должности',
                  hintText: 'Например: Кассир',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                enabled: !_isSaving,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название должности';
                  }
                  if (value.trim().length < 2) {
                    return 'Название должно содержать минимум 2 символа';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleSave(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(
                  labelText: 'Часовая ставка (₽)',
                  hintText: 'Например: 450',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: !_isSaving,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите часовую ставку';
                  }
                  final rate = _parseRate(value);
                  if (rate == null || rate <= 0) {
                    return 'Ставка должна быть больше 0';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleSave(),
              ),
            ],
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
