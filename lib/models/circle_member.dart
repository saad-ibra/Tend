class CircleMember {
  final String id;
  final String name;
  final String avatarInitial;
  final String currentRhythm;
  final bool tendedToday;
  final int streakDays;

  CircleMember({
    required this.id,
    required this.name,
    required this.avatarInitial,
    required this.currentRhythm,
    required this.tendedToday,
    required this.streakDays,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_initial': avatarInitial,
        'current_rhythm': currentRhythm,
        'tended_today': tendedToday,
        'streak_days': streakDays,
      };

  factory CircleMember.fromJson(Map<String, dynamic> json) {
    return CircleMember(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Practitioner',
      avatarInitial: json['avatar_initial'] as String? ?? 'P',
      currentRhythm: json['current_rhythm'] as String? ?? 'Daily rhythm',
      tendedToday: json['tended_today'] as bool? ?? false,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
    );
  }
}
