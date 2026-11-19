import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class IntentionCard extends StatelessWidget {
  final String intention;
  final String promptText;

  const IntentionCard({
    super.key,
    required this.intention,
    required this.promptText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061B1C1A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Today’s Intention',
                  style: AppTypography.labelSm(color: AppColors.onSecondaryContainer),
                ),
              ),
              const Icon(
                Icons.spa_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Literary quote style headline
          Text(
            '"$intention"',
            style: AppTypography.quote(color: AppColors.onSurface),
          ),
          const SizedBox(height: 14),

          // Divider
          const Divider(color: AppColors.surfaceContainerHigh, height: 1),
          const SizedBox(height: 14),

          // Reflection Prompt
          Row(
            children: [
              const Icon(
                Icons.auto_stories_outlined,
                size: 16,
                color: AppColors.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  promptText,
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
