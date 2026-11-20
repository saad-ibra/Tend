import 'habit.dart';

enum CoachActionType {
  createHabit,
  modifyHabit,
  none,
}

class CoachAction {
  final String id;
  final CoachActionType type;
  final String? targetHabitId;
  final String title;
  final String? description;
  final HabitFrequencyType frequencyType;
  final List<int> targetWeekdays;
  final String colorHex;
  final String reason;
  bool isExecuted;
  bool isDismissed;

  CoachAction({
    required this.id,
    required this.type,
    this.targetHabitId,
    required this.title,
    this.description,
    this.frequencyType = HabitFrequencyType.daily,
    this.targetWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.colorHex = '#744127',
    this.reason = '',
    this.isExecuted = false,
    this.isDismissed = false,
  });

  CoachAction copyWith({
    String? id,
    CoachActionType? type,
    String? targetHabitId,
    String? title,
    String? description,
    HabitFrequencyType? frequencyType,
    List<int>? targetWeekdays,
    String? colorHex,
    String? reason,
    bool? isExecuted,
    bool? isDismissed,
  }) {
    return CoachAction(
      id: id ?? this.id,
      type: type ?? this.type,
      targetHabitId: targetHabitId ?? this.targetHabitId,
      title: title ?? this.title,
      description: description ?? this.description,
      frequencyType: frequencyType ?? this.frequencyType,
      targetWeekdays: targetWeekdays ?? this.targetWeekdays,
      colorHex: colorHex ?? this.colorHex,
      reason: reason ?? this.reason,
      isExecuted: isExecuted ?? this.isExecuted,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'target_habit_id': targetHabitId,
        'title': title,
        'description': description,
        'frequency_type': frequencyType.name,
        'target_weekdays': targetWeekdays,
        'color_hex': colorHex,
        'reason': reason,
        'is_executed': isExecuted,
        'is_dismissed': isDismissed,
      };

  factory CoachAction.fromJson(Map<String, dynamic> json) {
    CoachActionType resolvedType = CoachActionType.none;
    final typeStr = json['type'] as String? ?? '';
    if (typeStr == 'createHabit' || typeStr == 'create_habit') {
      resolvedType = CoachActionType.createHabit;
    } else if (typeStr == 'modifyHabit' || typeStr == 'modify_habit') {
      resolvedType = CoachActionType.modifyHabit;
    }

    HabitFrequencyType resolvedFreq = HabitFrequencyType.daily;
    final freqStr = json['frequency_type'] as String? ?? '';
    if (freqStr == 'weekdays') {
      resolvedFreq = HabitFrequencyType.weekdays;
    }

    return CoachAction(
      id: json['id'] as String? ?? 'act_${DateTime.now().millisecondsSinceEpoch}',
      type: resolvedType,
      targetHabitId: json['target_habit_id'] as String?,
      title: json['title'] as String? ?? 'New Rhythm',
      description: json['description'] as String?,
      frequencyType: resolvedFreq,
      targetWeekdays: (json['target_weekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      colorHex: json['color_hex'] as String? ?? '#744127',
      reason: json['reason'] as String? ?? '',
      isExecuted: json['is_executed'] as bool? ?? false,
      isDismissed: json['is_dismissed'] as bool? ?? false,
    );
  }
}
