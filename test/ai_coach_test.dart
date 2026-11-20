import 'package:flutter_test/flutter_test.dart';
import 'package:tend/controllers/coach_controller.dart';
import 'package:tend/controllers/habit_controller.dart';
import 'package:tend/models/coach_action.dart';
import 'package:tend/models/coach_message.dart';
import 'package:tend/models/coach_session.dart';
import 'package:tend/models/habit.dart';
import 'package:tend/repositories/coach_repository.dart';
import 'package:tend/services/gemini_coach_service.dart';
import 'habit_tracker_test.dart';

class InMemoryCoachRepository implements CoachRepository {
  final List<CoachSession> _sessions = [];
  final List<CoachMessage> _messages = [];

  @override
  Future<List<CoachSession>> getSessions() async {
    return List.from(_sessions);
  }

  @override
  Future<CoachSession?> getSession(String id) async {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSession(CoachSession session) async {
    final idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      _sessions[idx] = session;
    } else {
      _sessions.add(session);
    }
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> togglePinSession(String id) async {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      _sessions[idx] = _sessions[idx].copyWith(isPinned: !_sessions[idx].isPinned);
    }
  }

  @override
  Future<void> toggleArchiveSession(String id) async {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      _sessions[idx] = _sessions[idx].copyWith(isArchived: !_sessions[idx].isArchived);
    }
  }

  @override
  Future<List<CoachMessage>> getMessages() async {
    if (_sessions.isNotEmpty) return _sessions.first.messages;
    return List.from(_messages);
  }

  @override
  Future<void> saveMessage(CoachMessage message) async {
    if (_sessions.isNotEmpty) {
      final s = _sessions.first;
      final updated = s.copyWith(messages: List.from(s.messages)..add(message));
      await saveSession(updated);
    } else {
      _messages.add(message);
    }
  }

  @override
  Future<void> updateMessage(CoachMessage message) async {
    if (_sessions.isNotEmpty) {
      final s = _sessions.first;
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
    _sessions.clear();
    _messages.clear();
  }
}

