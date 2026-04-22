import 'package:artemis_work_planner/src/planners/day_planner.dart';
import 'package:artemis_work_planner/src/screens/daily/day_planner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_setup.dart';

void main() {
  final testDate = DateTime(2025, 6, 16); // Monday

  setUp(() {
    mockSecureStorage();
    initTestServices();
  });

  Widget buildScreen() => testWidget(DayPlannerScreen(date: testDate));

  group('DayPlannerScreen', () {
    testWidgets('renders 4 block sections', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Block 1'), findsOneWidget);
      expect(find.text('Block 2'), findsOneWidget);
      expect(find.text('Block 3'), findsOneWidget);
      expect(find.text('Block 4'), findsOneWidget);
    });

    testWidgets('shows empty state text in each block when no tasks', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No tasks — tap + to add'), findsNWidgets(4));
    });

    testWidgets('does not show Unassigned section when no tasks', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Unassigned'), findsNothing);
    });

    testWidgets('shows task in correct block after seeding', (tester) async {
      // Seed a task in block 2 via the fake repository
      await fakePlanners.getOrCreateDayPlanner(testDate);
      final task = Task.create(title: 'Block 2 Task', pomodoroBlock: 2);
      await fakePlanners.addTask(testDate, task);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Block 2 Task'), findsOneWidget);
    });

    testWidgets('shows Unassigned section when task has no block', (
      tester,
    ) async {
      final task = Task.create(title: 'Floating Task');
      await fakePlanners.addTask(testDate, task);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Unassigned'), findsOneWidget);
      expect(find.text('Floating Task'), findsOneWidget);
    });

    testWidgets('displays correct task count summary', (tester) async {
      await fakePlanners.addTask(
        testDate,
        Task.create(title: 'T1', completed: true),
      );
      await fakePlanners.addTask(testDate, Task.create(title: 'T2'));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 tasks completed'), findsOneWidget);
    });

    testWidgets('has a FAB to add unassigned tasks', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows Notes section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
    });
  });
}
