import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tend/controllers/checkin_controller.dart';
import 'package:tend/controllers/habit_controller.dart';
import 'package:tend/models/habit.dart';
import 'package:tend/models/mood_energy_checkin.dart';
import 'package:tend/repositories/checkin_repository.dart';
import 'habit_tracker_test.dart';

class InMemoryCheckInRepo implements CheckInRepository {
  final List<MoodEnergyCheckIn> _list = [];

  @override
  Future<List<MoodEnergyCheckIn>> getCheckIns() async => List.unmodifiable(_list);

  @override
  Future<MoodEnergyCheckIn?> getCheckInForDate(String dateKey) async {
    try {
      return _list.firstWhere((c) => c.dateKey == dateKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCheckIn(MoodEnergyCheckIn checkIn) async {
    _list.removeWhere((c) => c.dateKey == checkIn.dateKey);
    _list.add(checkIn);
  }

  @override
  Future<void> deleteCheckIn(String id) async {
    _list.removeWhere((c) => c.id == id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Days & Mindful Ledger Tests', () {
    late InMemoryHabitRepository habitRepo;
    late HabitController habitCtrl;
    late InMemoryCheckInRepo checkInRepo;
    late CheckInController checkInCtrl;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      habitRepo = InMemoryHabitRepository();
      habitCtrl = HabitController(repository: habitRepo);
      checkInRepo = InMemoryCheckInRepo();
      checkInCtrl = CheckInController(repository: checkInRepo);

      final now = DateTime.now();
      await habitRepo.saveHabit(Habit(
        id: 'h1',
        title: 'Morning Stillness',
        description: 'Breathing',
        createdAt: now,
      ));
      await habitCtrl.load();

      // Mark habit completed today
      await habitCtrl.toggleCompletion('h1', now);

      // Save check-in today
      await checkInCtrl.logCheckIn(
        moodScore: 4,
        energyScore: 5,
        tags: ['focused', 'grounded'],
        note: 'Felt serene after morning walk.',
      );
    });

    test('Correlates completed habits and check-in for target day', () {
      final today = DateTime.now();
      final completed = habitCtrl.getCompletedHabitsForDate(today);
      final checkIn = checkInCtrl.getCheckInForDate(today);

      expect(completed.length, equals(1));
      expect(completed.first.title, equals('Morning Stillness'));

      expect(checkIn, isNotNull);
      expect(checkIn!.moodLabel, equals('Grounded'));
      expect(checkIn.energyLabel, equals('Vibrant'));
      expect(checkIn.tags, contains('focused'));
      expect(checkIn.note, equals('Felt serene after morning walk.'));
    });
  });
}
