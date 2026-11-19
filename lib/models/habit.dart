enum HabitFrequencyType {
  daily,
  weekdays,
}

class Habit {
  final String id;
  final String title;
  final String? description;
  final HabitFrequencyType frequencyType;
  final List<int> targetWeekdays; // 1 = Monday, 7 = Sunday (matching DateTime.weekday)
  final String colorHex;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? archivedAt;

  const Habit({
    required this.id,
    required this.title,
    this.description,
    this.frequencyType = HabitFrequencyType.daily,
    this.targetWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.colorHex = '#744127',
    this.isArchived = false,
    required this.createdAt,
    this.archivedAt,
  });

  bool isScheduledFor(DateTime date) {
    if (isArchived) return false;
    if (frequencyType == HabitFrequencyType.daily) return true;
    return targetWeekdays.contains(date.weekday);
  }

  String get frequencyLabel {
    if (frequencyType == HabitFrequencyType.daily || targetWeekdays.length == 7) {
      return 'Every day';
    }
    if (targetWeekdays.length == 5 &&
        targetWeekdays.contains(1) &&
        targetWeekdays.contains(2) &&
        targetWeekdays.contains(3) &&
        targetWeekdays.contains(4) &&
        targetWeekdays.contains(5)) {
      return 'Weekdays (Mon–Fri)';
    }
    const dayNames = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    final sorted = List<int>.from(targetWeekdays)..sort();
    return sorted.map((d) => dayNames[d] ?? '').where((s) => s.isNotEmpty).join(', ');
  }

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    HabitFrequencyType? frequencyType,
    List<int>? targetWeekdays,
    String? colorHex,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? archivedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      frequencyType: frequencyType ?? this.frequencyType,
      targetWeekdays: targetWeekdays ?? this.targetWeekdays,
      colorHex: colorHex ?? this.colorHex,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'frequency_type': frequencyType.name,
      'target_weekdays': targetWeekdays,
      'color_hex': colorHex,
      'is_archived': isArchived,
      'created_at': createdAt.toIso8601String(),
      'archived_at': archivedAt?.toIso8601String(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      frequencyType: HabitFrequencyType.values.byName(
        json['frequency_type'] as String? ?? 'daily',
      ),
      targetWeekdays: (json['target_weekdays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      colorHex: json['color_hex'] as String? ?? '#744127',
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
    );
  }
}
