import 'package:flutter/material.dart';
import '../controllers/coach_controller.dart';
import '../controllers/feed_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class FeedScreen extends StatelessWidget {
  final FeedController? controller;
  final CoachController? coachController;
  final VoidCallback? onOpenProfile;

  const FeedScreen({
    super.key,
    this.controller,
    this.coachController,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.espressoDeep.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_stories_outlined,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'COMING SOON',
                    style: AppTypography.labelSm(color: AppColors.primary).copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mindful Feed',
                  style: const TextStyle(
                    fontFamily: 'Newsreader',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Curated reflections, seasonal essays, and contemplative readings are being gathered.\n\nTake this moment to pause and breathe.',
                  style: AppTypography.bodyMd(color: AppColors.outline).copyWith(
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
