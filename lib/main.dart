import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/checkin_controller.dart';
import 'controllers/coach_controller.dart';
import 'controllers/feed_controller.dart';
import 'controllers/habit_controller.dart';
import 'controllers/network_controller.dart';
import 'repositories/local_checkin_repository.dart';
import 'repositories/local_coach_repository.dart';
import 'repositories/local_feed_repository.dart';
import 'repositories/local_habit_repository.dart';
import 'repositories/local_network_repository.dart';
import 'screens/coach_screen.dart';
import 'screens/days_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/home_screen.dart';
import 'screens/network_screen.dart';
import 'screens/profile_screen.dart';
import 'services/gemini_coach_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_header.dart';
import 'widgets/tend_bottom_nav_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TendApp());
}

class TendApp extends StatelessWidget {
  final HabitController? habitController;
  final CheckInController? checkInController;
  final CoachController? coachController;
  final FeedController? feedController;
  final NetworkController? networkController;

  const TendApp({
    super.key,
    this.habitController,
    this.checkInController,
    this.coachController,
    this.feedController,
    this.networkController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: MainScaffold(
        habitController: habitController,
        checkInController: checkInController,
        coachController: coachController,
        feedController: feedController,
        networkController: networkController,
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final HabitController? habitController;
  final CheckInController? checkInController;
  final CoachController? coachController;
  final FeedController? feedController;
  final NetworkController? networkController;

  const MainScaffold({
    super.key,
    this.habitController,
    this.checkInController,
    this.coachController,
    this.feedController,
    this.networkController,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  late final HabitController _habitController;
  late final CheckInController _checkInController;
  late final CoachController _coachController;
  late final FeedController _feedController;
  late final NetworkController _networkController;

  @override
  void initState() {
    super.initState();
    _habitController = widget.habitController ??
        HabitController(repository: LocalHabitRepository());
    _habitController.load();

    _checkInController = widget.checkInController ??
        CheckInController(repository: LocalCheckInRepository());
    _checkInController.loadCheckIns();

    _coachController = widget.coachController ??
        CoachController(
          repository: LocalCoachRepository(),
          coachService: GeminiCoachService(),
          habitController: _habitController,
          checkInController: _checkInController,
        );
    _restoreCoachApiKey();

    _feedController = widget.feedController ??
        FeedController(repository: LocalFeedRepository());
    _feedController.loadArticles();

    _networkController = widget.networkController ??
        NetworkController(repository: LocalNetworkRepository());
    _networkController.loadCircles();
  }

  Future<void> _restoreCoachApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGeminiKey = prefs.getString('tend_gemini_api_key');
    if (savedGeminiKey != null && savedGeminiKey.isNotEmpty) {
      _coachController.coachService.setGeminiApiKey(savedGeminiKey);
    }
    final savedGroqKey = prefs.getString('tend_groq_api_key');
    if (savedGroqKey != null && savedGroqKey.isNotEmpty) {
      _coachController.coachService.setGroqApiKey(savedGroqKey);
    }
    final savedProvider = prefs.getString('tend_ai_provider');
    if (savedProvider == 'groq') {
      _coachController.coachService.setProvider(AiProvider.groq);
    } else if (savedProvider == 'gemini') {
      _coachController.coachService.setProvider(AiProvider.gemini);
    } else {
      _coachController.coachService.setProvider(AiProvider.auto);
    }
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          habitController: _habitController,
          checkInController: _checkInController,
          coachController: _coachController,
        ),
      ),
    );
  }

  void _openCoach() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoachScreen(
          controller: _coachController,
          onOpenProfile: _openProfile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        controller: _habitController,
        checkInController: _checkInController,
      ),
      FeedScreen(
        controller: _feedController,
        coachController: _coachController,
        onOpenProfile: _openProfile,
      ),
      NetworkScreen(
        controller: _networkController,
      ),
      DaysScreen(
        checkInController: _checkInController,
        habitController: _habitController,
      ),
    ];

    return Scaffold(
      appBar: AppHeader(
        onSearchTap: () {},
        onProfileTap: _openProfile,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: TendBottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onVoiceTap: _openCoach,
      ),
    );
  }
}
