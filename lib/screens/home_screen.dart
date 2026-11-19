import 'package:flutter/material.dart';
import '../controllers/habit_controller.dart';
import '../models/habit.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/empty_habits_view.dart';
import '../widgets/habit_archive_sheet.dart';
import '../widgets/habit_form_sheet.dart';
import '../widgets/habit_item_tile.dart';
import '../widgets/weekly_progress_bar.dart';

class HomeScreen extends StatefulWidget {
  final HabitController controller;

  const HomeScreen({
    super.key,
    required this.controller,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HabitController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _openCreateSheet() {
    HabitFormSheet.show(
      context: context,
      onSave: (newHabit) async {
        final success = await controller.createHabit(
          title: newHabit.title,
          description: newHabit.description,
          frequencyType: newHabit.frequencyType,
          targetWeekdays: newHabit.targetWeekdays,
          colorHex: newHabit.colorHex,
        );
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rhythm created: ${newHabit.title}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  void _openEditSheet(Habit habit) {
    HabitFormSheet.show(
      context: context,
      habit: habit,
      onSave: (updated) async {
        final success = await controller.updateHabit(updated);
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated "${updated.title}"'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onArchive: () => _confirmArchive(habit),
      onDelete: () => _confirmDelete(habit),
    );
  }

  void _confirmArchive(Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Archive Rhythm?', style: AppTypography.headlineSm()),
        content: Text(
          'Archiving "${habit.title}" will pause it from your daily schedule without deleting its past history.',
          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTypography.bodyMd(color: AppColors.outline)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.archiveHabit(habit.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Archived "${habit.title}"'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => controller.unarchiveHabit(habit.id),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Permanently?', style: AppTypography.headlineSm(color: AppColors.error)),
        content: Text(
          'This will permanently remove "${habit.title}" and all its historical completions. This action cannot be undone.',
          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTypography.bodyMd(color: AppColors.outline)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.deleteHabit(habit.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${habit.title}" permanently'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openArchiveSheet() {
    HabitArchiveSheet.show(
      context: context,
      archivedHabits: controller.archivedHabits,
      onUnarchive: (id) => controller.unarchiveHabit(id),
      onDelete: (id) => controller.deleteHabit(id),
    );
  }

  String _formatDateTitle(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, $month ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final todayDue = controller.todayDueHabits;
    final completedCount = controller.todayCompletedCount;
    final totalCount = controller.todayTotalCount;
    final progress = controller.todayProgressRatio;
    final weekly = controller.getWeeklyProgress();
    final archivedCount = controller.archivedHabits.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Date Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning, Elena',
                    style: AppTypography.headlineLg(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTitle(controller.selectedDate),
                    style: AppTypography.bodySm(color: AppColors.outline),
                  ),
                ],
              ),
              if (archivedCount > 0)
                TextButton.icon(
                  onPressed: _openArchiveSheet,
                  icon: const Icon(Icons.archive_outlined, size: 16),
                  label: Text('Archived ($archivedCount)'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.outline,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Weekly Progress Bar Ribbon
          WeeklyProgressBar(
            days: weekly,
            selectedDate: controller.selectedDate,
            onSelectDate: (date) => controller.selectDate(date),
          ),
          const SizedBox(height: 16),

          // Today's Progress Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today’s Progress',
                      style: AppTypography.headlineSm(color: AppColors.onSurface),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: progress == 1.0
                            ? AppColors.secondaryContainer
                            : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$completedCount of $totalCount tended',
                        style: AppTypography.labelSm(
                          color: progress == 1.0
                              ? AppColors.onSecondaryContainer
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? AppColors.secondary : AppColors.caramelMid,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Habit List Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Rhythms',
                style: AppTypography.headlineMd(color: AppColors.onSurface),
              ),
              IconButton(
                onPressed: _openCreateSheet,
                icon: const Icon(Icons.add_circle_outline, size: 22),
                color: AppColors.primary,
                tooltip: 'Add new rhythm',
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Habits List or Empty View
          if (todayDue.isEmpty)
            EmptyHabitsView(
              onAddHabit: _openCreateSheet,
              isScheduledEmpty: controller.activeHabits.isNotEmpty,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayDue.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final habit = todayDue[index];
                final isDone = controller.isHabitCompleted(habit.id, controller.selectedDate);
                final streak = controller.getStreakForHabit(habit.id);

                return HabitItemTile(
                  habit: habit,
                  isCompleted: isDone,
                  streakDays: streak,
                  onToggle: () => controller.toggleCompletion(habit.id, controller.selectedDate),
                  onEdit: () => _openEditSheet(habit),
                  onArchive: () => _confirmArchive(habit),
                  onDelete: () => _confirmDelete(habit),
                );
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
