import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/models/branch.dart';
import 'package:my_app/data/models/position.dart';

class ShiftFormLocationSection extends StatelessWidget {
  final ValueNotifier<AsyncValue<List<Position>>> positionsState;
  final ValueNotifier<AsyncValue<List<Branch>>> branchesState;
  final String? selectedRole;
  final String? selectedBranch;
  final String? selectedEmployeeId;
  final void Function(String?) onRoleChanged;
  final void Function(String?) onBranchChanged;
  final VoidCallback onLoadPositions;
  final VoidCallback onLoadBranches;

  const ShiftFormLocationSection({
    super.key,
    required this.positionsState,
    required this.branchesState,
    required this.selectedRole,
    required this.selectedBranch,
    required this.selectedEmployeeId,
    required this.onRoleChanged,
    required this.onBranchChanged,
    required this.onLoadPositions,
    required this.onLoadBranches,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: selectedEmployeeId != null
              ? InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Должность',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(selectedRole ?? '—', overflow: TextOverflow.ellipsis),
                )
              : ValueListenableBuilder<AsyncValue<List<Position>>>(
                  valueListenable: positionsState,
                  builder: (context, state, _) {
                    final items = state.dataOrNull ?? const <Position>[];
                    final names = items.map((p) => p.name).toList();
                    final disabled = state.isLoading || state.hasError || items.isEmpty;
                    final value = (!disabled && names.contains(selectedRole)) ? selectedRole : null;
                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: value,
                      onTap: onLoadPositions,
                      decoration: InputDecoration(
                        labelText: state.isLoading
                            ? 'Загрузка...'
                            : state.hasError
                                ? 'Ошибка загрузки'
                                : 'Должность',
                        border: const OutlineInputBorder(),
                      ),
                      items: items
                          .map((p) => DropdownMenuItem(
                                value: p.name,
                                child: Text(
                                  '${p.name} (${p.hourlyRate.toStringAsFixed(0)} ₽/ч)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: disabled ? null : onRoleChanged,
                      validator: (value) => value == null ? 'Выберите должность' : null,
                    );
                  },
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ValueListenableBuilder<AsyncValue<List<Branch>>>(
            valueListenable: branchesState,
            builder: (context, state, _) {
              final branches = state.dataOrNull ?? const <Branch>[];
              final names = branches.map((b) => b.name).toList();
              final disabled = state.isLoading || state.hasError || branches.isEmpty;
              final value = (!disabled && names.contains(selectedBranch)) ? selectedBranch : null;
              return DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: value,
                onTap: onLoadBranches,
                decoration: InputDecoration(
                  labelText: state.isLoading
                      ? 'Загрузка...'
                      : state.hasError
                          ? 'Ошибка загрузки'
                          : 'Филиал',
                  border: const OutlineInputBorder(),
                ),
                items: names
                    .map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: disabled ? null : onBranchChanged,
                validator: (value) => value == null ? 'Выберите филиал' : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
