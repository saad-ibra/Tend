import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class EmptyHabitsView extends StatelessWidget {
  final VoidCallback onAddHabit;
  final bool isScheduledEmpty;

  const EmptyHabitsView({
    super.key,
    required this.onAddHabit,
    this.isScheduledEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainer,
            ),
            child: const Center(
              child: Icon(
                Icons.spa_outlined,
                size: 24,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isScheduledEmpty ? 'No Rhythms Scheduled' : 'No Habits Created Yet',
            style: AppTypography.headlineMd(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isScheduledEmpty
                ? 'You have no habits scheduled for this day. Rest and enjoy your quiet focus.'
                : 'Begin by planting a small, intentional daily rhythm.',
            style: AppTypography.bodySm(color: AppColors.outline),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAddHabit,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add a Rhythm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
