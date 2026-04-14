import 'package:artemis_work_planner/src/models/goal.dart';
import 'package:artemis_work_planner/src/models/plan.dart';
import 'package:artemis_work_planner/src/screens/goals/goal_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_setup.dart';

void main() {
  final goal = Goal.create(
    id: 'g1',
    title: 'Launch Product X',
    description: 'Ship v1 to customers',
    type: GoalType.farm,
    status: GoalStatus.inProgress,
  );

  setUp(() {
    mockSecureStorage();
    initTestServices();
  });

  group('GoalDetailScreen', () {
    testWidgets('shows goal title and description', (tester) async {
      await tester.pumpWidget(testWidget(GoalDetailScreen(goal: goal)));
      await tester.pumpAndSettle();
      expect(find.text('Launch Product X'), findsOneWidget);
      expect(find.text('Ship v1 to customers'), findsOneWidget);
    });

    testWidgets('shows goal type label', (tester) async {
      await tester.pumpWidget(testWidget(GoalDetailScreen(goal: goal)));
      await tester.pumpAndSettle();
      expect(find.text('Farm'), findsOneWidget);
    });

    testWidgets('shows all four status choice chips', (tester) async {
      await tester.pumpWidget(testWidget(GoalDetailScreen(goal: goal)));
      await tester.pumpAndSettle();
      expect(find.text('Not Started'), findsOneWidget);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Abandoned'), findsOneWidget);
    });

    testWidgets('shows "No plans yet" when no plans are linked', (
      tester,
    ) async {
      await tester.pumpWidget(testWidget(GoalDetailScreen(goal: goal)));
      await tester.pumpAndSettle();
      expect(find.text('No plans yet'), findsOneWidget);
    });

    testWidgets('shows plan cards when plans exist for this goal', (
      tester,
    ) async {
      fakePlans.seed([
        Plan.create(
          id: 'p1',
          title: 'Phase 1',
          description: 'First phase',
          goalId: goal.id,
          status: PlanStatus.active,
        ),
      ]);
      await tester.pumpWidget(testWidget(GoalDetailScreen(goal: goal)));
      await tester.pumpAndSettle();
      expect(find.text('Phase 1'), findsOneWidget);
    });

    testWidgets('does not show plans from a different goal', (tester) async {
      fakePlans.seed([
        Plan.create(
          id: 'p2',
          title: 'Other Goal Plan',
          description: 'D',
          goalId: 'different-goal',
          status: PlanStatus.active,
        ),
      ]);
      await tester.pumpWidget(testWidget(GoalDetailScreen(goal: goal)));
      await tester.pumpAndSettle();
      expect(find.text('Other Goal Plan'), findsNothing);
      expect(find.text('No plans yet'), findsOneWidget);
    });

    testWidgets('shows Plans section header and Add Plan button', (
      tester,
    ) async {
      await tester.pumpWidget(testWidget(GoalDetailScreen(goal: goal)));
      await tester.pumpAndSettle();
      expect(find.text('Plans'), findsOneWidget);
      expect(find.text('Add Plan'), findsOneWidget);
    });

    testWidgets('shows edit and delete action buttons in AppBar', (
      tester,
    ) async {
      await tester.pumpWidget(testWidget(GoalDetailScreen(goal: goal)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('shows "Goal Details" in AppBar title', (tester) async {
      await tester.pumpWidget(testWidget(GoalDetailScreen(goal: goal)));
      await tester.pumpAndSettle();
      expect(find.text('Goal Details'), findsOneWidget);
    });

    testWidgets('shows Status section heading', (tester) async {
      await tester.pumpWidget(testWidget(GoalDetailScreen(goal: goal)));
      await tester.pumpAndSettle();
      expect(find.text('Status'), findsOneWidget);
    });
  });
}
