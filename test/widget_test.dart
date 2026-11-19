import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tend/controllers/habit_controller.dart';
import 'package:tend/main.dart';
import 'package:tend/models/habit.dart';
import 'package:tend/widgets/habit_item_tile.dart';
import 'habit_tracker_test.dart';

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

    await tester.pumpWidget(TendApp(controller: controller));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify main components render
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Good morning, Elena'), findsOneWidget);
    expect(find.text('Today’s Progress'), findsOneWidget);
    expect(find.text('Daily Rhythms'), findsOneWidget);
    expect(find.text('Morning stillness'), findsOneWidget);
    expect(find.text('0 of 1 tended'), findsOneWidget);

    // Verify toggle interaction by tapping the habit tile
    await tester.tap(find.byType(HabitItemTile));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify 1 of 1 tended
    expect(find.text('1 of 1 tended'), findsOneWidget);
  });
}
