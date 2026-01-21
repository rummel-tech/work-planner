import 'package:artemis_work_planner/src/models/goal.dart';
import 'package:artemis_work_planner/src/models/plan.dart';
import 'package:artemis_work_planner/src/planners/day_planner.dart';
import 'package:artemis_work_planner/src/planners/week_planner.dart';

void main() {
  print('=== Artemis Work Planner Example ===\n');

  // 1. Create Goals
  print('1. Creating Goals:');
  final corporateGoal = Goal.create(
    title: 'Launch Product X',
    description: 'Successfully launch our new product line by Q2 2026',
    type: GoalType.corporate,
    targetDate: DateTime(2026, 6, 30),
  );
  print('   Corporate Goal: ${corporateGoal.title}');

  final entrepreneurialGoal = Goal.create(
    title: 'Start Consulting Business',
    description: 'Launch independent consulting practice',
    type: GoalType.entrepreneurial,
    targetDate: DateTime(2026, 12, 31),
  );
  print('   Entrepreneurial Goal: ${entrepreneurialGoal.title}\n');

  // 2. Create Plans
  print('2. Creating Plans:');
  final productLaunchPlan = Plan.create(
    title: 'Product X Launch Plan',
    description: 'Detailed plan for product launch',
    goalId: corporateGoal.id,
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 6, 30),
    steps: [
      'Finalize product specifications',
      'Complete development',
      'Conduct beta testing',
      'Prepare marketing materials',
      'Train sales team',
      'Launch to market',
    ],
    status: PlanStatus.active,
  );
  print('   Plan: ${productLaunchPlan.title}');
  print('   Steps: ${productLaunchPlan.steps.length}\n');

  // 3. Create Day Planner
  print('3. Creating Day Planner:');
  final today = DateTime(2026, 1, 20);
  var dayPlanner = DayPlanner.create(
    date: today,
    notes: 'Focus on product development today',
  );

  // Add tasks to the day
  dayPlanner = dayPlanner.addTask(
    Task.create(
      title: 'Review product specifications',
      scheduledTime: DateTime(2026, 1, 20, 9, 0),
      durationMinutes: 60,
      priority: TaskPriority.high,
      planId: productLaunchPlan.id,
    ),
  );

  dayPlanner = dayPlanner.addTask(
    Task.create(
      title: 'Team standup meeting',
      scheduledTime: DateTime(2026, 1, 20, 10, 0),
      durationMinutes: 30,
      priority: TaskPriority.medium,
    ),
  );

  dayPlanner = dayPlanner.addTask(
    Task.create(
      title: 'Code review session',
      scheduledTime: DateTime(2026, 1, 20, 14, 0),
      durationMinutes: 90,
      priority: TaskPriority.high,
    ),
  );

  print('   Date: ${dayPlanner.date.toIso8601String().split('T')[0]}');
  print('   Tasks: ${dayPlanner.tasks.length}');
  print('   Notes: ${dayPlanner.notes}\n');

  // Mark some tasks as completed
  final completedTask = dayPlanner.tasks[1].toggleCompleted();
  dayPlanner = dayPlanner.updateTask(completedTask);

  print('   Completed: ${dayPlanner.completedTasks.length}');
  print('   Pending: ${dayPlanner.pendingTasks.length}');
  print('   Completion Rate: ${(dayPlanner.completionRate * 100).toStringAsFixed(1)}%\n');

  // 4. Create Week Planner
  print('4. Creating Week Planner:');
  final weekStart = DateTime(2026, 1, 19); // Monday
  var weekPlanner = WeekPlanner.create(
    weekStartDate: weekStart,
    weeklyGoals: [
      'Complete product specification review',
      'Finish development sprint',
      'Prepare for beta testing',
    ],
    notes: 'Critical week for product development',
  );

  // Add daily planners for the week (stores references by ID)
  weekPlanner = weekPlanner.addDailyPlannerEntry(0, dayPlanner.id);

  final tuesdayPlanner = DayPlanner.create(
    date: weekStart.add(const Duration(days: 1)),
  );
  weekPlanner = weekPlanner.addDailyPlannerEntry(1, tuesdayPlanner.id);

  print('   Week: ${weekPlanner.weekStartDate.toIso8601String().split('T')[0]} to ${weekPlanner.weekEndDate.toIso8601String().split('T')[0]}');
  print('   Daily Planner Entries: ${weekPlanner.dailyPlannerEntries.length}');
  print('   Weekly Goals: ${weekPlanner.weeklyGoals.length}\n');

  // 5. Update Goal Status
  print('5. Updating Goal Status:');
  final updatedGoal = corporateGoal.copyWith(status: GoalStatus.inProgress);
  print('   ${updatedGoal.title} - Status: ${updatedGoal.status}\n');

  print('=== Example Complete ===');
}
