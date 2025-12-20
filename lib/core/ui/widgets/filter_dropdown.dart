import 'package:flutter/material.dart';

class FilterDropdown<T> extends StatelessWidget {
  final T? value;
  final String emoji;
  final String label;
  final List<T> items;
  final String Function(T) itemLabel;
  final Widget Function(T)? itemBuilder;
  final ValueChanged<T?> onChanged;

  const FilterDropdown({
    super.key,
    required this.value,
    required this.emoji,
    required this.label,
    required this.items,
    required this.itemLabel,
    this.itemBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButton<T>(
        value: value,
        isDense: true,
        hint: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        underline: const SizedBox(),
        icon: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: itemBuilder?.call(item) ?? Text(itemLabel(item)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
