import 'package:flutter/material.dart';
import 'package:rummel_blue_theme/rummel_blue_theme.dart';

import 'src/services/database_service.dart';
import 'src/navigation/app_router.dart';
import 'src/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.initialize();
  runApp(const ArtemisWorkPlannerApp());
}

class ArtemisWorkPlannerApp extends StatelessWidget {
  const ArtemisWorkPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Planner',
      theme: RummelBlueTheme.light(),
      darkTheme: RummelBlueTheme.dark(),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
