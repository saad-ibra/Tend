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

  List<CoachSession> _parseRawSessions(List<String>? rawList) {
    if (rawList == null || rawList.isEmpty) return [];
    final sessions = <CoachSession>[];
    for (final str in rawList) {
      try {
        sessions.add(CoachSession.fromJson(jsonDecode(str) as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupted entries safely
      }
    }
    sessions.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return sessions;
  }

  @override
  Future<List<CoachSession>> getSessions() async {
    final sp = await _getPrefs();
    final rawList = sp.getStringList(_sessionStorageKey);

    if (rawList == null || rawList.isEmpty) {
      // Check for legacy messages migration
      final legacyList = sp.getStringList(_legacyMessagesKey);
      if (legacyList != null && legacyList.isNotEmpty) {
        final legacyMessages = <CoachMessage>[];
        for (final str in legacyList) {
          try {
            legacyMessages.add(CoachMessage.fromJson(jsonDecode(str) as Map<String, dynamic>));
          } catch (_) {}
        }
        final defaultSession = CoachSession(
          id: 'session_legacy',
          title: 'Initial Reflection',
          createdAt: legacyMessages.isNotEmpty ? legacyMessages.first.timestamp : DateTime.now(),
          updatedAt: legacyMessages.isNotEmpty ? legacyMessages.last.timestamp : DateTime.now(),
          messages: legacyMessages,
        );
        // Persist directly and remove legacy key without calling saveSession to prevent recursion
        await _persistSessions([defaultSession], sp);
        try {
          await sp.remove(_legacyMessagesKey);
        } catch (_) {}
        return [defaultSession];
      }
      return [];
    }

    return _parseRawSessions(rawList);
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
    final rawList = sp.getStringList(_sessionStorageKey);
    final sessions = _parseRawSessions(rawList);
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
    final rawList = sp.getStringList(_sessionStorageKey);
    final sessions = _parseRawSessions(rawList);
    sessions.removeWhere((s) => s.id == id);
    await _persistSessions(sessions, sp);
  }

  @override
  Future<void> togglePinSession(String id) async {
    final sp = await _getPrefs();
    final rawList = sp.getStringList(_sessionStorageKey);
    final sessions = _parseRawSessions(rawList);
    final idx = sessions.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      sessions[idx] = sessions[idx].copyWith(isPinned: !sessions[idx].isPinned);
      await _persistSessions(sessions, sp);
    }
  }

  @override
  Future<void> toggleArchiveSession(String id) async {
    final sp = await _getPrefs();
    final rawList = sp.getStringList(_sessionStorageKey);
    final sessions = _parseRawSessions(rawList);
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
    if (sessions.isNotEmpty) return sessions.first.messages;
    return [];
  }

  @override
  Future<void> saveMessage(CoachMessage message) async {
    final sessions = await getSessions();
    if (sessions.isNotEmpty) {
      final s = sessions.first;
      final updated = s.copyWith(messages: List.from(s.messages)..add(message));
      await saveSession(updated);
    }
  }

  @override
  Future<void> updateMessage(CoachMessage message) async {
    final sessions = await getSessions();
    if (sessions.isNotEmpty) {
      final s = sessions.first;
      final mList = List<CoachMessage>.from(s.messages);
      final idx = mList.indexWhere((m) => m.id == message.id);
      if (idx >= 0) {
        mList[idx] = message;
        await saveSession(s.copyWith(messages: mList));
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
