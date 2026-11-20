import 'package:flutter/foundation.dart';
import '../models/circle_member.dart';
import '../models/rhythm_circle.dart';
import '../repositories/network_repository.dart';

class NetworkController extends ChangeNotifier {
  final NetworkRepository repository;

  List<RhythmCircle> _circles = [];
  bool _isLoading = false;
  String _selectedFilter = 'All';

  NetworkController({required this.repository});

  List<RhythmCircle> get circles => _circles;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;

  int get joinedCirclesCount => _circles.where((c) => c.isJoined).length;

  int get totalPracticingPeers {
    return _circles.fold<int>(0, (acc, circle) {
      final activeInCircle = circle.members.where((m) => m.tendedToday).length;
      return acc + activeInCircle;
    });
  }

  Future<void> loadCircles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetched = await repository.getCircles(
        category: _selectedFilter == 'All' ? null : _selectedFilter,
      );
      _circles = List<RhythmCircle>.from(fetched);
    } catch (e) {
      debugPrint('Error loading rhythm circles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setFilter(String filter) async {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    await loadCircles();
  }

  Future<void> toggleJoin(String circleId) async {
    final index = _circles.indexWhere((c) => c.id == circleId);
    if (index == -1) return;

    final circle = _circles[index];
    final newJoined = !circle.isJoined;

    // Optimistic UI update
    _circles[index] = circle.copyWith(
      isJoined: newJoined,
      memberCount: newJoined ? circle.memberCount + 1 : (circle.memberCount > 1 ? circle.memberCount - 1 : 1),
    );
    notifyListeners();

    try {
      if (newJoined) {
        await repository.joinCircle(circleId);
      } else {
        await repository.leaveCircle(circleId);
      }
    } catch (e) {
      debugPrint('Error toggling circle join: $e');
      // Rollback
      _circles[index] = circle;
      notifyListeners();
    }
  }

  Future<void> createCircle({
    required String name,
    required String philosophy,
    required String category,
    required String rhythmFocus,
  }) async {
    final now = DateTime.now();
    final newCircle = RhythmCircle(
      id: 'circle_${now.millisecondsSinceEpoch}',
      name: name,
      philosophy: philosophy,
      category: category,
      rhythmFocus: rhythmFocus,
      memberCount: 1,
      weeklyConsistencyPercent: 100,
      isJoined: true,
      members: [
        CircleMember(
          id: 'me',
          name: 'Elena (You)',
          avatarInitial: 'E',
          currentRhythm: rhythmFocus,
          tendedToday: true,
          streakDays: 1,
        ),
      ],
      createdAt: now,
    );

    await repository.createCircle(newCircle);
    await loadCircles();
  }

  Future<bool> sendStillnessNudge({
    required String circleId,
    required String targetName,
  }) async {
    try {
      return await repository.sendStillnessNudge(
        circleId: circleId,
        targetName: targetName,
      );
    } catch (e) {
      debugPrint('Error sending stillness nudge: $e');
      return false;
    }
  }
}
