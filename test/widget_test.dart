import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tend/controllers/checkin_controller.dart';
import 'package:tend/controllers/feed_controller.dart';
import 'package:tend/controllers/habit_controller.dart';
import 'package:tend/controllers/network_controller.dart';
import 'package:tend/main.dart';
import 'package:tend/models/habit.dart';
import 'package:tend/widgets/habit_item_tile.dart';
import 'package:tend/widgets/tend_voice_button.dart';
import 'days_test.dart';
import 'feed_test.dart';
import 'habit_tracker_test.dart';
import 'network_test.dart';

void main() {
  testWidgets('TendApp renders Habit Tracker on Home Screen', (WidgetTester tester) async {
    final repo = InMemoryHabitRepository();
    final controller = HabitController(repository: repo);

    // Seed test habit
    await repo.saveHabit(Habit(
      id: 'test_h1',
      title: 'Morning stillness',
      description: '10m breathing',
      frequencyType: HabitFrequencyType.daily,
      createdAt: DateTime.now(),
    ));

    await tester.pumpWidget(TendApp(habitController: controller));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify main components render
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Good morning, Elena'), findsOneWidget);
    expect(find.text('Today’s Progress'), findsOneWidget);
    expect(find.text('Daily Rhythms'), findsOneWidget);
    expect(find.text('Morning stillness'), findsOneWidget);
    expect(find.text('0 of 1 tended'), findsOneWidget);

    // Verify toggle interaction by scrolling into view and tapping the habit tile
    await tester.ensureVisible(find.byType(HabitItemTile));
    await tester.tap(find.byType(HabitItemTile));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify 1 of 1 tended
    expect(find.text('1 of 1 tended'), findsOneWidget);
  });

  testWidgets('Tapping footer center button opens AI Habit Coach screen', (WidgetTester tester) async {
    final habitRepo = InMemoryHabitRepository();
    final habitCtrl = HabitController(repository: habitRepo);

    await tester.pumpWidget(TendApp(habitController: habitCtrl));
    await tester.pump(const Duration(milliseconds: 300));

    // Find the voice button in bottom navigation
    expect(find.byType(TendVoiceButton), findsWidgets);

    // Tap the center voice button
    await tester.tap(find.byType(TendVoiceButton).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify AI Habit Coach screen opened
    expect(find.text('AI Habit Coach'), findsOneWidget);
    expect(find.text('Ask your coach anything about your habits...'), findsOneWidget);
  });

  testWidgets('Navigating to Feed tab displays Mindful Readings coming soon state',
      (WidgetTester tester) async {
    final habitRepo = InMemoryHabitRepository();
    final habitCtrl = HabitController(repository: habitRepo);
    final feedRepo = InMemoryFeedRepository();
    final feedCtrl = FeedController(repository: feedRepo);

    await tester.pumpWidget(TendApp(
      habitController: habitCtrl,
      feedController: feedCtrl,
    ));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Feed tab (Tab index 1)
    await tester.tap(find.text('Feed'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Feed screen components
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.text('Mindful Feed'), findsOneWidget);
  });

  testWidgets('Navigating to Network tab displays Rhythm Circles coming soon state',
      (WidgetTester tester) async {
    final habitRepo = InMemoryHabitRepository();
    final habitCtrl = HabitController(repository: habitRepo);
    final networkRepo = InMemoryNetworkRepository();
    final networkCtrl = NetworkController(repository: networkRepo);

    await tester.pumpWidget(TendApp(
      habitController: habitCtrl,
      networkController: networkCtrl,
    ));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Network tab (Tab index 2)
    await tester.tap(find.text('Network'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Network screen components
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.text('Rhythm Circles'), findsOneWidget);
  });

  testWidgets('Navigating to Days tab displays Calendar Ledger',
      (WidgetTester tester) async {
    final habitRepo = InMemoryHabitRepository();
    final habitCtrl = HabitController(repository: habitRepo);
    final checkInRepo = InMemoryCheckInRepo();
    final checkInCtrl = CheckInController(repository: checkInRepo);

    await tester.pumpWidget(TendApp(
      habitController: habitCtrl,
      checkInController: checkInCtrl,
    ));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Days tab (Tab index 3)
    await tester.tap(find.text('Days'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Days screen components
    expect(find.text('Calendar Ledger'), findsOneWidget);
    expect(find.text('Reflections Journal'), findsOneWidget);
    expect(find.text('Tended Rhythms'), findsOneWidget);
  });
}
