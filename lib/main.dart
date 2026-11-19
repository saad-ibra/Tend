import 'package:flutter/material.dart';
import 'controllers/habit_controller.dart';
import 'repositories/local_habit_repository.dart';
import 'screens/days_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/home_screen.dart';
import 'screens/network_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_header.dart';
import 'widgets/tend_bottom_nav_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TendApp());
}

class TendApp extends StatelessWidget {
  final HabitController? controller;

  const TendApp({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: MainScaffold(controller: controller),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final HabitController? controller;

  const MainScaffold({super.key, this.controller});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  late final HabitController _habitController;

  @override
  void initState() {
    super.initState();
    _habitController = widget.controller ??
        HabitController(repository: LocalHabitRepository());
    _habitController.load();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(controller: _habitController),
      const FeedScreen(),
      const NetworkScreen(),
      const DaysScreen(),
    ];

    return Scaffold(
      appBar: AppHeader(
        onSearchTap: () {},
        onProfileTap: () {},
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
        onVoiceStateChanged: (state) {
          // Voice interaction state change
        },
      ),
    );
  }
}
