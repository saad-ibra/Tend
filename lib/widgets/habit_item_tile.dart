import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class HabitItemTile extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final int streakDays;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const HabitItemTile({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.streakDays,
    required this.onToggle,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitColor = _parseColor(habit.colorHex);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.borderSubtle.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x063B2317),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Organic Custom Checkpoint
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted ? habitColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted ? habitColor : AppColors.borderSubtle,
                        width: isCompleted ? 0 : 1.6,
                      ),
                    ),
                    child: isCompleted
                        ? const Center(
                            child: Icon(
                              Icons.check,
                              size: 15,
                              color: AppColors.surface,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),

                // Details (Title, Frequency / Description)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: AppTypography.headlineSm(
                          color: isCompleted
                              ? AppColors.outline
                              : AppColors.onSurface,
                        ).copyWith(
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: AppColors.outline,
                        ),
                        child: Text(habit.title),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        habit.description != null && habit.description!.isNotEmpty
                            ? habit.description!
                            : habit.frequencyLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm(
                          color: isCompleted
                              ? AppColors.outline.withValues(alpha: 0.6)
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Streak Badge (if streak > 0)
                if (streakDays > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.caramelCream.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$streakDays d',
                          style: AppTypography.labelSm(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                // Action Menu
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: AppColors.outline,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  color: AppColors.surfaceContainerLowest,
                  elevation: 4,
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'archive') {
                      onArchive();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Text('Edit Habit', style: AppTypography.bodyMd()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          const Icon(Icons.archive_outlined, size: 18, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Text('Archive', style: AppTypography.bodyMd()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          const SizedBox(width: 10),
                          Text('Delete', style: AppTypography.bodyMd(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
