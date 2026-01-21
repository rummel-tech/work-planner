import 'package:flutter/material.dart';

import '../../models/goal.dart';
import '../../planners/day_planner.dart';
import '../../planners/week_planner.dart';
import '../../services/goal_repository.dart';
import '../../services/plan_repository.dart';
import '../../services/planner_repository.dart';
import '../../ui_components/completion_indicator.dart';
import '../../ui_components/goal_card.dart';
import '../../ui_components/task_tile.dart';
import '../../navigation/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _goalRepository = GoalRepository();
  final _planRepository = PlanRepository();
  final _plannerRepository = PlannerRepository();

  int _currentIndex = 0;
  List<Goal> _activeGoals = [];
  Map<String, int> _planCounts = {};
  DayPlanner? _todayPlanner;
  WeekPlanner? _currentWeekPlanner;
  double _weekCompletionRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
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

    setState(() {
      _activeGoals = goals;
      _planCounts = planCounts;
      _todayPlanner = todayPlanner;
      _currentWeekPlanner = weekPlanner;
      _weekCompletionRate = weekStats.completionRate;
    });
  }

  Future<void> _toggleTaskCompleted(Task task) async {
    if (_todayPlanner == null) return;

    final updatedTask = task.toggleCompleted();
    final updatedPlanner = _todayPlanner!.updateTask(updatedTask);
    await _plannerRepository.saveDayPlanner(updatedPlanner);
    _loadData();
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekProgress(),
            const SizedBox(height: 24),
            _buildTodayTasks(),
            const SizedBox(height: 24),
            _buildActiveGoals(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CompletionIndicator(
              rate: _weekCompletionRate,
              size: 64,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Week Progress',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentWeekPlanner != null
                        ? '${_currentWeekPlanner!.weeklyGoals.length} weekly goals'
                        : 'No weekly goals',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() => _currentIndex = 2);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTasks() {
    final tasks = _todayPlanner?.tasks ?? [];
    final pendingTasks = tasks.where((t) => !t.completed).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Tasks",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                setState(() => _currentIndex = 3);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (pendingTasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tasks.isEmpty
                          ? 'No tasks for today'
                          : 'All tasks completed!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...pendingTasks.take(3).map((task) => TaskTile(
                task: task,
                onCompletedChanged: (_) => _toggleTaskCompleted(task),
              )),
      ],
    );
  }

  Widget _buildActiveGoals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Goals',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                setState(() => _currentIndex = 1);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_activeGoals.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No active goals',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._activeGoals.take(3).map((goal) => GoalCard(
                goal: goal,
                planCount: _planCounts[goal.id] ?? 0,
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRouter.goalDetail,
                    arguments: goal,
                  );
                  _loadData();
                },
              )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Planner'),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          _GoalsTab(onDataChanged: _loadData),
          _WeeklyTab(onDataChanged: _loadData),
          _TodayTab(onDataChanged: _loadData),
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

class _GoalsTab extends StatelessWidget {
  final VoidCallback onDataChanged;

  const _GoalsTab({required this.onDataChanged});

  @override
  Widget build(BuildContext context) {
    return const _GoalsScreen();
  }
}

class _WeeklyTab extends StatelessWidget {
  final VoidCallback onDataChanged;

  const _WeeklyTab({required this.onDataChanged});

  @override
  Widget build(BuildContext context) {
    return const _WeeklyScreen();
  }
}

class _TodayTab extends StatelessWidget {
  final VoidCallback onDataChanged;

  const _TodayTab({required this.onDataChanged});

  @override
  Widget build(BuildContext context) {
    return const _TodayScreen();
  }
}

class _GoalsScreen extends StatefulWidget {
  const _GoalsScreen();

  @override
  State<_GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<_GoalsScreen>
    with SingleTickerProviderStateMixin {
  final _goalRepository = GoalRepository();
  final _planRepository = PlanRepository();
  late TabController _tabController;
  List<Goal> _allGoals = [];
  Map<String, int> _planCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGoals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final goals = await _goalRepository.getAll();
    final planCounts = <String, int>{};
    for (final goal in goals) {
      planCounts[goal.id] = await _planRepository.countByGoalId(goal.id);
    }
    setState(() {
      _allGoals = goals;
      _planCounts = planCounts;
    });
  }

  List<Goal> _getFilteredGoals(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _allGoals.where((g) => g.type == GoalType.corporate).toList();
      case 2:
        return _allGoals
            .where((g) => g.type == GoalType.entrepreneurial)
            .toList();
      default:
        return _allGoals;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Corporate'),
            Tab(text: 'Entrepreneurial'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGoalList(0),
              _buildGoalList(1),
              _buildGoalList(2),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRouter.goalForm);
                _loadGoals();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Goal'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalList(int tabIndex) {
    final goals = _getFilteredGoals(tabIndex);

    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No goals yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGoals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          return GoalCard(
            goal: goal,
            planCount: _planCounts[goal.id] ?? 0,
            onTap: () async {
              await Navigator.pushNamed(
                context,
                AppRouter.goalDetail,
                arguments: goal,
              );
              _loadGoals();
            },
          );
        },
      ),
    );
  }
}

