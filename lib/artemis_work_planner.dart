/// Artemis Work Planner - A module for planning and management of work
/// for both corporate and entrepreneurial endeavors.
///
/// This library provides functionality to:
/// - Create and manage goals (corporate and entrepreneurial)
/// - Create plans to achieve those goals
/// - Plan daily tasks with DayPlanner
/// - Plan weekly tasks with WeekPlanner
library artemis_work_planner;

// Models
export 'src/models/goal.dart';
export 'src/models/plan.dart';
export 'src/planners/day_planner.dart';
export 'src/planners/week_planner.dart';

// Services
export 'src/services/database_service.dart';
export 'src/services/goal_repository.dart';
export 'src/services/plan_repository.dart';
export 'src/services/planner_repository.dart';

// Navigation
export 'src/navigation/app_router.dart';

// Screens
export 'src/screens/home/home_screen.dart';
export 'src/screens/goals/goals_screen.dart';
export 'src/screens/goals/goal_detail_screen.dart';
export 'src/screens/goals/goal_form_screen.dart';
export 'src/screens/plans/plans_screen.dart';
export 'src/screens/plans/plan_detail_screen.dart';
export 'src/screens/plans/plan_form_screen.dart';
export 'src/screens/daily/day_planner_screen.dart';
export 'src/screens/daily/task_form_screen.dart';
export 'src/screens/weekly/weekly_planner_screen.dart';

// UI Components
export 'src/ui_components/goal_card.dart';
export 'src/ui_components/plan_card.dart';
export 'src/ui_components/task_tile.dart';
export 'src/ui_components/priority_badge.dart';
export 'src/ui_components/status_chip.dart';
export 'src/ui_components/completion_indicator.dart';
export 'src/ui_components/empty_state.dart';
