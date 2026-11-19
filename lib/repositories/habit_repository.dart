import '../models/habit.dart';
import '../models/habit_completion.dart';

abstract class HabitRepository {
  /// Retrieves habits. If [includeArchived] is true, returns both active and archived.
  Future<List<Habit>> getHabits({bool includeArchived = false});

  /// Retrieves a specific habit by its ID.
  Future<Habit?> getHabitById(String id);

  /// Saves or updates a habit.
  Future<void> saveHabit(Habit habit);

  /// Archives a habit.
  Future<void> archiveHabit(String id);

  /// Restores an archived habit.
  Future<void> unarchiveHabit(String id);

  /// Permanently removes a habit and its completions.
  Future<void> deleteHabit(String id);

  /// Retrieves all completion records.
  Future<List<HabitCompletion>> getCompletions();

  /// Retrieves all completion records for a specific habit.
  Future<List<HabitCompletion>> getCompletionsForHabit(String habitId);

  /// Marks a habit as complete on a given date.
  Future<void> markComplete(String habitId, DateTime date);

  /// Undoes completion for a habit on a given date.
  Future<void> undoCompletion(String habitId, DateTime date);

  /// Checks if a habit was completed on a specific date.
  Future<bool> isCompletedOnDate(String habitId, DateTime date);
}
