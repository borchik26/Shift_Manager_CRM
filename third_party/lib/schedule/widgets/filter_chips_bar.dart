import 'package:flutter/material.dart';
import 'package:my_app/schedule/constants/filter_presets.dart';

/// Горизонтальная полоса с быстрыми фильтрами (чипами)
class FilterChipsBar extends StatelessWidget {
  const FilterChipsBar({
    super.key,
    required this.activePresetId,
    required this.onPresetToggle,
  });

  final String? activePresetId;
  final void Function(String presetId) onPresetToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: FilterPresets.all.map((preset) {
          final isActive = activePresetId == preset.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    preset.icon,
                    size: 16,
                    color: isActive ? Colors.white : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(preset.label),
                ],
              ),
              selected: isActive,
              onSelected: (_) => onPresetToggle(preset.id),
              selectedColor: Colors.blue.shade700,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.blue.shade700,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isActive ? Colors.blue.shade700 : Colors.grey.shade300,
                width: isActive ? 2 : 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }
}
