class HabitCompletion {
  final String id;
  final String habitId;
  final String dateKey; // Format: YYYY-MM-DD
  final DateTime completedAt;

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.dateKey,
    required this.completedAt,
  });

  static String formatDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habit_id': habitId,
      'date_key': dateKey,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      dateKey: json['date_key'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }
}
