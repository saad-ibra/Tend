import 'coach_message.dart';

class CoachSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isArchived;
  final List<CoachMessage> messages;

  CoachSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.messages = const [],
  });

  CoachSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
    List<CoachMessage>? messages,
  }) {
    return CoachSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_pinned': isPinned,
        'is_archived': isArchived,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory CoachSession.fromJson(Map<String, dynamic> json) {
    return CoachSession(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Rhythm Reflection',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => CoachMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
