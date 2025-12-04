import 'package:flutter/material.dart';
import 'package:my_app/schedule/utils/shift_conflict_checker.dart';

/// Reusable Warning/Error box component for displaying shift conflicts
class ConflictWarningBox extends StatelessWidget {
  final List<ShiftConflict> conflicts;
  final bool showIgnoreOption;
  final bool ignoreWarning;
  final ValueChanged<bool>? onIgnoreChanged;

  const ConflictWarningBox({
    super.key,
    required this.conflicts,
    this.showIgnoreOption = true,
    this.ignoreWarning = false,
    this.onIgnoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (conflicts.isEmpty) return const SizedBox.shrink();

    final hasErrors = ShiftConflictChecker.hasHardErrors(conflicts);
    final hasWarnings = ShiftConflictChecker.hasWarnings(conflicts);

    // Determine box color and icon based on conflict severity
    final color = hasErrors ? Colors.red : Colors.orange;
    final icon = hasErrors ? Icons.error : Icons.warning_amber;
    final title = hasErrors ? 'Ошибка' : 'Предупреждение';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and title
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List of conflict messages
          ...conflicts.map((conflict) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        conflict.isWarning
                            ? Icons.info_outline
                            : Icons.close_rounded,
                        color: color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        conflict.message,
                        style: TextStyle(
                          color: color.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

          // Show "Ignore Warning" checkbox only for soft warnings
          if (hasWarnings && !hasErrors && showIgnoreOption) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 4),
            InkWell(
              onTap: onIgnoreChanged != null
                  ? () => onIgnoreChanged!(!ignoreWarning)
                  : null,
              child: Row(
                children: [
                  Checkbox(
                    value: ignoreWarning,
                    onChanged: onIgnoreChanged != null
                        ? (bool? value) => onIgnoreChanged!(value ?? false)
                        : null,
                    activeColor: color,
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Игнорировать предупреждение',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
