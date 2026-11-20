import 'coach_action.dart';

enum CoachSender {
  user,
  coach,
}

class CoachMessage {
  final String id;
  final CoachSender sender;
  final String text;
  final DateTime timestamp;
  final CoachAction? action;
  final Map<String, dynamic>? metricsSummary;

  CoachMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.action,
    this.metricsSummary,
  });

  CoachMessage copyWith({
    String? id,
    CoachSender? sender,
    String? text,
    DateTime? timestamp,
    CoachAction? action,
    Map<String, dynamic>? metricsSummary,
  }) {
    return CoachMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      metricsSummary: metricsSummary ?? this.metricsSummary,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender.name,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'action': action?.toJson(),
        'metrics_summary': metricsSummary,
      };

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    return CoachMessage(
      id: json['id'] as String,
      sender: (json['sender'] == 'user') ? CoachSender.user : CoachSender.coach,
      text: json['text'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: json['action'] != null
          ? CoachAction.fromJson(json['action'] as Map<String, dynamic>)
          : null,
      metricsSummary: json['metrics_summary'] as Map<String, dynamic>?,
    );
  }
}
