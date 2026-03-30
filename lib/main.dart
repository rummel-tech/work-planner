import 'package:flutter/material.dart';
import 'package:rummel_blue_theme/rummel_blue_theme.dart';

import 'src/services/api_config.dart';
import 'src/services/api_service.dart';
import 'src/services/auth_service.dart';
import 'src/services/database_service.dart';
import 'src/services/goal_repository.dart';
import 'src/services/plan_repository.dart';
import 'src/services/planner_repository.dart';
import 'src/services/service_locator.dart';
import 'src/navigation/app_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure API base URL (override via env/config in production builds)
  ApiConfig.configure(baseUrl: const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8040',
  ));

  // Wire auth failure callback before any authenticated requests
  final authService = AuthService();
  authService.onAuthFailure = () {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRouter.welcome, (_) => false);
  };

  // Build the API service and inject into repositories
  final apiService = ApiService(authService);
  ServiceLocator.init(
    authService: authService,
    apiService: apiService,
    goalRepo: GoalRepository(api: apiService),
    planRepo: PlanRepository(api: apiService),
    plannerRepo: PlannerRepository(api: apiService),
  );

  // Initialise local sembast database (used as offline cache)
  await DatabaseService.instance.initialize();

  // Determine initial route based on auth state
  final isAuthenticated = await authService.isAuthenticated();

  runApp(ArtemisWorkPlannerApp(initialRoute: isAuthenticated ? AppRouter.home : AppRouter.welcome));
}

class ArtemisWorkPlannerApp extends StatelessWidget {
  final String initialRoute;

  const ArtemisWorkPlannerApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Planner',
      theme: RummelBlueTheme.light(),
      darkTheme: RummelBlueTheme.dark(),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
