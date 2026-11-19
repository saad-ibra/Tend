import 'package:flutter_test/flutter_test.dart';
import 'package:tend/controllers/habit_controller.dart';
import 'package:tend/models/habit.dart';
import 'package:tend/models/habit_completion.dart';
import 'package:tend/repositories/habit_repository.dart';

class InMemoryHabitRepository implements HabitRepository {
  final List<Habit> _habits = [];
  final List<HabitCompletion> _completions = [];

  @override
  Future<List<Habit>> getHabits({bool includeArchived = false}) async {
    return includeArchived
        ? List.unmodifiable(_habits)
        : _habits.where((h) => !h.isArchived).toList();
  }

  @override
  Future<Habit?> getHabitById(String id) async {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    final idx = _habits.indexWhere((h) => h.id == habit.id);
    if (idx >= 0) {
      _habits[idx] = habit;
    } else {
      _habits.add(habit);
    }
  }

  @override
  Future<void> archiveHabit(String id) async {
    final habit = await getHabitById(id);
    if (habit != null) {
      await saveHabit(habit.copyWith(isArchived: true, archivedAt: DateTime.now()));
    }
  }

  @override
  Future<void> unarchiveHabit(String id) async {
    final habit = await getHabitById(id);
    if (habit != null) {
      await saveHabit(habit.copyWith(isArchived: false, archivedAt: null));
    }
  }

  @override
  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    _completions.removeWhere((c) => c.habitId == id);
  }

  @override
  Future<List<HabitCompletion>> getCompletions() async {
    return List.unmodifiable(_completions);
  }

  @override
  Future<List<HabitCompletion>> getCompletionsForHabit(String habitId) async {
    return _completions.where((c) => c.habitId == habitId).toList();
  }

  @override
  Future<void> markComplete(String habitId, DateTime date) async {
    final dateKey = HabitCompletion.formatDateKey(date);
    if (!_completions.any((c) => c.habitId == habitId && c.dateKey == dateKey)) {
      _completions.add(HabitCompletion(
        id: '${habitId}_$dateKey',
        habitId: habitId,
        dateKey: dateKey,
        completedAt: DateTime.now(),
      ));
    }
  }

  @override
  Future<void> undoCompletion(String habitId, DateTime date) async {
    final dateKey = HabitCompletion.formatDateKey(date);
    _completions.removeWhere((c) => c.habitId == habitId && c.dateKey == dateKey);
  }

  @override
  Future<bool> isCompletedOnDate(String habitId, DateTime date) async {
    final dateKey = HabitCompletion.formatDateKey(date);
    return _completions.any((c) => c.habitId == habitId && c.dateKey == dateKey);
  }
}

void main() {
  group('Habit Model Tests', () {
    test('JSON serialization & deserialization', () {
      final now = DateTime(2026, 11, 19, 12, 0);
      final habit = Habit(
        id: 'h1',
        title: 'Morning stillness',
        description: '10 min breathing',
        frequencyType: HabitFrequencyType.weekdays,
        targetWeekdays: const [1, 2, 3, 4, 5],
        colorHex: '#744127',
        isArchived: false,
        createdAt: now,
      );

      final json = habit.toJson();
      final reconstructed = Habit.fromJson(json);

      expect(reconstructed.id, 'h1');
      expect(reconstructed.title, 'Morning stillness');
      expect(reconstructed.frequencyType, HabitFrequencyType.weekdays);
      expect(reconstructed.targetWeekdays, [1, 2, 3, 4, 5]);
      expect(reconstructed.frequencyLabel, 'Weekdays (Mon–Fri)');
    });

    test('isScheduledFor correctly evaluates weekdays', () {
      final now = DateTime(2026, 11, 19); // Thursday (weekday = 4)
      final weekendDate = DateTime(2026, 11, 22); // Sunday (weekday = 7)

      final weekdayHabit = Habit(
        id: 'h2',
        title: 'Work block',
        frequencyType: HabitFrequencyType.weekdays,
        targetWeekdays: const [1, 2, 3, 4, 5],
        createdAt: DateTime.now(),
      );

      expect(weekdayHabit.isScheduledFor(now), isTrue);
      expect(weekdayHabit.isScheduledFor(weekendDate), isFalse);
    });
  });

  group('HabitController Business Logic Tests', () {
    late InMemoryHabitRepository repo;
    late HabitController controller;

    setUp(() {
      repo = InMemoryHabitRepository();
      controller = HabitController(repository: repo);
    });

    test('Creating and loading a habit', () async {
      final success = await controller.createHabit(
        title: 'Read philosophy',
        description: '20 pages',
        frequencyType: HabitFrequencyType.daily,
      );

      expect(success, isTrue);
      expect(controller.activeHabits.length, 1);
      expect(controller.activeHabits.first.title, 'Read philosophy');
    });

    test('Validation prevents empty title', () async {
      final success = await controller.createHabit(
        title: '   ',
        frequencyType: HabitFrequencyType.daily,
      );

      expect(success, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(controller.activeHabits, isEmpty);
    });

    test('Toggle completion marks and unmarks habit', () async {
      await controller.createHabit(
        title: 'Hydrate',
        frequencyType: HabitFrequencyType.daily,
      );
      final habitId = controller.activeHabits.first.id;
      final today = DateTime.now();

      expect(controller.isHabitCompleted(habitId, today), isFalse);
      expect(controller.todayCompletedCount, 0);

      // Mark complete
      await controller.toggleCompletion(habitId, today);
      expect(controller.isHabitCompleted(habitId, today), isTrue);
      expect(controller.todayCompletedCount, 1);
      expect(controller.todayProgressRatio, 1.0);

      // Undo completion
      await controller.toggleCompletion(habitId, today);
      expect(controller.isHabitCompleted(habitId, today), isFalse);
      expect(controller.todayCompletedCount, 0);
      expect(controller.todayProgressRatio, 0.0);
    });

    test('Streak calculation counts consecutive days', () async {
      await controller.createHabit(
        title: 'Stretch',
        frequencyType: HabitFrequencyType.daily,
      );
      final habitId = controller.activeHabits.first.id;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final dayBefore = today.subtract(const Duration(days: 2));

      // Mark today, yesterday, day before
      await controller.toggleCompletion(habitId, dayBefore);
      await controller.toggleCompletion(habitId, yesterday);
      await controller.toggleCompletion(habitId, today);

      final streak = controller.getStreakForHabit(habitId);
      expect(streak, 3);
    });

    test('Archiving moves habit from active to archived list', () async {
      await controller.createHabit(
        title: 'Cold shower',
        frequencyType: HabitFrequencyType.daily,
      );
      final habitId = controller.activeHabits.first.id;

      expect(controller.activeHabits.length, 1);
      expect(controller.archivedHabits.length, 0);

      await controller.archiveHabit(habitId);
      expect(controller.activeHabits.length, 0);
      expect(controller.archivedHabits.length, 1);

      await controller.unarchiveHabit(habitId);
      expect(controller.activeHabits.length, 1);
      expect(controller.archivedHabits.length, 0);
    });

    test('Weekly progress overview returns 7 days', () {
      final weekly = controller.getWeeklyProgress();
      expect(weekly.length, 7);
      expect(weekly.map((d) => d.dayLabel).toList(), ['M', 'T', 'W', 'T', 'F', 'S', 'S']);
    });
  });
}
