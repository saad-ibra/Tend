import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coach_message.dart';
import '../models/coach_session.dart';
import 'coach_repository.dart';

class LocalCoachRepository implements CoachRepository {
  static const String _sessionStorageKey = 'tend_coach_sessions_v2';
  static const String _legacyMessagesKey = 'tend_coach_messages_v1';

  final SharedPreferences? prefs;

  LocalCoachRepository({this.prefs});

  Future<SharedPreferences> _getPrefs() async {
    return prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<List<CoachSession>> getSessions() async {
    final sp = await _getPrefs();
    final rawList = sp.getStringList(_sessionStorageKey);

    if (rawList == null || rawList.isEmpty) {
      // Check for legacy messages migration
      final legacyList = sp.getStringList(_legacyMessagesKey);
      if (legacyList != null && legacyList.isNotEmpty) {
        final legacyMessages = legacyList
            .map((str) => CoachMessage.fromJson(jsonDecode(str) as Map<String, dynamic>))
            .toList();
        final defaultSession = CoachSession(
          id: 'session_legacy',
          title: 'Initial Reflection',
          createdAt: legacyMessages.isNotEmpty ? legacyMessages.first.timestamp : DateTime.now(),
          updatedAt: legacyMessages.isNotEmpty ? legacyMessages.last.timestamp : DateTime.now(),
          messages: legacyMessages,
        );
        await saveSession(defaultSession);
        return [defaultSession];
      }
      return [];
    }

    final sessions = rawList
        .map((str) => CoachSession.fromJson(jsonDecode(str) as Map<String, dynamic>))
        .toList();

    // Sort: pinned first, then by updatedAt descending
    sessions.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return sessions;
  }

  @override
  Future<CoachSession?> getSession(String id) async {
    final sessions = await getSessions();
    try {
      return sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSession(CoachSession session) async {
    final sp = await _getPrefs();
    final sessions = await getSessions();
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.insert(0, session);
    }
    await _persistSessions(sessions, sp);
  }

  @override
  Future<void> deleteSession(String id) async {
    final sp = await _getPrefs();
    final sessions = await getSessions();
    sessions.removeWhere((s) => s.id == id);
    await _persistSessions(sessions, sp);
  }

  @override
  Future<void> togglePinSession(String id) async {
    final sp = await _getPrefs();
    final sessions = await getSessions();
    final idx = sessions.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      sessions[idx] = sessions[idx].copyWith(isPinned: !sessions[idx].isPinned);
      await _persistSessions(sessions, sp);
    }
  }

  @override
  Future<void> toggleArchiveSession(String id) async {
    final sp = await _getPrefs();
    final sessions = await getSessions();
    final idx = sessions.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      sessions[idx] = sessions[idx].copyWith(isArchived: !sessions[idx].isArchived);
      await _persistSessions(sessions, sp);
    }
  }

  Future<void> _persistSessions(List<CoachSession> sessions, SharedPreferences sp) async {
    final encoded = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await sp.setStringList(_sessionStorageKey, encoded);
  }

  // --- Legacy Compatibility Methods ---

  @override
  Future<List<CoachMessage>> getMessages() async {
    final sessions = await getSessions();
    if (sessions.isEmpty) return [];
    return sessions.first.messages;
  }

  @override
  Future<void> saveMessage(CoachMessage message) async {
    final sessions = await getSessions();
    if (sessions.isEmpty) {
      final now = DateTime.now();
      final newSession = CoachSession(
        id: 'session_${now.millisecondsSinceEpoch}',
        title: message.text.length > 30 ? '${message.text.substring(0, 30)}...' : message.text,
        createdAt: now,
        updatedAt: now,
        messages: [message],
      );
      await saveSession(newSession);
    } else {
      final first = sessions.first;
      final updatedList = List<CoachMessage>.from(first.messages)..add(message);
      final updatedSession = first.copyWith(
        messages: updatedList,
        updatedAt: DateTime.now(),
      );
      await saveSession(updatedSession);
    }
  }

  @override
  Future<void> updateMessage(CoachMessage message) async {
    final sessions = await getSessions();
    for (final session in sessions) {
      final idx = session.messages.indexWhere((m) => m.id == message.id);
      if (idx >= 0) {
        final updatedList = List<CoachMessage>.from(session.messages);
        updatedList[idx] = message;
        await saveSession(session.copyWith(messages: updatedList));
        break;
      }
    }
  }

  @override
  Future<void> clearHistory() async {
    final sp = await _getPrefs();
    await sp.remove(_sessionStorageKey);
    await sp.remove(_legacyMessagesKey);
  }
}
