import 'package:flutter/material.dart';
import '../models/weekly_progress.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class WeeklyProgressBar extends StatelessWidget {
  final List<DayProgress> days;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  const WeeklyProgressBar({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.onSelectDate,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                'Weekly Rhythm',
                style: AppTypography.labelMd(color: AppColors.onSurfaceVariant),
              ),
              Text(
                'Mon – Sun',
                style: AppTypography.labelSm(color: AppColors.outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final isSelected = _isSameDay(day.date, selectedDate);
              final isToday = day.isToday;

              return GestureDetector(
                onTap: () => onSelectDate(day.date),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.surfaceContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.borderSubtle
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        day.dayLabel,
                        style: AppTypography.labelSm(
                          color: isToday
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ).copyWith(
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.date.day}',
                        style: AppTypography.bodySm(
                          color: isToday ? AppColors.onSurface : AppColors.outline,
                        ).copyWith(
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Dot indicator for completion
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: day.isAllCompleted
                              ? AppColors.secondary
                              : day.completedCount > 0
                                  ? AppColors.caramelMid
                                  : AppColors.surfaceContainerHigh,
                        ),
                        child: day.isAllCompleted
                            ? const Center(
                                child: Icon(
                                  Icons.check,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              )
                            : (day.completedCount > 0
                                ? Center(
                                    child: Text(
                                      '${day.completedCount}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : null),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