class _WeeklyScreen extends StatefulWidget {
  const _WeeklyScreen();

  @override
  State<_WeeklyScreen> createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<_WeeklyScreen> {
  final _plannerRepository = PlannerRepository();
  WeekPlanner? _weekPlanner;
  Map<int, DayPlanner> _dayPlanners = {};
  DateTime _currentWeekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initWeekStart();
    _loadWeekPlanner();
  }

  void _initWeekStart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    _currentWeekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));
  }

  Future<void> _loadWeekPlanner() async {
    final planner =
        await _plannerRepository.getOrCreateWeekPlanner(_currentWeekStart);
    final dayPlanners = await _plannerRepository.getDayPlannersForWeek(planner);
    setState(() {
      _weekPlanner = planner;
      _dayPlanners = dayPlanners;
    });
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _loadWeekPlanner();
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _loadWeekPlanner();
  }

  String _formatWeekRange() {
    final end = _currentWeekStart.add(const Duration(days: 6));
    return '${_currentWeekStart.month}/${_currentWeekStart.day} - ${end.month}/${end.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousWeek,
              ),
              Text(
                _formatWeekRange(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextWeek,
              ),
            ],
          ),
        ),
        if (_weekPlanner != null && _weekPlanner!.weeklyGoals.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Goals',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ..._weekPlanner!.weeklyGoals.map((goal) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 8),
                              const SizedBox(width: 8),
                              Expanded(child: Text(goal)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadWeekPlanner,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = _currentWeekStart.add(Duration(days: index));
                final dayPlanner = _dayPlanners[index];
                final taskCount = dayPlanner?.tasks.length ?? 0;
                final completedCount = dayPlanner?.completedTasks.length ?? 0;
                final isToday = DateTime.now().day == date.day &&
                    DateTime.now().month == date.month &&
                    DateTime.now().year == date.year;

                return Card(
                  color: isToday
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                              [index],
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          '${date.day}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    title: Text(
                      taskCount == 0
                          ? 'No tasks'
                          : '$completedCount/$taskCount tasks completed',
                    ),
                    trailing: taskCount > 0
                        ? CircularProgressIndicator(
                            value:
                                taskCount > 0 ? completedCount / taskCount : 0,
                            strokeWidth: 3,
                          )
                        : null,
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRouter.dayPlanner,
                        arguments: date,
                      );
                      _loadWeekPlanner();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayScreen extends StatefulWidget {
  const _TodayScreen();

  @override
  State<_TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<_TodayScreen> {
  final _plannerRepository = PlannerRepository();
  DayPlanner? _todayPlanner;

  @override
  void initState() {
    super.initState();
    _loadTodayPlanner();
  }

  Future<void> _loadTodayPlanner() async {
    final planner =
        await _plannerRepository.getOrCreateDayPlanner(DateTime.now());
    setState(() {
      _todayPlanner = planner;
    });
  }

  Future<void> _toggleTaskCompleted(Task task) async {
    if (_todayPlanner == null) return;

    final updatedTask = task.toggleCompleted();
    final updatedPlanner = _todayPlanner!.updateTask(updatedTask);
    await _plannerRepository.saveDayPlanner(updatedPlanner);
    _loadTodayPlanner();
  }

  Future<void> _deleteTask(Task task) async {
    if (_todayPlanner == null) return;

    final updatedPlanner = _todayPlanner!.removeTask(task.id);
    await _plannerRepository.saveDayPlanner(updatedPlanner);
    _loadTodayPlanner();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _todayPlanner?.tasks ?? [];
    final now = DateTime.now();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${now.month}/${now.day}/${now.year}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (_todayPlanner != null)
                Text(
                  '${_todayPlanner!.completedTasks.length}/${tasks.length} completed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
            ],
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks for today',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the button below to add a task',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTodayPlanner,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskTile(
                        task: task,
                        onCompletedChanged: (_) => _toggleTaskCompleted(task),
                        onDelete: () => _deleteTask(task),
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRouter.taskForm,
                            arguments: {
                              'task': task,
                              'date': DateTime.now(),
                            },
                          );
                          _loadTodayPlanner();
                        },
                      );
                    },
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(
                  context,
                  AppRouter.taskForm,
                  arguments: {'date': DateTime.now()},
                );
                _loadTodayPlanner();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ),
        ),
      ],
    );
  }
}
