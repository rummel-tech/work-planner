import 'package:artemis_work_planner/src/models/plan.dart';
import 'package:artemis_work_planner/src/screens/plans/plans_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(() {
    mockSecureStorage();
    initTestServices();
  });

  group('PlansScreen', () {
    Widget buildScreen({String goalId = 'goal-1'}) =>
        testWidget(PlansScreen(goalId: goalId));

    testWidgets('shows "Plans" in the AppBar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Plans'), findsOneWidget);
    });

    testWidgets('shows empty state when no plans exist', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('No plans yet'), findsOneWidget);
      expect(
          find.text('Create a plan to work towards your goal'), findsOneWidget);
    });

    testWidgets('always shows a FAB', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows plan cards when plans are seeded', (tester) async {
      fakePlans.seed([
        Plan.create(
          id: 'p1',
          title: 'Sprint Plan',
          description: 'Two-week sprint',
          goalId: 'goal-1',
          status: PlanStatus.active,
        ),
        Plan.create(
          id: 'p2',
          title: 'Q3 Roadmap',
          description: 'Quarterly plan',
          goalId: 'goal-1',
          status: PlanStatus.draft,
        ),
      ]);
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Sprint Plan'), findsOneWidget);
      expect(find.text('Q3 Roadmap'), findsOneWidget);
    });

    testWidgets('only shows plans for the given goalId', (tester) async {
      fakePlans.seed([
        Plan.create(
          id: 'p1',
          title: 'My Goal Plan',
          description: 'D',
          goalId: 'goal-1',
          status: PlanStatus.active,
        ),
        Plan.create(
          id: 'p2',
          title: 'Other Goal Plan',
          description: 'D',
          goalId: 'goal-2',
          status: PlanStatus.active,
        ),
      ]);
      await tester.pumpWidget(buildScreen(goalId: 'goal-1'));
      await tester.pumpAndSettle();
      expect(find.text('My Goal Plan'), findsOneWidget);
      expect(find.text('Other Goal Plan'), findsNothing);
    });

    testWidgets('empty state contains a "Create Plan" action button',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Create Plan'), findsOneWidget);
    });
  });
}
