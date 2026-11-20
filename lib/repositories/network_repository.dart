import '../models/rhythm_circle.dart';

abstract class NetworkRepository {
  /// Fetches circles matching category or returns all if category is null/All.
  Future<List<RhythmCircle>> getCircles({String? category});

  /// Joins a rhythm circle by ID.
  Future<void> joinCircle(String circleId);

  /// Leaves a rhythm circle by ID.
  Future<void> leaveCircle(String circleId);

  /// Creates a new rhythm circle.
  Future<void> createCircle(RhythmCircle circle);

  /// Sends a gentle stillness nod to a circle or member.
  Future<bool> sendStillnessNudge({
    required String circleId,
    required String targetName,
  });
}
