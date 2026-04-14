import 'package:artemis_work_planner/src/screens/weekly/weekly_planner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_setup.dart';

void main() {
  // Fixed week to avoid date-dependent test failures
  final fixedWeekStart = DateTime(2025, 6, 16); // Monday 16 Jun – Sun 22 Jun

  setUp(() {
    mockSecureStorage();
    initTestServices();
  });

  Widget buildScreen() =>
      testWidget(WeeklyPlannerScreen(initialWeekStart: fixedWeekStart));

  group('WeeklyPlannerScreen', () {
    testWidgets('shows "Weekly Planner" in the AppBar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Weekly Planner'), findsOneWidget);
    });

    testWidgets('displays the formatted week date range', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      // 16 Jun (Mon) to 22 Jun (Sun)
      expect(find.text('6/16 - 6/22'), findsOneWidget);
    });

    testWidgets('shows "Week Progress" card', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Week Progress'), findsOneWidget);
    });

    testWidgets('shows "0% complete" when no tasks exist', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('0% complete'), findsOneWidget);
    });

    testWidgets('shows "Weekly Goals" section header', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Weekly Goals'), findsOneWidget);
    });

    testWidgets('shows "No weekly goals set" when goals list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('No weekly goals set'), findsOneWidget);
    });

    testWidgets('shows all 7 day labels (Mon–Sun)', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
        expect(find.text(day), findsOneWidget);
      }
    });

    testWidgets('shows "No tasks" for each day when no tasks are scheduled', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('No tasks'), findsNWidgets(7));
    });

    testWidgets('shows Notes section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('shows previous and next week navigation buttons', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      // Nav buttons are IconButtons; day-row trailing chevrons are plain Icons
      expect(find.widgetWithIcon(IconButton, Icons.chevron_left), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows correct day-of-month numbers for the fixed week', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      // 16 Jun (Mon) through 22 Jun (Sun)
      for (final day in ['16', '17', '18', '19', '20', '21', '22']) {
        expect(find.text(day), findsOneWidget);
      }
    });
  });
}
