import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/circle_member.dart';
import '../models/rhythm_circle.dart';
import 'network_repository.dart';

class LocalNetworkRepository implements NetworkRepository {
  static const _storageKey = 'tend_circles_v1';
  bool _initialized = false;
  final List<RhythmCircle> _circles = [];

  final List<RhythmCircle> _seedCircles = [
    RhythmCircle(
      id: 'circle_dawn_walkers',
      name: 'Dawn Walkers',
      philosophy: 'Greeting first light without screens, pacing our breath with the waking earth.',
      category: 'Morning',
      rhythmFocus: '20m Morning walk / light exposure',
      memberCount: 9,
      weeklyConsistencyPercent: 88,
      isJoined: true,
      createdAt: DateTime(2026, 10, 1),
      members: [
        CircleMember(
          id: 'm1',
          name: 'Elena',
          avatarInitial: 'E',
          currentRhythm: 'Morning walk',
          tendedToday: true,
          streakDays: 6,
        ),
        CircleMember(
          id: 'm2',
          name: 'Julian',
          avatarInitial: 'J',
          currentRhythm: 'Sunrise breathing',
          tendedToday: true,
          streakDays: 14,
        ),
        CircleMember(
          id: 'm3',
          name: 'Soren',
          avatarInitial: 'S',
          currentRhythm: '15m Park stroll',
          tendedToday: false,
          streakDays: 4,
        ),
        CircleMember(
          id: 'm4',
          name: 'Aria',
          avatarInitial: 'A',
          currentRhythm: 'Morning sunlight',
          tendedToday: true,
          streakDays: 9,
        ),
      ],
    ),
    RhythmCircle(
      id: 'circle_deep_work',
      name: 'Deep Work Sanctuary',
      philosophy: 'Protecting quiet uninterrupted cognitive blocks against reactive fragmentation.',
      category: 'Focus',
      rhythmFocus: '90m Single-task focus block',
      memberCount: 14,
      weeklyConsistencyPercent: 84,
      isJoined: true,
      createdAt: DateTime(2026, 10, 10),
      members: [
        CircleMember(
          id: 'm5',
          name: 'Mateo',
          avatarInitial: 'M',
          currentRhythm: 'Prose drafting',
          tendedToday: true,
          streakDays: 11,
        ),
        CircleMember(
          id: 'm6',
          name: 'Kiran',
          avatarInitial: 'K',
          currentRhythm: 'Architecture modeling',
          tendedToday: false,
          streakDays: 3,
        ),
        CircleMember(
          id: 'm7',
          name: 'Hana',
          avatarInitial: 'H',
          currentRhythm: 'Code focus block',
          tendedToday: true,
          streakDays: 7,
        ),
      ],
    ),
    RhythmCircle(
      id: 'circle_evening_unwind',
      name: 'Evening Hearth',
      philosophy: 'Dimming artificial luminescence, brewing herbal infusions, and reclaiming quiet rest.',
      category: 'Rest',
      rhythmFocus: 'Screen-free 60m before sleep',
      memberCount: 16,
      weeklyConsistencyPercent: 79,
      isJoined: false,
      createdAt: DateTime(2026, 10, 18),
      members: [
        CircleMember(
          id: 'm8',
          name: 'Lin',
          avatarInitial: 'L',
          currentRhythm: 'Evening book reading',
          tendedToday: true,
          streakDays: 5,
        ),
        CircleMember(
          id: 'm9',
          name: 'Freja',
          avatarInitial: 'F',
          currentRhythm: 'Herbal tea ritual',
          tendedToday: false,
          streakDays: 8,
        ),
      ],
    ),
    RhythmCircle(
      id: 'circle_mindful_writers',
      name: 'Morning Pages Guild',
      philosophy: 'Unfiltered longhand journal entries before opening email or social demands.',
      category: 'Creative',
      rhythmFocus: '3 pages stream-of-consciousness writing',
      memberCount: 7,
      weeklyConsistencyPercent: 92,
      isJoined: false,
      createdAt: DateTime(2026, 11, 01),
      members: [
        CircleMember(
          id: 'm10',
          name: 'Cassian',
          avatarInitial: 'C',
          currentRhythm: 'Longhand journal',
          tendedToday: true,
          streakDays: 19,
        ),
        CircleMember(
          id: 'm11',
          name: 'Mei',
          avatarInitial: 'M',
          currentRhythm: 'Daily morning pages',
          tendedToday: true,
          streakDays: 12,
        ),
      ],
    ),
    RhythmCircle(
      id: 'circle_gentle_movement',
      name: 'Somatic Stillness',
      philosophy: 'Gentle spinal mobility, hip openers, and ground-based restorative stretching.',
      category: 'Movement',
      rhythmFocus: '15m Restorative somatic flow',
      memberCount: 11,
      weeklyConsistencyPercent: 81,
      isJoined: false,
      createdAt: DateTime(2026, 11, 04),
      members: [
        CircleMember(
          id: 'm12',
          name: 'Noah',
          avatarInitial: 'N',
          currentRhythm: 'Gentle spinal waves',
          tendedToday: true,
          streakDays: 4,
        ),
      ],
    ),
  ];

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _circles.clear();
        for (final item in list) {
          _circles.add(RhythmCircle.fromJson(item as Map<String, dynamic>));
        }
      } catch (_) {
        _circles.clear();
        _circles.addAll(_seedCircles);
      }
    } else {
      _circles.clear();
      _circles.addAll(_seedCircles);
      await _persist();
    }
    _initialized = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _circles.map((c) => c.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  @override
  Future<List<RhythmCircle>> getCircles({String? category}) async {
    await _ensureInitialized();
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
    await _ensureInitialized();
    final index = _circles.indexWhere((c) => c.id == circleId);
    if (index != -1) {
      final current = _circles[index];
      _circles[index] = current.copyWith(
        isJoined: true,
        memberCount: current.memberCount + 1,
      );
      await _persist();
    }
  }

  @override
  Future<void> leaveCircle(String circleId) async {
    await _ensureInitialized();
    final index = _circles.indexWhere((c) => c.id == circleId);
    if (index != -1) {
      final current = _circles[index];
      _circles[index] = current.copyWith(
        isJoined: false,
        memberCount: current.memberCount > 1 ? current.memberCount - 1 : 1,
      );
      await _persist();
    }
  }

  @override
  Future<void> createCircle(RhythmCircle circle) async {
    await _ensureInitialized();
    _circles.insert(0, circle);
    await _persist();
  }

  @override
  Future<bool> sendStillnessNudge({
    required String circleId,
    required String targetName,
  }) async {
    await _ensureInitialized();
    // Simulate non-invasive stillness nod acknowledgement
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
