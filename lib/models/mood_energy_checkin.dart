class MoodEnergyCheckIn {
  final String id;
  final String dateKey; // YYYY-MM-DD
  final DateTime createdAt;
  final int moodScore; // 1 to 5
  final int energyScore; // 1 to 5
  final List<String> tags;
  final String note;

  const MoodEnergyCheckIn({
    required this.id,
    required this.dateKey,
    required this.createdAt,
    required this.moodScore,
    required this.energyScore,
    this.tags = const [],
    this.note = '',
  });

  static String getMoodLabel(int score) {
    switch (score) {
      case 1:
        return 'Heavy';
      case 2:
        return 'Unsettled';
      case 3:
        return 'Steady';
      case 4:
        return 'Grounded';
      case 5:
        return 'Radiant';
      default:
        return 'Steady';
    }
  }

  static String getEnergyLabel(int score) {
    switch (score) {
      case 1:
        return 'Depleted';
      case 2:
        return 'Low';
      case 3:
        return 'Gentle';
      case 4:
        return 'Active';
      case 5:
        return 'Vibrant';
      default:
        return 'Gentle';
    }
  }

  String get moodLabel => getMoodLabel(moodScore);
  String get energyLabel => getEnergyLabel(energyScore);

  MoodEnergyCheckIn copyWith({
    String? id,
    String? dateKey,
    DateTime? createdAt,
    int? moodScore,
    int? energyScore,
    List<String>? tags,
    String? note,
  }) {
    return MoodEnergyCheckIn(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      createdAt: createdAt ?? this.createdAt,
      moodScore: moodScore ?? this.moodScore,
      energyScore: energyScore ?? this.energyScore,
      tags: tags ?? this.tags,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date_key': dateKey,
        'created_at': createdAt.toIso8601String(),
        'mood_score': moodScore,
        'energy_score': energyScore,
        'tags': tags,
        'note': note,
      };

  factory MoodEnergyCheckIn.fromJson(Map<String, dynamic> json) {
    return MoodEnergyCheckIn(
      id: json['id'] as String,
      dateKey: json['date_key'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      moodScore: (json['mood_score'] as num?)?.toInt() ?? 3,
      energyScore: (json['energy_score'] as num?)?.toInt() ?? 3,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      note: json['note'] as String? ?? '',
    );
  }
}