void main() {
  group('CoachAction, CoachMessage & CoachSession Model Tests', () {
    test('CoachAction JSON serialization and deserialization', () {
      final action = CoachAction(
        id: 'act_101',
        type: CoachActionType.createHabit,
        title: 'Evening stillness',
        description: '5 min breathing',
        frequencyType: HabitFrequencyType.daily,
        targetWeekdays: const [1, 2, 3, 4, 5, 6, 7],
        colorHex: '#744127',
        reason: 'Restores evening focus',
      );

      final json = action.toJson();
      final restored = CoachAction.fromJson(json);

      expect(restored.id, 'act_101');
      expect(restored.type, CoachActionType.createHabit);
      expect(restored.title, 'Evening stillness');
      expect(restored.description, '5 min breathing');
      expect(restored.frequencyType, HabitFrequencyType.daily);
      expect(restored.isExecuted, false);
      expect(restored.isDismissed, false);
    });

    test('CoachMessage JSON serialization and deserialization with action', () {
      final now = DateTime.now();
      final action = CoachAction(
        id: 'act_102',
        type: CoachActionType.modifyHabit,
        targetHabitId: 'h_1',
        title: 'Morning stretch',
        reason: 'Scale down to 2 mins',
      );

      final message = CoachMessage(
        id: 'msg_1',
        sender: CoachSender.coach,
        text: 'Consider scaling down to maintain momentum.',
        timestamp: now,
        action: action,
        metricsSummary: {'completion_rate': '85%'},
      );

      final json = message.toJson();
      final restored = CoachMessage.fromJson(json);

      expect(restored.id, 'msg_1');
      expect(restored.sender, CoachSender.coach);
      expect(restored.text, 'Consider scaling down to maintain momentum.');
      expect(restored.action?.type, CoachActionType.modifyHabit);
      expect(restored.metricsSummary?['completion_rate'], '85%');
    });

    test('CoachSession JSON serialization and deserialization', () {
      final now = DateTime.now();
      final session = CoachSession(
        id: 'sess_1',
        title: 'Reflection on Consistency',
        createdAt: now,
        updatedAt: now,
        isPinned: true,
        isArchived: false,
        messages: [
          CoachMessage(
            id: 'm1',
            sender: CoachSender.coach,
            text: 'Hello',
            timestamp: now,
          ),
        ],
      );

      final json = session.toJson();
      final restored = CoachSession.fromJson(json);

      expect(restored.id, 'sess_1');
      expect(restored.title, 'Reflection on Consistency');
      expect(restored.isPinned, true);
      expect(restored.isArchived, false);
      expect(restored.messages.length, 1);
    });
  });

  group('GeminiCoachService Contextual Logic Tests', () {
    final service = GeminiCoachService();

    test('Generates weekly summary advice from actual context data', () async {
      final context = {
        'active_habits': [
          {'id': 'h_1', 'title': 'Stillness', 'color_hex': '#744127'}
        ],
        'weekly_completion_percentage': 82,
        'top_streak': 5,
        'today_mood': 'Grounded',
        'today_energy': 'Gentle',
      };

      final reply = await service.generateAdvice(
        userPrompt: 'Can you give me a weekly summary of my progress?',
        contextData: context,
      );

      expect(reply.sender, CoachSender.coach);
      expect(reply.text.contains('82%'), true);
      expect(reply.text.contains('5 days'), true);
      expect(reply.metricsSummary?['completion_rate'], '82%');
    });

    test('Suggests actionable rhythm creation with CoachAction', () async {
      final context = {
        'active_habits': [],
        'weekly_completion_percentage': 100,
        'top_streak': 0,
        'today_mood': 'Steady',
        'today_energy': 'Gentle',
      };

      final reply = await service.generateAdvice(
        userPrompt: 'Suggest a new rhythm to start',
        contextData: context,
      );

      expect(reply.action, isNotNull);
      expect(reply.action?.type, CoachActionType.createHabit);
      expect(reply.action?.title.isNotEmpty, true);
    });

    test('cleanAndParseJson handles raw and markdown-fenced JSON reliably', () {
      const rawJson = '{"message": "Hello", "weekly_summary": {"completion_rate": "80%"}}';
      final parsedRaw = GeminiCoachService.cleanAndParseJson(rawJson);
      expect(parsedRaw?['message'], 'Hello');

      const fencedJson = '```json\n{"message": "Fenced", "weekly_summary": {"completion_rate": "90%"}}\n```';
      final parsedFenced = GeminiCoachService.cleanAndParseJson(fencedJson);
      expect(parsedFenced?['message'], 'Fenced');

      const prefixedJson = 'Here is the response:\n```\n{"message": "Prefixed"}\n```';
      final parsedPrefixed = GeminiCoachService.cleanAndParseJson(prefixedJson);
      expect(parsedPrefixed?['message'], 'Prefixed');
    });

    test('Auto-detects Groq key based on gsk_ prefix', () {
      final multiService = GeminiCoachService();
      multiService.setApiKey('gsk_test123456');

      expect(multiService.groqApiKey, 'gsk_test123456');
      expect(multiService.isCloudConfigured, true);
    });

    test('Reports informative error when selected provider key is missing', () async {
      final service = GeminiCoachService();
      service.setProvider(AiProvider.groq);

      final reply = await service.generateAdvice(
        userPrompt: 'Hello',
        contextData: {},
      );

      expect(reply.sender, CoachSender.coach);
      expect(service.lastError, contains('Groq Cloud selected as provider, but no API key is set'));
    });

    test('Tests key validation methods for empty key input', () async {
      final service = GeminiCoachService();
      final groqResult = await service.testGroqApiKey('');
      final geminiResult = await service.testGeminiApiKey('');

      expect(groqResult, contains('cannot be empty'));
      expect(geminiResult, contains('cannot be empty'));
    });
  });

  group('CoachController State & Session Management Tests', () {
    late InMemoryCoachRepository coachRepo;
    late InMemoryHabitRepository habitRepo;
    late HabitController habitCtrl;
    late CoachController coachCtrl;

    setUp(() {
      coachRepo = InMemoryCoachRepository();
      habitRepo = InMemoryHabitRepository();
      habitCtrl = HabitController(repository: habitRepo);
      coachCtrl = CoachController(
        repository: coachRepo,
        coachService: GeminiCoachService(),
        habitController: habitCtrl,
      );
    });

    test('Loads initial welcome message and default session when empty', () async {
      await coachCtrl.loadConversation();
      expect(coachCtrl.sessions.length, 1);
      expect(coachCtrl.messages.length, 1);
      expect(coachCtrl.messages.first.sender, CoachSender.coach);
      expect(coachCtrl.messages.first.text.contains('Welcome'), true);
    });

    test('Creates new conversation session and switches active context', () async {
      await coachCtrl.loadConversation();
      expect(coachCtrl.sessions.length, 1);
      final firstId = coachCtrl.currentSession!.id;

      await coachCtrl.createNewSession(title: 'Morning Focus');
      expect(coachCtrl.sessions.length, 2);
      expect(coachCtrl.currentSession!.title, 'Morning Focus');
      expect(coachCtrl.currentSession!.id != firstId, true);

      // Switch back
      coachCtrl.switchSession(firstId);
      expect(coachCtrl.currentSession!.id, firstId);
    });

    test('Pinning and Archiving conversations updates session flags', () async {
      await coachCtrl.loadConversation();
      final currentId = coachCtrl.currentSession!.id;

      expect(coachCtrl.currentSession!.isPinned, false);
      await coachCtrl.togglePinSession(currentId);
      expect(coachCtrl.currentSession!.isPinned, true);

      expect(coachCtrl.currentSession!.isArchived, false);
      await coachCtrl.toggleArchiveSession(currentId);
      expect(coachCtrl.currentSession!.isArchived, true);
      expect(coachCtrl.archivedSessions.length, 1);
      expect(coachCtrl.activeSessions.isEmpty, true);
    });

    test('Renaming conversation updates session title', () async {
      await coachCtrl.loadConversation();
      final currentId = coachCtrl.currentSession!.id;

      await coachCtrl.renameSession(currentId, 'Custom Rhythm Plan');
      expect(coachCtrl.currentSession!.title, 'Custom Rhythm Plan');
    });

    test('Deleting conversation removes session and maintains fallback', () async {
      await coachCtrl.loadConversation();
      await coachCtrl.createNewSession(title: 'Session to Delete');
      expect(coachCtrl.sessions.length, 2);

      final deleteId = coachCtrl.currentSession!.id;
      await coachCtrl.deleteSession(deleteId);
      expect(coachCtrl.sessions.length, 1);
      expect(coachCtrl.currentSession!.id != deleteId, true);
    });

    test('Sending message appends user message and receives coach advice', () async {
      await coachCtrl.loadConversation();
      expect(coachCtrl.messages.length, 1);

      await coachCtrl.sendMessage('How is my consistency this week?');
      expect(coachCtrl.messages.length, 3);
      expect(coachCtrl.messages[1].sender, CoachSender.user);
      expect(coachCtrl.messages[1].text, 'How is my consistency this week?');
      expect(coachCtrl.messages[2].sender, CoachSender.coach);
    });

    test('Executing CoachAction creates a new habit in HabitController upon user confirmation', () async {
      await coachCtrl.loadConversation();
      expect(habitCtrl.habits.isEmpty, true);

      final action = CoachAction(
        id: 'act_create_test',
        type: CoachActionType.createHabit,
        title: 'Evening reading',
        description: '10 pages of philosophy',
        frequencyType: HabitFrequencyType.daily,
        colorHex: '#55614E',
      );

      final msg = CoachMessage(
        id: 'msg_test',
        sender: CoachSender.coach,
        text: 'I suggest reading.',
        timestamp: DateTime.now(),
        action: action,
      );
      await coachRepo.saveMessage(msg);

      final success = await coachCtrl.executeAction(msg, action);
      expect(success, true);
      expect(action.isExecuted, true);

      // Verify habit was actually created in HabitController
      expect(habitCtrl.habits.length, 1);
      expect(habitCtrl.habits.first.title, 'Evening reading');
    });

    test('Dismissing CoachAction marks action as dismissed', () async {
      final action = CoachAction(
        id: 'act_dismiss_test',
        type: CoachActionType.createHabit,
        title: 'Cold shower',
      );
      final msg = CoachMessage(
        id: 'msg_dismiss',
        sender: CoachSender.coach,
        text: 'Take cold showers.',
        timestamp: DateTime.now(),
        action: action,
      );
      await coachRepo.saveMessage(msg);

      await coachCtrl.dismissAction(msg, action);
      expect(action.isDismissed, true);
    });
  });
}
