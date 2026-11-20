import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tend/controllers/network_controller.dart';
import 'package:tend/models/circle_member.dart';
import 'package:tend/models/rhythm_circle.dart';
import 'package:tend/repositories/network_repository.dart';

class InMemoryNetworkRepository implements NetworkRepository {
  final List<RhythmCircle> _circles = [];

  InMemoryNetworkRepository({List<RhythmCircle>? initialCircles}) {
    if (initialCircles != null) {
      _circles.addAll(initialCircles);
    }
  }

  @override
  Future<List<RhythmCircle>> getCircles({String? category}) async {
    if (category == null || category.isEmpty || category == 'All') {
      return List.unmodifiable(_circles);
    }
    if (category == 'My Circles') {
      return _circles.where((c) => c.isJoined).toList();
    }
    return _circles
        .where((c) => c.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  @override
  Future<void> joinCircle(String circleId) async {
    final idx = _circles.indexWhere((c) => c.id == circleId);
    if (idx != -1) {
      _circles[idx] = _circles[idx].copyWith(
        isJoined: true,
        memberCount: _circles[idx].memberCount + 1,
      );
    }
  }

  @override
  Future<void> leaveCircle(String circleId) async {
    final idx = _circles.indexWhere((c) => c.id == circleId);
    if (idx != -1) {
      _circles[idx] = _circles[idx].copyWith(
        isJoined: false,
        memberCount: _circles[idx].memberCount > 1 ? _circles[idx].memberCount - 1 : 1,
      );
    }
  }

  @override
  Future<void> createCircle(RhythmCircle circle) async {
    _circles.insert(0, circle);
  }

  @override
  Future<bool> sendStillnessNudge({
    required String circleId,
    required String targetName,
  }) async {
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RhythmCircle Model Tests', () {
    test('JSON serialization & deserialization', () {
      final circle = RhythmCircle(
        id: 'c1',
        name: 'Dawn Walkers',
        philosophy: 'First light without screens.',
        category: 'Morning',
        rhythmFocus: '20m walk',
        memberCount: 8,
        weeklyConsistencyPercent: 88,
        isJoined: true,
        createdAt: DateTime(2026, 11, 1),
        members: [
          CircleMember(
            id: 'm1',
            name: 'Julian',
            avatarInitial: 'J',
            currentRhythm: 'Sunrise walk',
            tendedToday: true,
            streakDays: 7,
          )
        ],
      );

      final json = circle.toJson();
      final restored = RhythmCircle.fromJson(json);

      expect(restored.id, equals('c1'));
      expect(restored.name, equals('Dawn Walkers'));
      expect(restored.isJoined, isTrue);
      expect(restored.members.first.name, equals('Julian'));
    });
  });

  group('NetworkController Tests', () {
    late InMemoryNetworkRepository repo;
    late NetworkController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = InMemoryNetworkRepository(initialCircles: [
        RhythmCircle(
          id: 'c1',
          name: 'Dawn Walkers',
          philosophy: 'Morning light.',
          category: 'Morning',
          rhythmFocus: '20m walk',
          memberCount: 5,
          weeklyConsistencyPercent: 90,
          isJoined: false,
          createdAt: DateTime.now(),
          members: [
            CircleMember(
              id: 'm1',
              name: 'Elena',
              avatarInitial: 'E',
              currentRhythm: 'Walk',
              tendedToday: true,
              streakDays: 4,
            ),
          ],
        ),
      ]);
      controller = NetworkController(repository: repo);
    });

    test('Loads circles and calculates active practicing peers', () async {
      await controller.loadCircles();
      expect(controller.circles.length, equals(1));
      expect(controller.totalPracticingPeers, equals(1));
      expect(controller.joinedCirclesCount, equals(0));
    });

    test('Toggles joining and leaving circle', () async {
      await controller.loadCircles();
      await controller.toggleJoin('c1');

      expect(controller.joinedCirclesCount, equals(1));
      expect(controller.circles.first.isJoined, isTrue);
      expect(controller.circles.first.memberCount, equals(6));

      await controller.toggleJoin('c1');
      expect(controller.joinedCirclesCount, equals(0));
      expect(controller.circles.first.isJoined, isFalse);
    });

    test('Creates a new circle', () async {
      await controller.loadCircles();
      await controller.createCircle(
        name: 'Deep Work Sanctuary',
        philosophy: 'Protected focus.',
        category: 'Focus',
        rhythmFocus: '90m focus block',
      );

      expect(controller.circles.length, equals(2));
      expect(controller.circles.first.name, equals('Deep Work Sanctuary'));
      expect(controller.circles.first.isJoined, isTrue);
    });

    test('Sends stillness nudge successfully', () async {
      final success = await controller.sendStillnessNudge(
        circleId: 'c1',
        targetName: 'Dawn Walkers',
      );
      expect(success, isTrue);
    });
  });
}
