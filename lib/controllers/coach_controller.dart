import 'package:flutter/foundation.dart';
import '../models/coach_action.dart';
import '../models/coach_message.dart';
import '../models/coach_session.dart';
import '../models/habit.dart';
import '../repositories/coach_repository.dart';
import '../services/gemini_coach_service.dart';
import 'checkin_controller.dart';
import 'habit_controller.dart';

class CoachController extends ChangeNotifier {
  final CoachRepository repository;
  final GeminiCoachService coachService;
  final HabitController habitController;
  final CheckInController? checkInController;

  static int _sessionCounter = 0;
  List<CoachSession> _sessions = [];
  String? _currentSessionId;
  bool _isThinking = false;
  String? _errorMessage;

  CoachController({
    required this.repository,
    required this.coachService,
    required this.habitController,
    this.checkInController,
  });

  List<CoachSession> get sessions => List.unmodifiable(_sessions);
  List<CoachSession> get activeSessions =>
      _sessions.where((s) => !s.isArchived).toList();
  List<CoachSession> get archivedSessions =>
      _sessions.where((s) => s.isArchived).toList();

  CoachSession? get currentSession {
    if (_sessions.isEmpty) return null;
    return _sessions.firstWhere(
      (s) => s.id == _currentSessionId,
      orElse: () => _sessions.first,
    );
  }

  List<CoachMessage> get messages => currentSession?.messages ?? [];
  bool get isThinking => _isThinking;
  String? get errorMessage => _errorMessage;

  Future<void> loadConversation() async {
    _sessions = await repository.getSessions();

    if (_sessions.isEmpty) {
      final now = DateTime.now();
      final welcome = CoachMessage(
        id: 'welcome_${now.millisecondsSinceEpoch}',
        sender: CoachSender.coach,
        text: 'Welcome to your mindful habit reflection space. I observe your rhythms, consistency patterns, and inner climate to help you tend to your days with patience and intention.\n\n'
            'Ask me anything about your habit progress, request a weekly summary, or ask for a personalized rhythm suggestion.',
        timestamp: now,
      );
      final defaultSession = CoachSession(
        id: 'session_${now.microsecondsSinceEpoch}_${_sessionCounter++}',
        title: 'Rhythm Reflection',
        createdAt: now,
        updatedAt: now,
        messages: [welcome],
      );
      await repository.saveSession(defaultSession);
      _sessions = [defaultSession];
    }

    _currentSessionId ??= _sessions.first.id;
    notifyListeners();
  }

  Future<void> createNewSession({String? title}) async {
    final now = DateTime.now();
    final welcome = CoachMessage(
      id: 'welcome_${now.millisecondsSinceEpoch}',
      sender: CoachSender.coach,
      text: 'Starting a new conversation. What rhythm or reflection would you like to explore together?',
      timestamp: now,
    );

    final newSession = CoachSession(
      id: 'session_${now.microsecondsSinceEpoch}_${_sessionCounter++}',
      title: title ?? 'New Conversation',
      createdAt: now,
      updatedAt: now,
      messages: [welcome],
    );

    await repository.saveSession(newSession);
    _sessions.insert(0, newSession);
    _currentSessionId = newSession.id;
    notifyListeners();
  }

  void switchSession(String sessionId) {
    if (_currentSessionId != sessionId) {
      _currentSessionId = sessionId;
      notifyListeners();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await repository.deleteSession(sessionId);
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_sessions.isEmpty) {
      await loadConversation();
    } else {
      _currentSessionId = _sessions.first.id;
      notifyListeners();
    }
  }

