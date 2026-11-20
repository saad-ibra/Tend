import 'circle_member.dart';

class RhythmCircle {
  final String id;
  final String name;
  final String philosophy;
  final String category; // 'Morning', 'Focus', 'Rest', 'Creative', 'Movement'
  final String rhythmFocus;
  final int memberCount;
  final int weeklyConsistencyPercent;
  final bool isJoined;
  final List<CircleMember> members;
  final DateTime createdAt;

  RhythmCircle({
    required this.id,
    required this.name,
    required this.philosophy,
    required this.category,
    required this.rhythmFocus,
    required this.memberCount,
    required this.weeklyConsistencyPercent,
    this.isJoined = false,
    required this.members,
    required this.createdAt,
  });

  RhythmCircle copyWith({
    String? id,
    String? name,
    String? philosophy,
    String? category,
    String? rhythmFocus,
    int? memberCount,
    int? weeklyConsistencyPercent,
    bool? isJoined,
    List<CircleMember>? members,
    DateTime? createdAt,
  }) {
    return RhythmCircle(
      id: id ?? this.id,
      name: name ?? this.name,
      philosophy: philosophy ?? this.philosophy,
      category: category ?? this.category,
      rhythmFocus: rhythmFocus ?? this.rhythmFocus,
      memberCount: memberCount ?? this.memberCount,
      weeklyConsistencyPercent:
          weeklyConsistencyPercent ?? this.weeklyConsistencyPercent,
      isJoined: isJoined ?? this.isJoined,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'philosophy': philosophy,
        'category': category,
        'rhythm_focus': rhythmFocus,
        'member_count': memberCount,
        'weekly_consistency_percent': weeklyConsistencyPercent,
        'is_joined': isJoined,
        'members': members.map((m) => m.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };

  factory RhythmCircle.fromJson(Map<String, dynamic> json) {
    return RhythmCircle(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Rhythm Circle',
      philosophy: json['philosophy'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      rhythmFocus: json['rhythm_focus'] as String? ?? 'Daily Rhythm',
      memberCount: (json['member_count'] as num?)?.toInt() ?? 1,
      weeklyConsistencyPercent:
          (json['weekly_consistency_percent'] as num?)?.toInt() ?? 80,
      isJoined: json['is_joined'] as bool? ?? false,
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => CircleMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
