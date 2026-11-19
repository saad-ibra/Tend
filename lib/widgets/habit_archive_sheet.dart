import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class HabitArchiveSheet extends StatelessWidget {
  final List<Habit> archivedHabits;
  final ValueChanged<String> onUnarchive;
  final ValueChanged<String> onDelete;

  const HabitArchiveSheet({
    super.key,
    required this.archivedHabits,
    required this.onUnarchive,
    required this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required List<Habit> archivedHabits,
    required ValueChanged<String> onUnarchive,
    required ValueChanged<String> onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => HabitArchiveSheet(
        archivedHabits: archivedHabits,
        onUnarchive: onUnarchive,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grab Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Archived Rhythms',
                    style: AppTypography.headlineMd(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Paused habits kept safe in your ledger',
                    style: AppTypography.bodySm(color: AppColors.outline),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20, color: AppColors.outline),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (archivedHabits.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.archive_outlined,
                      size: 32,
                      color: AppColors.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No archived habits',
                      style: AppTypography.headlineSm(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Habits you archive will appear here.',
                      style: AppTypography.bodySm(color: AppColors.outline),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: archivedHabits.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final habit = archivedHabits[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.title,
                                style: AppTypography.bodyMd(
                                  color: AppColors.onSurface,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                habit.frequencyLabel,
                                style: AppTypography.bodySm(
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            onUnarchive(habit.id);
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.unarchive_outlined, size: 16),
                          label: const Text('Restore'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            onDelete(habit.id);
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.error,
                          tooltip: 'Delete permanently',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
