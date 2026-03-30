import 'auth_service.dart';
import 'api_service.dart';
import 'goal_repository.dart';
import 'plan_repository.dart';
import 'planner_repository.dart';

/// Simple service locator. Initialised once in main() before runApp().
///
/// Access via [ServiceLocator.auth], [ServiceLocator.goals], etc.
class ServiceLocator {
  ServiceLocator._();

  static late AuthService _auth;
  static late ApiService _api;
  static late GoalRepository _goals;
  static late PlanRepository _plans;
  static late PlannerRepository _planners;

  static void init({
    required AuthService authService,
    required ApiService apiService,
    required GoalRepository goalRepo,
    required PlanRepository planRepo,
    required PlannerRepository plannerRepo,
  }) {
    _auth = authService;
    _api = apiService;
    _goals = goalRepo;
    _plans = planRepo;
    _planners = plannerRepo;
  }

  static AuthService get auth => _auth;
  static ApiService get api => _api;
  static GoalRepository get goals => _goals;
  static PlanRepository get plans => _plans;
  static PlannerRepository get planners => _planners;
}
