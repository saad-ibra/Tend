import 'package:flutter_test/flutter_test.dart';
import 'package:tend/controllers/checkin_controller.dart';
import 'package:tend/models/mood_energy_checkin.dart';
import 'package:tend/repositories/checkin_repository.dart';

class InMemoryCheckInRepository implements CheckInRepository {
  final Map<String, MoodEnergyCheckIn> _store = {};

  @override
  Future<List<MoodEnergyCheckIn>> getCheckIns() async {
    final list = _store.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<MoodEnergyCheckIn?> getCheckInForDate(String dateKey) async {
    try {
      return _store.values.firstWhere((c) => c.dateKey == dateKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCheckIn(MoodEnergyCheckIn checkIn) async {
    // If a check-in with the same dateKey exists, overwrite it
    final existingKey = _store.keys.cast<String?>().firstWhere(
          (k) => _store[k]!.dateKey == checkIn.dateKey || _store[k]!.id == checkIn.id,
          orElse: () => null,
        );
    if (existingKey != null) {
      _store[existingKey] = checkIn;
    } else {
      _store[checkIn.id] = checkIn;
    }
  }

  @override
  Future<void> deleteCheckIn(String id) async {
    _store.remove(id);
  }
}

void main() {
  group('MoodEnergyCheckIn Model Tests', () {
    test('JSON serialization & deserialization roundtrip', () {
      final now = DateTime.now();
      final checkIn = MoodEnergyCheckIn(
        id: 'ci_test_1',
        dateKey: '2026-11-20',
        createdAt: now,
        moodScore: 4,
        energyScore: 3,
        tags: const ['Stillness', 'Nature'],
        note: 'Grounded and mindful morning walk.',
      );

      final json = checkIn.toJson();
      final restored = MoodEnergyCheckIn.fromJson(json);

      expect(restored.id, checkIn.id);
      expect(restored.dateKey, '2026-11-20');
      expect(restored.moodScore, 4);
      expect(restored.moodLabel, 'Grounded');
      expect(restored.energyScore, 3);
      expect(restored.energyLabel, 'Gentle');
      expect(restored.tags, ['Stillness', 'Nature']);
      expect(restored.note, 'Grounded and mindful morning walk.');
    });

    test('Label mappings match wabi-sabi scales accurately', () {
      expect(MoodEnergyCheckIn.getMoodLabel(1), 'Heavy');
      expect(MoodEnergyCheckIn.getMoodLabel(2), 'Unsettled');
      expect(MoodEnergyCheckIn.getMoodLabel(3), 'Steady');
      expect(MoodEnergyCheckIn.getMoodLabel(4), 'Grounded');
      expect(MoodEnergyCheckIn.getMoodLabel(5), 'Radiant');

      expect(MoodEnergyCheckIn.getEnergyLabel(1), 'Depleted');
      expect(MoodEnergyCheckIn.getEnergyLabel(2), 'Low');
      expect(MoodEnergyCheckIn.getEnergyLabel(3), 'Gentle');
      expect(MoodEnergyCheckIn.getEnergyLabel(4), 'Active');
      expect(MoodEnergyCheckIn.getEnergyLabel(5), 'Vibrant');
    });
  });

  group('CheckInController Business Logic Tests', () {
    late InMemoryCheckInRepository repo;
    late CheckInController controller;

    setUp(() {
      repo = InMemoryCheckInRepository();
      controller = CheckInController(repository: repo);
    });

    test('Logs daily check-in and updates todayCheckIn', () async {
      await controller.loadCheckIns();
      expect(controller.hasCheckedInToday, false);
      expect(controller.todayCheckIn, isNull);

      final result = await controller.logCheckIn(
        moodScore: 4,
        energyScore: 5,
        tags: ['Deep Work', 'Sleep'],
        note: 'Focused sprint session.',
      );

      expect(result.moodScore, 4);
      expect(result.energyScore, 5);
      expect(controller.hasCheckedInToday, true);
      expect(controller.todayCheckIn?.moodLabel, 'Grounded');
      expect(controller.todayCheckIn?.energyLabel, 'Vibrant');
      expect(controller.totalCheckInsCount, 1);
    });

    test('Overwrites check-in on the same date rather than creating duplicate', () async {
      await controller.logCheckIn(moodScore: 2, energyScore: 2);
      expect(controller.totalCheckInsCount, 1);
      expect(controller.todayCheckIn?.moodScore, 2);

      // Log again on the same day with updated feelings
      await controller.logCheckIn(moodScore: 5, energyScore: 4, note: 'Evening tea lifted mood.');
      expect(controller.totalCheckInsCount, 1);
      expect(controller.todayCheckIn?.moodScore, 5);
      expect(controller.todayCheckIn?.note, 'Evening tea lifted mood.');
    });

    test('Calculates streak across consecutive calendar days', () async {
      final now = DateTime.now();

      // Today
      await controller.logCheckIn(moodScore: 4, energyScore: 4, timestamp: now);

      // Yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      await controller.logCheckIn(moodScore: 3, energyScore: 3, timestamp: yesterday);

      // 2 days ago
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      await controller.logCheckIn(moodScore: 4, energyScore: 4, timestamp: twoDaysAgo);

      expect(controller.checkInStreak, 3);
    });

    test('Calculates average mood and energy statistics', () async {
      final now = DateTime.now();

      await controller.logCheckIn(
        moodScore: 4,
        energyScore: 2,
        timestamp: now,
      );

      await controller.logCheckIn(
        moodScore: 2,
        energyScore: 4,
        timestamp: now.subtract(const Duration(days: 1)),
      );

      expect(controller.averageMood, 3.0);
      expect(controller.averageEnergy, 3.0);
    });

    test('Deletes check-in correctly', () async {
      final item = await controller.logCheckIn(moodScore: 4, energyScore: 4);
      expect(controller.totalCheckInsCount, 1);

      await controller.deleteCheckIn(item.id);
      expect(controller.totalCheckInsCount, 0);
      expect(controller.hasCheckedInToday, false);
    });

    test('getPastSevenDays returns exactly 7 items with day continuity', () async {
      final pastSeven = controller.getPastSevenDays();
      expect(pastSeven.length, 7);
    });
  });
}
