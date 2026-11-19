import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';
import 'habit_repository.dart';

class LocalHabitRepository implements HabitRepository {
  static const String _habitsKey = 'tend_habits_v1';
  static const String _completionsKey = 'tend_completions_v1';

  final SharedPreferences? prefs;

  LocalHabitRepository({this.prefs});

  Future<SharedPreferences> _getPrefs() async {
    return prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<List<Habit>> getHabits({bool includeArchived = false}) async {
    final prefs = await _getPrefs();
    final rawList = prefs.getStringList(_habitsKey);

    if (rawList == null) {
      // Seed default starter habits on first run
      final initialHabits = _getInitialStarterHabits();
      await _saveAllHabits(initialHabits, prefs);
      return includeArchived
          ? initialHabits
          : initialHabits.where((h) => !h.isArchived).toList();
    }

    final habits = rawList
        .map((str) => Habit.fromJson(jsonDecode(str) as Map<String, dynamic>))
        .toList();

    return includeArchived
        ? habits
        : habits.where((h) => !h.isArchived).toList();
  }

  @override
  Future<Habit?> getHabitById(String id) async {
    final habits = await getHabits(includeArchived: true);
    try {
      return habits.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    final prefs = await _getPrefs();
    final habits = await getHabits(includeArchived: true);
    final index = habits.indexWhere((h) => h.id == habit.id);

    if (index >= 0) {
      habits[index] = habit;
    } else {
      habits.add(habit);
    }

    await _saveAllHabits(habits, prefs);
  }

  @override
  Future<void> archiveHabit(String id) async {
    final habit = await getHabitById(id);
    if (habit != null) {
      await saveHabit(habit.copyWith(
        isArchived: true,
        archivedAt: DateTime.now(),
      ));
    }
  }

  @override
  Future<void> unarchiveHabit(String id) async {
    final habit = await getHabitById(id);
    if (habit != null) {
      await saveHabit(habit.copyWith(
        isArchived: false,
        archivedAt: null,
      ));
    }
  }

  @override
  Future<void> deleteHabit(String id) async {
    final prefs = await _getPrefs();
    final habits = await getHabits(includeArchived: true);
    habits.removeWhere((h) => h.id == id);
    await _saveAllHabits(habits, prefs);

    // Also delete associated completions
    final completions = await getCompletions();
    completions.removeWhere((c) => c.habitId == id);
    await _saveAllCompletions(completions, prefs);
  }

  @override
  Future<List<HabitCompletion>> getCompletions() async {
    final prefs = await _getPrefs();
    final rawList = prefs.getStringList(_completionsKey) ?? [];
    return rawList
        .map((str) => HabitCompletion.fromJson(jsonDecode(str) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<HabitCompletion>> getCompletionsForHabit(String habitId) async {
    final all = await getCompletions();
    return all.where((c) => c.habitId == habitId).toList();
  }

  @override
  Future<void> markComplete(String habitId, DateTime date) async {
    final prefs = await _getPrefs();
    final completions = await getCompletions();
    final dateKey = HabitCompletion.formatDateKey(date);

    final alreadyExists = completions.any(
      (c) => c.habitId == habitId && c.dateKey == dateKey,
    );

    if (!alreadyExists) {
      completions.add(HabitCompletion(
        id: '${habitId}_$dateKey',
        habitId: habitId,
        dateKey: dateKey,
        completedAt: DateTime.now(),
      ));
      await _saveAllCompletions(completions, prefs);
    }
  }

  @override
  Future<void> undoCompletion(String habitId, DateTime date) async {
    final prefs = await _getPrefs();
    final completions = await getCompletions();
    final dateKey = HabitCompletion.formatDateKey(date);

    completions.removeWhere(
      (c) => c.habitId == habitId && c.dateKey == dateKey,
    );

    await _saveAllCompletions(completions, prefs);
  }

  @override
  Future<bool> isCompletedOnDate(String habitId, DateTime date) async {
    final completions = await getCompletions();
    final dateKey = HabitCompletion.formatDateKey(date);
    return completions.any((c) => c.habitId == habitId && c.dateKey == dateKey);
  }

  Future<void> _saveAllHabits(List<Habit> habits, SharedPreferences prefs) async {
    final encoded = habits.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList(_habitsKey, encoded);
  }

  Future<void> _saveAllCompletions(
      List<HabitCompletion> completions, SharedPreferences prefs) async {
    final encoded = completions.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_completionsKey, encoded);
  }

  List<Habit> _getInitialStarterHabits() {
    final now = DateTime.now();
    return [
      Habit(
        id: 'starter_1',
        title: 'Morning stillness',
        description: '10 minutes of quiet observation and breathing',
        frequencyType: HabitFrequencyType.daily,
        targetWeekdays: const [1, 2, 3, 4, 5, 6, 7],
        colorHex: '#55614E', // Sage
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Habit(
        id: 'starter_2',
        title: 'Hydrate & gentle stretch',
        description: 'Full glass of warm water & spine alignment',
        frequencyType: HabitFrequencyType.daily,
        targetWeekdays: const [1, 2, 3, 4, 5, 6, 7],
        colorHex: '#835136', // Warm Caramel
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Habit(
        id: 'starter_3',
        title: 'Deep focus block',
        description: '90 minutes uninterrupted craft with screen notifications muted',
        frequencyType: HabitFrequencyType.weekdays,
        targetWeekdays: const [1, 2, 3, 4, 5], // Mon-Fri
        colorHex: '#744127', // Espresso Caramel
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Habit(
        id: 'starter_4',
        title: 'Evening reflection journal',
        description: 'One honest observation or gratitude from the day',
        frequencyType: HabitFrequencyType.daily,
        targetWeekdays: const [1, 2, 3, 4, 5, 6, 7],
        colorHex: '#B97B54', // Caramel Mid
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }
}
