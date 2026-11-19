import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../models/weekly_progress.dart';
import '../repositories/habit_repository.dart';

class HabitController extends ChangeNotifier {
  final HabitRepository repository;

  List<Habit> _habits = [];
  List<HabitCompletion> _completions = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  HabitController({required this.repository});

  HabitRepository get _repository => repository;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;

  List<Habit> get activeHabits =>
      _habits.where((h) => !h.isArchived).toList();

  List<Habit> get archivedHabits =>
      _habits.where((h) => h.isArchived).toList();

  List<Habit> get todayDueHabits =>
      activeHabits.where((h) => h.isScheduledFor(_selectedDate)).toList();

  int get todayCompletedCount {
    return todayDueHabits.where((h) => isHabitCompleted(h.id, _selectedDate)).length;
  }

  int get todayTotalCount => todayDueHabits.length;

  double get todayProgressRatio {
    if (todayTotalCount == 0) return 0.0;
    return (todayCompletedCount / todayTotalCount).clamp(0.0, 1.0);
  }

  bool isHabitCompleted(String habitId, [DateTime? date]) {
    final targetDate = date ?? _selectedDate;
    final dateKey = HabitCompletion.formatDateKey(targetDate);
    return _completions.any((c) => c.habitId == habitId && c.dateKey == dateKey);
  }

  /// Calculates the current unbroken streak of scheduled completions for [habitId].
  int getStreakForHabit(String habitId) {
    Habit? habit;
    try {
      habit = _habits.firstWhere((h) => h.id == habitId);
    } catch (_) {
      return 0;
    }

    final today = DateTime.now();
    final todayClean = DateTime(today.year, today.month, today.day);
    int streak = 0;

    DateTime checkDate = todayClean;
    final isScheduledToday = habit.isScheduledFor(checkDate);
    final isDoneToday = isHabitCompleted(habitId, checkDate);

    // If scheduled today and already completed, start count with today
    if (isScheduledToday && isDoneToday) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else if (isScheduledToday && !isDoneToday) {
      // If scheduled today but not yet done, streak is unbroken if yesterday was done
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      // Not scheduled today (e.g. weekend for a Mon-Fri habit), check back from yesterday
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Walk backward day by day
    for (int i = 0; i < 365; i++) {
      if (!habit.isScheduledFor(checkDate)) {
        // Skip non-scheduled days without breaking the streak
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      if (isHabitCompleted(habitId, checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // Uncompleted scheduled day found; streak ends here
        break;
      }
    }

    return streak;
  }

  /// Generates the Mon–Sun overview for the current week containing [selectedDate].
  List<DayProgress> getWeeklyProgress() {
    final now = DateTime.now();
    final todayClean = DateTime(now.year, now.month, now.day);
    final current = _selectedDate;
    // DateTime.weekday: 1 = Monday, 7 = Sunday
    final mondayOffset = current.weekday - 1;
    final monday = DateTime(current.year, current.month, current.day)
        .subtract(Duration(days: mondayOffset));

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final List<DayProgress> list = [];

    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dateKey = HabitCompletion.formatDateKey(day);
      final scheduledHabits = activeHabits.where((h) => h.isScheduledFor(day)).toList();
      final totalDue = scheduledHabits.length;

      final completed = scheduledHabits.where((h) {
        return _completions.any((c) => c.habitId == h.id && c.dateKey == dateKey);
      }).length;

      final isToday = day.year == todayClean.year &&
          day.month == todayClean.month &&
          day.day == todayClean.day;
      final isFuture = day.isAfter(todayClean);

      list.add(DayProgress(
        date: day,
        dateKey: dateKey,
        dayLabel: dayLabels[i],
        completedCount: completed,
        totalDueCount: totalDue,
        isToday: isToday,
        isFuture: isFuture,
      ));
    }

    return list;
  }

  // Operations
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _habits = await _repository.getHabits(includeArchived: true);
      _completions = await _repository.getCompletions();
    } catch (e) {
      _errorMessage = 'Failed to load habit records: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleCompletion(String habitId, [DateTime? date]) async {
    final targetDate = date ?? _selectedDate;
    final isDone = isHabitCompleted(habitId, targetDate);

    try {
      if (isDone) {
        await _repository.undoCompletion(habitId, targetDate);
      } else {
        await _repository.markComplete(habitId, targetDate);
      }
      _completions = await _repository.getCompletions();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update habit status: $e';
      notifyListeners();
    }
  }

  Future<bool> createHabit({
    required String title,
    String? description,
    required HabitFrequencyType frequencyType,
    List<int>? targetWeekdays,
    String? colorHex,
  }) async {
    if (title.trim().isEmpty) {
      _errorMessage = 'Habit title cannot be empty';
      notifyListeners();
      return false;
    }

    final newHabit = Habit(
      id: 'h_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description?.trim().isNotEmpty == true ? description!.trim() : null,
      frequencyType: frequencyType,
      targetWeekdays: targetWeekdays ?? const [1, 2, 3, 4, 5, 6, 7],
      colorHex: colorHex ?? '#744127',
      isArchived: false,
      createdAt: DateTime.now(),
    );

    try {
      await _repository.saveHabit(newHabit);
      _habits = await _repository.getHabits(includeArchived: true);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create habit: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateHabit(Habit habit) async {
    if (habit.title.trim().isEmpty) {
      _errorMessage = 'Habit title cannot be empty';
      notifyListeners();
      return false;
    }

    try {
      await _repository.saveHabit(habit);
      _habits = await _repository.getHabits(includeArchived: true);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update habit: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> archiveHabit(String habitId) async {
    try {
      await _repository.archiveHabit(habitId);
      _habits = await _repository.getHabits(includeArchived: true);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to archive habit: $e';
      notifyListeners();
    }
  }

  Future<void> unarchiveHabit(String habitId) async {
    try {
      await _repository.unarchiveHabit(habitId);
      _habits = await _repository.getHabits(includeArchived: true);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to restore habit: $e';
      notifyListeners();
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await _repository.deleteHabit(habitId);
      _habits = await _repository.getHabits(includeArchived: true);
      _completions = await _repository.getCompletions();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete habit: $e';
      notifyListeners();
    }
  }

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }
}
