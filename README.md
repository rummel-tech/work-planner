# Artemis Work Planner

A comprehensive work planning and management module for both corporate and entrepreneurial endeavors. This Dart library enables you to create goals, develop plans to achieve those goals, and organize your work with daily and weekly planners.

## Features

- **Goal Management**: Create and track both corporate and entrepreneurial goals with target dates and status tracking
- **Plan Creation**: Develop detailed plans with actionable steps to achieve your goals
- **Day Planner**: Organize daily tasks with priorities, schedules, and completion tracking
- **Week Planner**: Plan your week with daily planners and weekly goals
- **Progress Tracking**: Monitor completion rates for both daily and weekly activities

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  artemis_work_planner:
    path: .
```

Then run:

```bash
dart pub get
```

## Usage

### Creating Goals

```dart
import 'package:artemis_work_planner/artemis_work_planner.dart';

// Create a corporate goal
final corporateGoal = Goal(
  title: 'Launch Product X',
  description: 'Successfully launch our new product line',
  type: GoalType.corporate,
  targetDate: DateTime(2026, 6, 30),
);

// Create an entrepreneurial goal
final entrepreneurialGoal = Goal(
  title: 'Start Consulting Business',
  description: 'Launch independent consulting practice',
  type: GoalType.entrepreneurial,
);
```

### Creating Plans

```dart
final plan = Plan(
  title: 'Product Launch Plan',
  description: 'Detailed plan for product launch',
  goalId: corporateGoal.id,
  startDate: DateTime(2026, 3, 1),
  endDate: DateTime(2026, 6, 30),
  steps: [
    'Finalize specifications',
    'Complete development',
    'Conduct testing',
    'Launch to market',
  ],
  status: PlanStatus.active,
);
```

### Using Day Planner

```dart
var dayPlanner = DayPlanner(
  date: DateTime.now(),
  notes: 'Focus on important tasks',
);

// Add tasks
dayPlanner = dayPlanner.addTask(Task(
  title: 'Team meeting',
  scheduledTime: DateTime(2026, 1, 20, 10, 0),
  durationMinutes: 60,
  priority: TaskPriority.high,
));

// Mark task as completed
final task = dayPlanner.tasks.first;
final completedTask = task.toggleCompleted();
dayPlanner = dayPlanner.updateTask(completedTask);

// Check progress
print('Completion Rate: ${dayPlanner.completionRate}');
```

### Using Week Planner

```dart
var weekPlanner = WeekPlanner(
  weekStartDate: DateTime(2026, 1, 19),
  weeklyGoals: [
    'Complete sprint',
    'Prepare presentation',
  ],
);

// Add daily planners
weekPlanner = weekPlanner.addDailyPlanner(0, mondayPlanner);
weekPlanner = weekPlanner.addDailyPlanner(1, tuesdayPlanner);

// Track weekly progress
print('Week Completion: ${weekPlanner.weekCompletionRate}');
```

## Example

Run the example to see all features in action:

```bash
dart run example/example.dart
```

## Testing

Run all tests:

```bash
dart test
```

## License

See LICENSE file for details.