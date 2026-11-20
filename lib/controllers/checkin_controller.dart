import 'package:flutter/foundation.dart';
import '../models/mood_energy_checkin.dart';
import '../repositories/checkin_repository.dart';

class CheckInController extends ChangeNotifier {
  final CheckInRepository repository;

  List<MoodEnergyCheckIn> _checkIns = [];
  bool _isLoading = false;
  String? _errorMessage;

  CheckInController({required this.repository});

  List<MoodEnergyCheckIn> get checkIns => List.unmodifiable(_checkIns);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get todayDateKey => _formatDateKey(DateTime.now());

  MoodEnergyCheckIn? get todayCheckIn {
    try {
      return _checkIns.firstWhere((c) => c.dateKey == todayDateKey);
    } catch (_) {
      return null;
    }
  }

  MoodEnergyCheckIn? getCheckInForDate(DateTime dt) {
    final key = _formatDateKey(dt);
    try {
      return _checkIns.firstWhere((c) => c.dateKey == key);
    } catch (_) {
      return null;
    }
  }

  bool get hasCheckedInToday => todayCheckIn != null;

  int get totalCheckInsCount => _checkIns.length;

  double get averageMood {
    if (_checkIns.isEmpty) return 0.0;
    final sum = _checkIns.fold(0, (acc, c) => acc + c.moodScore);
    return double.parse((sum / _checkIns.length).toStringAsFixed(1));
  }

  double get averageEnergy {
    if (_checkIns.isEmpty) return 0.0;
    final sum = _checkIns.fold(0, (acc, c) => acc + c.energyScore);
    return double.parse((sum / _checkIns.length).toStringAsFixed(1));
  }

  /// Calculates consecutive daily check-in streak ending today or yesterday
  int get checkInStreak {
    if (_checkIns.isEmpty) return 0;

    final existingDateKeys = _checkIns.map((c) => c.dateKey).toSet();
    final today = DateTime.now();
    DateTime current = DateTime(today.year, today.month, today.day);

    // If today is not logged, start checking from yesterday
    if (!existingDateKeys.contains(_formatDateKey(current))) {
      current = current.subtract(const Duration(days: 1));
      if (!existingDateKeys.contains(_formatDateKey(current))) {
        return 0;
      }
    }

    int streak = 0;
    while (existingDateKeys.contains(_formatDateKey(current))) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Returns check-ins for the last 7 calendar days
  List<MoodEnergyCheckIn?> getPastSevenDays() {
    final today = DateTime.now();
    final List<MoodEnergyCheckIn?> result = [];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final key = _formatDateKey(day);
      try {
        final match = _checkIns.firstWhere((c) => c.dateKey == key);
        result.add(match);
      } catch (_) {
        result.add(null);
      }
    }

    return result;
  }

  Future<void> loadCheckIns() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _checkIns = await repository.getCheckIns();
    } catch (e) {
      _errorMessage = 'Failed to load check-ins: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MoodEnergyCheckIn> logCheckIn({
    required int moodScore,
    required int energyScore,
    List<String> tags = const [],
    String note = '',
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final dateKey = _formatDateKey(now);

    final existing = await repository.getCheckInForDate(dateKey);

    final checkIn = MoodEnergyCheckIn(
      id: existing?.id ?? 'ci_${now.millisecondsSinceEpoch}',
      dateKey: dateKey,
      createdAt: now,
      moodScore: moodScore.clamp(1, 5),
      energyScore: energyScore.clamp(1, 5),
      tags: tags,
      note: note.trim(),
    );

    await repository.saveCheckIn(checkIn);
    _checkIns = await repository.getCheckIns();
    notifyListeners();
    return checkIn;
  }

  Future<void> deleteCheckIn(String id) async {
    try {
      await repository.deleteCheckIn(id);
      _checkIns = await repository.getCheckIns();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete check-in: $e';
      notifyListeners();
    }
  }

  static String _formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