  Future<void> togglePinSession(String sessionId) async {
    await repository.togglePinSession(sessionId);
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx >= 0) {
      _sessions[idx] = _sessions[idx].copyWith(isPinned: !_sessions[idx].isPinned);
      _sessions.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      notifyListeners();
    }
  }

  Future<void> toggleArchiveSession(String sessionId) async {
    await repository.toggleArchiveSession(sessionId);
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx >= 0) {
      _sessions[idx] = _sessions[idx].copyWith(isArchived: !_sessions[idx].isArchived);
      notifyListeners();
    }
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx >= 0) {
      final updated = _sessions[idx].copyWith(title: newTitle);
      _sessions[idx] = updated;
      await repository.saveSession(updated);
      notifyListeners();
    }
  }

  Map<String, dynamic> buildHabitContext() {
    final active = habitController.activeHabits;
    final weekly = habitController.getWeeklyProgress();

    int totalScheduled = 0;
    int totalCompleted = 0;
    for (final day in weekly) {
      totalScheduled += day.totalDueCount;
      totalCompleted += day.completedCount;
    }
    final int weeklyPct = totalScheduled > 0
        ? ((totalCompleted / totalScheduled) * 100).round()
        : 100;

    int topStreak = 0;
    for (final h in active) {
      final s = habitController.getStreakForHabit(h.id);
      if (s > topStreak) topStreak = s;
    }

    final todayCheckIn = checkInController?.todayCheckIn;

    return {
      'active_habits': active.map((h) => {
            'id': h.id,
            'title': h.title,
            'description': h.description,
            'frequency': h.frequencyLabel,
            'color_hex': h.colorHex,
            'current_streak': habitController.getStreakForHabit(h.id),
          }).toList(),
      'archived_count': habitController.archivedHabits.length,
      'weekly_completion_percentage': weeklyPct,
      'top_streak': topStreak,
      'today_mood': todayCheckIn?.moodLabel ?? 'Steady',
      'today_energy': todayCheckIn?.energyLabel ?? 'Gentle',
      'today_tags': todayCheckIn?.tags ?? [],
      'today_note': todayCheckIn?.note ?? '',
    };
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (_sessions.isEmpty || currentSession == null) {
      await loadConversation();
    }

    final session = currentSession!;
    final now = DateTime.now();

    final userMsg = CoachMessage(
      id: 'user_${now.millisecondsSinceEpoch}',
      sender: CoachSender.user,
      text: trimmed,
      timestamp: now,
    );

    // Auto-update conversation title if it was default
    String updatedTitle = session.title;
    if (session.messages.length <= 1 && (session.title == 'New Conversation' || session.title == 'Rhythm Reflection')) {
      updatedTitle = trimmed.length > 28 ? '${trimmed.substring(0, 28)}...' : trimmed;
    }

    final updatedMessages = List<CoachMessage>.from(session.messages)..add(userMsg);
    final updatedSession = session.copyWith(
      title: updatedTitle,
      messages: updatedMessages,
      updatedAt: now,
    );

    final sessionIdx = _sessions.indexWhere((s) => s.id == session.id);
    if (sessionIdx >= 0) {
      _sessions[sessionIdx] = updatedSession;
    }
    await repository.saveSession(updatedSession);

    _isThinking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final contextData = buildHabitContext();
      final reply = await coachService.generateAdvice(
        userPrompt: trimmed,
        contextData: contextData,
      );

      final withReplyMessages = List<CoachMessage>.from(updatedSession.messages)..add(reply);
      final finalSession = updatedSession.copyWith(
        messages: withReplyMessages,
        updatedAt: DateTime.now(),
      );

      if (sessionIdx >= 0) {
        _sessions[sessionIdx] = finalSession;
      }
      await repository.saveSession(finalSession);
    } catch (e) {
      _errorMessage = 'Could not generate coach response: $e';
    } finally {
      _isThinking = false;
      notifyListeners();
    }
  }

  Future<bool> executeAction(CoachMessage message, CoachAction action) async {
    bool success = false;

    if (action.type == CoachActionType.createHabit) {
      success = await habitController.createHabit(
        title: action.title,
        description: action.description,
        frequencyType: action.frequencyType,
        targetWeekdays: action.targetWeekdays,
        colorHex: action.colorHex,
      );
    } else if (action.type == CoachActionType.modifyHabit) {
      if (action.targetHabitId != null && habitController.activeHabits.isNotEmpty) {
        final existing = habitController.habits.firstWhere(
          (h) => h.id == action.targetHabitId,
          orElse: () => habitController.activeHabits.first,
        );
        final updatedHabit = Habit(
          id: existing.id,
          title: action.title.isNotEmpty ? action.title : existing.title,
          description: action.description ?? existing.description,
          frequencyType: action.frequencyType,
          targetWeekdays: action.targetWeekdays,
          colorHex: action.colorHex,
          isArchived: existing.isArchived,
          createdAt: existing.createdAt,
        );
        success = await habitController.updateHabit(updatedHabit);
      }
    }

    if (success) {
      action.isExecuted = true;
      action.isDismissed = false;

      final session = currentSession;
      if (session != null) {
        final now = DateTime.now();
        final confirmation = CoachMessage(
          id: 'conf_${now.millisecondsSinceEpoch}',
          sender: CoachSender.coach,
          text: 'I have updated your rhythms with "${action.title}". May this small adjustment bring renewed ease to your days.',
          timestamp: now,
        );
        final updatedMessages = List<CoachMessage>.from(session.messages)..add(confirmation);
        final updatedSession = session.copyWith(
          messages: updatedMessages,
          updatedAt: now,
        );
        final idx = _sessions.indexWhere((s) => s.id == session.id);
        if (idx >= 0) {
          _sessions[idx] = updatedSession;
        }
        await repository.saveSession(updatedSession);
      }

      notifyListeners();
    }

    return success;
  }

  Future<void> dismissAction(CoachMessage message, CoachAction action) async {
    action.isDismissed = true;
    final session = currentSession;
    if (session != null) {
      await repository.saveSession(session);
    }
    notifyListeners();
  }

  Future<void> clearHistory() async {
    if (currentSession != null) {
      await deleteSession(currentSession!.id);
    }
  }
}
