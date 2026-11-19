class DayProgress {
  final DateTime date;
  final String dateKey;
  final String dayLabel; // e.g. "M", "T", "W"
  final int completedCount;
  final int totalDueCount;
  final bool isToday;
  final bool isFuture;

  const DayProgress({
    required this.date,
    required this.dateKey,
    required this.dayLabel,
    required this.completedCount,
    required this.totalDueCount,
    required this.isToday,
    required this.isFuture,
  });

  double get ratio {
    if (totalDueCount == 0) return 0.0;
    return (completedCount / totalDueCount).clamp(0.0, 1.0);
  }

  bool get isAllCompleted => totalDueCount > 0 && completedCount >= totalDueCount;
}
