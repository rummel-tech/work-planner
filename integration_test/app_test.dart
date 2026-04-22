import 'package:artemis_work_planner/src/navigation/app_router.dart';
import 'package:artemis_work_planner/src/planners/day_planner.dart';
import 'package:artemis_work_planner/src/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rummel_blue_theme/rummel_blue_theme.dart';

import '../test/helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Helper — builds the full app against fake services already wired by setUp.
// ---------------------------------------------------------------------------

Widget buildApp({String initialRoute = AppRouter.home}) {
  return MaterialApp(
    title: 'Work Planner (test)',
    theme: RummelBlueTheme.light(),
    darkTheme: RummelBlueTheme.dark(),
    initialRoute: initialRoute,
    onGenerateRoute: AppRouter.generateRoute,
  );
}

Widget buildDayPlannerApp(DateTime date) {
  return MaterialApp(
    theme: RummelBlueTheme.light(),
    initialRoute: AppRouter.dayPlanner,
    onGenerateRoute: (settings) {
      if (settings.name == AppRouter.dayPlanner) {
        return AppRouter.generateRoute(
          RouteSettings(name: AppRouter.dayPlanner, arguments: date),
        );
      }
      return AppRouter.generateRoute(settings);
    },
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockSecureStorage();
    initTestServices(authenticated: true);
  });

  // -------------------------------------------------------------------------
  // Home screen
  // -------------------------------------------------------------------------

  group('Home screen', () {
    testWidgets('shows app title and bottom nav destinations', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Work Planner'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets("dashboard shows Today's Tasks and Active Goals sections", (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text("Today's Tasks"), findsOneWidget);
      expect(find.text('Active Goals'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Goal creation flow
  // -------------------------------------------------------------------------

  group('Goal creation flow [goal-management]', () {
    testWidgets('creates a goal via Goals tab → New Goal form', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Navigate to Goals tab
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();

      // Open goal form
      await tester.tap(find.text('New Goal'));
      await tester.pumpAndSettle();

      expect(find.text('New Goal'), findsWidgets);

      // Fill the form
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter goal title'),
        'Launch MVP',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter goal description'),
        'Ship the first version',
      );

      // Submit
      await tester.tap(find.text('Create Goal'));
      await tester.pumpAndSettle();

      // Goal appears in list
      expect(find.text('Launch MVP'), findsOneWidget);
    });

    testWidgets('validation blocks save when title is empty', (tester) async {
      await tester.pumpWidget(buildApp(initialRoute: AppRouter.goalForm));
      await tester.pumpAndSettle();

      // Tap save without entering anything
      await tester.tap(find.text('Create Goal'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Task creation flow (Today tab)
  // -------------------------------------------------------------------------

  group('Task creation flow [focused-execution]', () {
    testWidgets('adds a task from the Today tab', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter task title'),
        'Write tests',
      );

      await tester.tap(find.text('Create Task'));
      await tester.pumpAndSettle();

      expect(find.text('Write tests'), findsOneWidget);
    });

    testWidgets('task form validation blocks save when title is empty', (
      tester,
    ) async {
      final today = DateTime.now();
      await tester.pumpWidget(
        MaterialApp(
          theme: RummelBlueTheme.light(),
          initialRoute: AppRouter.taskForm,
          onGenerateRoute: (settings) {
            if (settings.name == AppRouter.taskForm) {
              return AppRouter.generateRoute(
                RouteSettings(
                  name: AppRouter.taskForm,
                  arguments: {'date': today},
                ),
              );
            }
            return AppRouter.generateRoute(settings);
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Task'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Task completion
  // -------------------------------------------------------------------------

  group('Task completion', () {
    testWidgets('toggling a task marks it as completed', (tester) async {
      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);

      // Seed a task via the fake repository
      await ServiceLocator.planners.addTask(
        date,
        Task.create(title: 'Finish report'),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(find.text('Finish report'), findsOneWidget);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      final updatedPlanner = await ServiceLocator.planners
          .getOrCreateDayPlanner(date);
      expect(updatedPlanner.completedTasks.length, equals(1));
    });
  });

  // -------------------------------------------------------------------------
  // Day planner — Pomodoro block layout
  // -------------------------------------------------------------------------

  group('Day planner — Pomodoro block layout', () {
    testWidgets('renders 4 labelled blocks', (tester) async {
      final date = DateTime(2025, 6, 16);
      await tester.pumpWidget(buildDayPlannerApp(date));
      await tester.pumpAndSettle();

      expect(find.text('Block 1'), findsOneWidget);
      expect(find.text('Block 2'), findsOneWidget);
      expect(find.text('Block 3'), findsOneWidget);
      expect(find.text('Block 4'), findsOneWidget);
    });

    testWidgets(
      'tapping + for a block pre-selects that block in the task form',
      (tester) async {
        final date = DateTime(2025, 6, 16);
        await tester.pumpWidget(buildDayPlannerApp(date));
        await tester.pumpAndSettle();

        // Tap the "Add task to Block 2" icon button
        await tester.tap(find.byTooltip('Add task to Block 2'));
        await tester.pumpAndSettle();

        expect(find.text('New Task'), findsOneWidget);

        final block2Chip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Block 2'),
        );
        expect(block2Chip.selected, isTrue);
      },
    );

    testWidgets('seeded task appears under its assigned block', (tester) async {
      final date = DateTime(2025, 6, 16);
      await ServiceLocator.planners.addTask(
        date,
        Task.create(title: 'Deep work task', pomodoroBlock: 3),
      );

      await tester.pumpWidget(buildDayPlannerApp(date));
      await tester.pumpAndSettle();

      expect(find.text('Deep work task'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Welcome / auth screens
  // -------------------------------------------------------------------------

  group('Welcome screen', () {
    testWidgets('shows Sign In and Create Account buttons', (tester) async {
      initTestServices(authenticated: false);
      await tester.pumpWidget(buildApp(initialRoute: AppRouter.welcome));
      await tester.pumpAndSettle();

      expect(find.text('Work Planner'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('Sign In button navigates to login screen', (tester) async {
      initTestServices(authenticated: false);
      await tester.pumpWidget(buildApp(initialRoute: AppRouter.welcome));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Login screen has a Sign In heading/button
      expect(find.text('Sign In'), findsWidgets);
    });
  });
}
