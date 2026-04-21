import 'package:flutter/material.dart';

import '../../models/goal.dart';
import '../../navigation/app_router.dart';
import '../../planners/day_planner.dart';
import '../../planners/week_planner.dart';
import '../../services/connectivity_notifier.dart';
import '../../services/service_locator.dart';
import '../daily/day_planner_screen.dart';
import '../goals/goals_screen.dart';
import '../weekly/weekly_planner_screen.dart';
import 'corp_tab.dart';
import 'home_auto_tab.dart';
import 'side_hustle_tab.dart';
import 'widgets.dart';

// ============================================================================
// HomeScreen — root scaffold with bottom nav
// ============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _goalRepository = ServiceLocator.goals;
  final _planRepository = ServiceLocator.plans;
  final _plannerRepository = ServiceLocator.planners;

  int _currentIndex = 0;
  late TabController _dashboardTabController;

  List<Goal> _activeGoals = [];
  Map<String, int> _planCounts = {};
  DayPlanner? _todayPlanner;
  WeekPlanner? _currentWeekPlanner;
  double _weekCompletionRate = 0.0;

  @override
  void initState() {
    super.initState();
    _dashboardTabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _dashboardTabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final goals = await _goalRepository.getActive();
    final planCounts = <String, int>{};
    for (final goal in goals) {
      planCounts[goal.id] = await _planRepository.countByGoalId(goal.id);
    }

    final today = DateTime.now();
    final todayPlanner = await _plannerRepository.getOrCreateDayPlanner(today);
    final weekPlanner = await _plannerRepository.getCurrentWeekPlanner();
    final weekStats = await _plannerRepository.getWeekStats(weekPlanner);

    if (!mounted) return;
    setState(() {
      _activeGoals = goals;
      _planCounts = planCounts;
      _todayPlanner = todayPlanner;
      _currentWeekPlanner = weekPlanner;
      _weekCompletionRate = weekStats.completionRate;
    });
  }

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------

  Widget _buildDashboard() {
    final corpGoals = _activeGoals
        .where((g) => g.type == GoalType.corporate)
        .toList();
    final farmGoals = _activeGoals
        .where((g) => g.type == GoalType.farm)
        .toList();
    final appDevGoals = _activeGoals
        .where((g) => g.type == GoalType.appDevelopment)
        .toList();
    final homeAutoGoals = _activeGoals
        .where((g) => g.type == GoalType.homeAuto)
        .toList();

    return Column(
      children: [
        // Week progress — always visible above the tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: WeekProgressCard(
            completionRate: _weekCompletionRate,
            weeklyGoalCount: _currentWeekPlanner?.weeklyGoals.length ?? 0,
            onTap: () async {
              await Navigator.pushNamed(context, AppRouter.weeklyPlanner);
              _loadData();
            },
          ),
        ),
        const SizedBox(height: 4),
        TabBar(
          controller: _dashboardTabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Corp'),
            Tab(text: 'Farm'),
            Tab(text: 'App Dev'),
            Tab(text: 'Home & Auto'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _dashboardTabController,
            children: [
              CorpTab(
                goals: corpGoals,
                planCounts: _planCounts,
                todayPlanner: _todayPlanner,
                onRefresh: _loadData,
                onGoalsTabTap: () => setState(() => _currentIndex = 1),
              ),
              SideHustleTab(
                goalType: GoalType.farm,
                taskCategory: TaskCategory.farm,
                goals: farmGoals,
                planCounts: _planCounts,
                todayPlanner: _todayPlanner,
                onRefresh: _loadData,
                onGoalsTabTap: () => setState(() => _currentIndex = 1),
              ),
              SideHustleTab(
                goalType: GoalType.appDevelopment,
                taskCategory: TaskCategory.appDevelopment,
                goals: appDevGoals,
                planCounts: _planCounts,
                todayPlanner: _todayPlanner,
                onRefresh: _loadData,
                onGoalsTabTap: () => setState(() => _currentIndex = 1),
              ),
              HomeAutoTab(
                goals: homeAutoGoals,
                planCounts: _planCounts,
                onRefresh: _loadData,
                onGoalsTabTap: () => setState(() => _currentIndex = 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Work Planner')),
      body: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: ConnectivityNotifier.isOffline,
            builder: (context, isOffline, _) {
              if (!isOffline) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: Colors.orange.shade100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Offline — showing cached data',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboard(),
                const GoalsScreen(embedded: true),
                const WeeklyPlannerScreen(embedded: true),
                DayPlannerScreen(
                  date: DateTime(now.year, now.month, now.day),
                  embedded: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          _loadData();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: 'Week',
          ),
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
        ],
      ),
    );
  }
}
