import 'package:flutter/material.dart';
import '../models/coach_action.dart';
import '../models/coach_message.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'coach_action_card.dart';

class CoachMessageBubble extends StatelessWidget {
  final CoachMessage message;
  final Function(CoachAction)? onAcceptAction;
  final Function(CoachAction)? onDismissAction;

  const CoachMessageBubble({
    super.key,
    required this.message,
    this.onAcceptAction,
    this.onDismissAction,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == CoachSender.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 2, right: 8),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.surfaceContainer
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppColors.borderSubtle
                      : AppColors.borderSubtle.withValues(alpha: 0.8),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x043B2317),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text content
                  SelectableText(
                    message.text,
                    style: AppTypography.bodyMd(
                      color: isUser ? AppColors.onSurface : AppColors.onSurfaceVariant,
                    ).copyWith(height: 1.5),
                  ),

                  // Weekly summary if present
                  if (message.metricsSummary != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.caramelCream.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.caramelMid.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.show_chart, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Weekly Adherence: ${message.metricsSummary!['completion_rate'] ?? '—'}',
                                style: AppTypography.labelSm(color: AppColors.primary),
                              ),
                            ],
                          ),
                          if (message.metricsSummary!['highlight'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '• Strength: ${message.metricsSummary!['highlight']}',
                              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(fontSize: 12),
                            ),
                          ],
                          if (message.metricsSummary!['growth_area'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '• Focus: ${message.metricsSummary!['growth_area']}',
                              style: AppTypography.bodySm(color: AppColors.outline).copyWith(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Action Card if present
                  if (message.action != null)
                    CoachActionCard(
                      message: message,
                      action: message.action!,
                      onAccept: () => onAcceptAction?.call(message.action!),
                      onDismiss: () => onDismissAction?.call(message.action!),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
