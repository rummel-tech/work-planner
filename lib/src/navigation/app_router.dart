import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/plan.dart';
import '../planners/day_planner.dart';
import '../screens/home/home_screen.dart';
import '../screens/goals/goal_detail_screen.dart';
import '../screens/goals/goal_form_screen.dart';
import '../screens/plans/plan_detail_screen.dart';
import '../screens/plans/plan_form_screen.dart';
import '../screens/daily/day_planner_screen.dart';
import '../screens/daily/task_form_screen.dart';
import '../screens/weekly/weekly_planner_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String goalDetail = '/goal';
  static const String goalForm = '/goal/form';
  static const String planDetail = '/plan';
  static const String planForm = '/plan/form';
  static const String dayPlanner = '/day';
  static const String taskForm = '/task/form';
  static const String weeklyPlanner = '/week';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case goalDetail:
        final goal = settings.arguments as Goal;
        return MaterialPageRoute(
          builder: (_) => GoalDetailScreen(goal: goal),
        );

      case goalForm:
        final goal = settings.arguments as Goal?;
        return MaterialPageRoute(
          builder: (_) => GoalFormScreen(goal: goal),
        );

      case planDetail:
        final plan = settings.arguments as Plan;
        return MaterialPageRoute(
          builder: (_) => PlanDetailScreen(plan: plan),
        );

      case planForm:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PlanFormScreen(
            plan: args?['plan'] as Plan?,
            goalId: args?['goalId'] as String?,
          ),
        );

      case dayPlanner:
        final date = settings.arguments as DateTime;
        return MaterialPageRoute(
          builder: (_) => DayPlannerScreen(date: date),
        );

      case taskForm:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => TaskFormScreen(
            task: args['task'] as Task?,
            date: args['date'] as DateTime,
          ),
        );

      case weeklyPlanner:
        final weekStart = settings.arguments as DateTime?;
        return MaterialPageRoute(
          builder: (_) => WeeklyPlannerScreen(initialWeekStart: weekStart),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
