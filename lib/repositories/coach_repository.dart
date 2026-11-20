import '../models/coach_message.dart';
import '../models/coach_session.dart';

abstract class CoachRepository {
  Future<List<CoachSession>> getSessions();
  Future<CoachSession?> getSession(String id);
  Future<void> saveSession(CoachSession session);
  Future<void> deleteSession(String id);
  Future<void> togglePinSession(String id);
  Future<void> toggleArchiveSession(String id);

  // Legacy single-thread support
  Future<List<CoachMessage>> getMessages();
  Future<void> saveMessage(CoachMessage message);
  Future<void> updateMessage(CoachMessage message);
  Future<void> clearHistory();
}
