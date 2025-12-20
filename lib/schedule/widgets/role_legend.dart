import 'package:flutter/material.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/core/utils/color_generator.dart';
import 'package:my_app/schedule/viewmodels/schedule_view_model.dart';

class RoleLegend extends StatelessWidget {
  final ScheduleViewModel viewModel;

  const RoleLegend({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AsyncValue<List<String>>>(
      valueListenable: viewModel.rolesState,
      builder: (context, state, _) {
        if (state.isLoading || state.hasError) return const SizedBox.shrink();
        final roles = state.dataOrNull ?? [];
        if (roles.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              Text(
                'ДОЛЖНОСТИ:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 16),
              ...roles.map((role) {
                final color = ColorGenerator.generateColor(role);
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(role, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
