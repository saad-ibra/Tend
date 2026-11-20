import 'package:flutter/material.dart';
import '../models/coach_action.dart';
import '../models/coach_message.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class CoachActionCard extends StatelessWidget {
  final CoachMessage message;
  final CoachAction action;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const CoachActionCard({
    super.key,
    required this.message,
    required this.action,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isCreate = action.type == CoachActionType.createHabit;
    final badgeLabel = isCreate ? 'PROPOSED NEW RHYTHM' : 'SUGGESTED ADJUSTMENT';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: action.isExecuted
              ? AppColors.secondary.withValues(alpha: 0.6)
              : AppColors.caramelMid.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.caramelCream.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (action.isExecuted)
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      'Tended & Added',
                      style: AppTypography.labelSm(color: AppColors.secondary),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            action.title,
            style: AppTypography.headlineSm(),
          ),
          if (action.description != null && action.description!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              action.description!,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ],
          if (action.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                action.reason,
                style: AppTypography.bodySm(color: AppColors.outline).copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Action Confirmation Buttons
          if (!action.isExecuted && !action.isDismissed)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      isCreate ? 'Accept & Create' : 'Accept & Update',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.outline,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                  child: const Text('Dismiss', style: TextStyle(fontSize: 13)),
                ),
              ],
            )
          else if (action.isDismissed)
            Text(
              'Suggestion dismissed',
              style: AppTypography.labelSm(color: AppColors.outline),
            ),
        ],
      ),
    );
  }
}
