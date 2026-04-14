import 'package:artemis_work_planner/src/models/goal.dart';
import 'package:artemis_work_planner/src/screens/goals/goals_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(() {
    mockSecureStorage();
    initTestServices();
  });

  Widget buildScreen() => testWidget(const GoalsScreen());

  group('GoalsScreen', () {
    testWidgets('shows empty state when there are no goals', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No goals yet'), findsWidgets);
      expect(find.text('Create your first goal to get started'), findsWidgets);
    });

    testWidgets('shows All / Corp / Farm / App Dev / Home & Auto tabs', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Corp'), findsOneWidget);
      expect(find.text('Farm'), findsOneWidget);
      expect(find.text('App Dev'), findsOneWidget);
      expect(find.text('Home & Auto'), findsOneWidget);
    });

    testWidgets('shows FAB', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows seeded goals in All tab', (tester) async {
      fakeGoals.seed([
        Goal.create(
          id: 'g1',
          title: 'Launch Product',
          description: 'Ship v1',
          type: GoalType.farm,
        ),
        Goal.create(
          id: 'g2',
          title: 'Q3 OKRs',
          description: 'Corporate goals',
          type: GoalType.corporate,
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Launch Product'), findsOneWidget);
      expect(find.text('Q3 OKRs'), findsOneWidget);
    });

    testWidgets('Corp tab shows only corporate goals', (tester) async {
      fakeGoals.seed([
        Goal.create(
          id: 'g1',
          title: 'Corp Goal',
          description: 'D',
          type: GoalType.corporate,
        ),
        Goal.create(
          id: 'g2',
          title: 'Farm Goal',
          description: 'D',
          type: GoalType.farm,
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Corp'));
      await tester.pumpAndSettle();

      expect(find.text('Corp Goal'), findsOneWidget);
      expect(find.text('Farm Goal'), findsNothing);
    });

    testWidgets('Farm tab shows only farm goals', (
      tester,
    ) async {
      fakeGoals.seed([
        Goal.create(
          id: 'g1',
          title: 'Corp Goal',
          description: 'D',
          type: GoalType.corporate,
        ),
        Goal.create(
          id: 'g2',
          title: 'Farm Goal',
          description: 'D',
          type: GoalType.farm,
        ),
      ]);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Farm'));
      await tester.pumpAndSettle();

      expect(find.text('Farm Goal'), findsOneWidget);
      expect(find.text('Corp Goal'), findsNothing);
    });
  });
}
