import 'package:artemis_work_planner/src/models/goal.dart';
import 'package:artemis_work_planner/src/screens/goals/goal_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(() {
    mockSecureStorage();
    initTestServices();
  });

  group('GoalFormScreen — create mode', () {
    Widget buildScreen() => testWidget(const GoalFormScreen());

    testWidgets('shows "New Goal" in the AppBar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('New Goal'), findsOneWidget);
    });

    testWidgets('shows title and description form fields', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Title'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Description'), findsOneWidget);
    });

    testWidgets('shows Corporate and Entrepreneurial type segments',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Corporate'), findsOneWidget);
      expect(find.text('Entrepreneurial'), findsOneWidget);
    });

    testWidgets('shows status choice chips', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Not Started'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Abandoned'), findsOneWidget);
    });

    testWidgets('shows "Create Goal" submit button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Create Goal'), findsOneWidget);
    });

    testWidgets('shows target date section with "No date selected"',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Target Date'), findsOneWidget);
      expect(find.text('No date selected'), findsOneWidget);
    });

    testWidgets('shows title validation error when title is empty',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Goal'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a title'), findsOneWidget);
    });

    testWidgets('shows description validation error when description is empty',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), 'My Goal');
      await tester.tap(find.text('Create Goal'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a description'), findsOneWidget);
    });
  });

  group('GoalFormScreen — edit mode', () {
    final existingGoal = Goal.create(
      id: 'g1',
      title: 'Existing Goal',
      description: 'Already saved',
      type: GoalType.entrepreneurial,
      status: GoalStatus.inProgress,
    );

    Widget buildScreen() => testWidget(GoalFormScreen(goal: existingGoal));

    testWidgets('shows "Edit Goal" in the AppBar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Edit Goal'), findsOneWidget);
    });

    testWidgets('pre-fills title and description from the existing goal',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Existing Goal'), findsOneWidget);
      expect(find.text('Already saved'), findsOneWidget);
    });

    testWidgets('shows "Save Changes" submit button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });
}
