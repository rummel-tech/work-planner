import 'package:artemis_work_planner/src/models/plan.dart';
import 'package:artemis_work_planner/src/screens/plans/plan_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(() {
    mockSecureStorage();
    initTestServices();
  });

  final planWithSteps = Plan.create(
    id: 'p1',
    title: 'Quarterly Roadmap',
    description: 'Plan for Q3 objectives',
    goalId: 'g1',
    steps: ['Research', 'Design', 'Build', 'Ship'],
    status: PlanStatus.active,
  );

  final planNoSteps = Plan.create(
    id: 'p2',
    title: 'Empty Plan',
    description: 'A plan with no steps',
    goalId: 'g1',
    status: PlanStatus.draft,
  );

  group('PlanDetailScreen', () {
    testWidgets('shows plan title and description', (tester) async {
      await tester.pumpWidget(
        testWidget(PlanDetailScreen(plan: planWithSteps)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Quarterly Roadmap'), findsOneWidget);
      expect(find.text('Plan for Q3 objectives'), findsOneWidget);
    });

    testWidgets('shows all steps when plan has steps', (tester) async {
      await tester.pumpWidget(
        testWidget(PlanDetailScreen(plan: planWithSteps)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Research'), findsOneWidget);
      expect(find.text('Design'), findsOneWidget);
      expect(find.text('Build'), findsOneWidget);
      expect(find.text('Ship'), findsOneWidget);
    });

    testWidgets('shows "No steps yet" when plan has no steps', (tester) async {
      await tester.pumpWidget(testWidget(PlanDetailScreen(plan: planNoSteps)));
      await tester.pumpAndSettle();
      expect(find.text('No steps yet'), findsOneWidget);
    });

    testWidgets(
      'shows "No tasks linked to this plan yet" when no tasks linked',
      (tester) async {
        await tester.pumpWidget(
          testWidget(PlanDetailScreen(plan: planWithSteps)),
        );
        await tester.pumpAndSettle();
        expect(find.text('No tasks linked to this plan yet'), findsOneWidget);
      },
    );

    testWidgets('shows all four status choice chips', (tester) async {
      await tester.pumpWidget(
        testWidget(PlanDetailScreen(plan: planWithSteps)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('shows "Add Step" button', (tester) async {
      await tester.pumpWidget(
        testWidget(PlanDetailScreen(plan: planWithSteps)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add Step'), findsOneWidget);
    });

    testWidgets('shows "Add Task" button', (tester) async {
      await tester.pumpWidget(
        testWidget(PlanDetailScreen(plan: planWithSteps)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add Task'), findsOneWidget);
    });

    testWidgets('shows linked task count label', (tester) async {
      await tester.pumpWidget(
        testWidget(PlanDetailScreen(plan: planWithSteps)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Linked Tasks (0)'), findsOneWidget);
    });

    testWidgets('has edit and delete action buttons in AppBar', (tester) async {
      await tester.pumpWidget(
        testWidget(PlanDetailScreen(plan: planWithSteps)),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('shows "Plan Details" in AppBar title', (tester) async {
      await tester.pumpWidget(
        testWidget(PlanDetailScreen(plan: planWithSteps)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Plan Details'), findsOneWidget);
    });

    testWidgets('shows Status section heading', (tester) async {
      await tester.pumpWidget(
        testWidget(PlanDetailScreen(plan: planWithSteps)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets('shows Steps section heading', (tester) async {
      await tester.pumpWidget(
        testWidget(PlanDetailScreen(plan: planWithSteps)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Steps'), findsOneWidget);
    });
  });
}
