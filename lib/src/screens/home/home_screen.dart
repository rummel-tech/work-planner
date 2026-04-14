import 'package:flutter/material.dart';

import '../../models/external_task.dart';
import '../../models/goal.dart';
import '../../navigation/app_router.dart';
import '../../planners/day_planner.dart';
import '../../planners/week_planner.dart';
import '../../services/connectivity_notifier.dart';
import '../../services/service_locator.dart';
import '../../ui_components/completion_indicator.dart';
import '../../ui_components/goal_card.dart';
import '../../ui_components/task_tile.dart';

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
          child: _buildWeekProgress(),
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
              _CorpTab(
                goals: corpGoals,
                planCounts: _planCounts,
                todayPlanner: _todayPlanner,
                onRefresh: _loadData,
                onGoalsTabTap: () => setState(() => _currentIndex = 1),
              ),
              _SideHustleTab(
                goalType: GoalType.farm,
                taskCategory: TaskCategory.farm,
                goals: farmGoals,
                planCounts: _planCounts,
                todayPlanner: _todayPlanner,
                onRefresh: _loadData,
                onGoalsTabTap: () => setState(() => _currentIndex = 1),
              ),
              _SideHustleTab(
                goalType: GoalType.appDevelopment,
                taskCategory: TaskCategory.appDevelopment,
                goals: appDevGoals,
                planCounts: _planCounts,
                todayPlanner: _todayPlanner,
                onRefresh: _loadData,
                onGoalsTabTap: () => setState(() => _currentIndex = 1),
              ),
              _HomeAutoTab(
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

  Widget _buildWeekProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CompletionIndicator(rate: _weekCompletionRate, size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Week Progress',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
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
              onPressed: () async {
                await Navigator.pushNamed(context, AppRouter.weeklyPlanner);
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
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
                _GoalsTab(onDataChanged: _loadData),
                _WeeklyTab(onDataChanged: _loadData),
                _TodayTab(onDataChanged: _loadData),
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

// ============================================================================
// Compact goal card used in the 3-across goals row
// ============================================================================

class _CompactGoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;

  const _CompactGoalCard({required this.goal, this.onTap});

  IconData get _icon {
    switch (goal.type) {
      case GoalType.corporate:
        return Icons.business;
      case GoalType.farm:
        return Icons.agriculture;
      case GoalType.appDevelopment:
        return Icons.code;
      case GoalType.homeAuto:
        return Icons.home;
    }
  }

  Color _color(BuildContext context) {
    switch (goal.type) {
      case GoalType.corporate:
        return Theme.of(context).colorScheme.primary;
      case GoalType.farm:
        return Colors.green.shade700;
      case GoalType.appDevelopment:
        return Colors.orange.shade700;
      case GoalType.homeAuto:
        return Colors.purple.shade600;
    }
  }

  Color _statusDot(BuildContext context) {
    switch (goal.status) {
      case GoalStatus.inProgress:
        return Colors.green;
      case GoalStatus.notStarted:
        return Theme.of(context).colorScheme.outline;
      case GoalStatus.completed:
        return Colors.blue;
      case GoalStatus.abandoned:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(_icon, size: 14, color: color),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _statusDot(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                goal.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Goals row — reused in every dashboard tab
// ============================================================================

class _GoalsRow extends StatelessWidget {
  final List<Goal> goals;
  final Map<String, int> planCounts;
  final VoidCallback onViewAll;
  final Future<void> Function(Goal) onGoalTap;

  const _GoalsRow({
    required this.goals,
    required this.planCounts,
    required this.onViewAll,
    required this.onGoalTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Goals', style: theme.textTheme.titleSmall),
            TextButton(onPressed: onViewAll, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 6),
        if (goals.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No active goals',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Row(
            children: goals.take(3).map((goal) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _CompactGoalCard(
                    goal: goal,
                    onTap: () => onGoalTap(goal),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ============================================================================
// Pomodoro block card — used in Corp tab
// ============================================================================

class _PomodoroBlockCard extends StatelessWidget {
  final int block;
  final List<Task> tasks;
  final VoidCallback onAddTask;
  final Future<void> Function(Task) onToggleTask;
  final Future<void> Function(Task) onEditTask;

  const _PomodoroBlockCard({
    required this.block,
    required this.tasks,
    required this.onAddTask,
    required this.onToggleTask,
    required this.onEditTask,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = tasks.where((t) => t.completed).length;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            leading: const Text('🍅', style: TextStyle(fontSize: 18)),
            title: Text(
              'Block $block',
              style: theme.textTheme.titleSmall,
            ),
            subtitle: tasks.isEmpty
                ? null
                : Text(
                    '$done/${tasks.length} done',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add task to block $block',
              onPressed: onAddTask,
            ),
          ),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'No tasks assigned — tap + to add',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...tasks.map(
              (task) => TaskTile(
                task: task,
                onCompletedChanged: (_) => onToggleTask(task),
                onTap: () => onEditTask(task),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ============================================================================
// Corp tab — pomodoro blocks + corporate goals
// ============================================================================

class _CorpTab extends StatefulWidget {
  final List<Goal> goals;
  final Map<String, int> planCounts;
  final DayPlanner? todayPlanner;
  final Future<void> Function() onRefresh;
  final VoidCallback onGoalsTabTap;

  const _CorpTab({
    required this.goals,
    required this.planCounts,
    required this.todayPlanner,
    required this.onRefresh,
    required this.onGoalsTabTap,
  });

  @override
  State<_CorpTab> createState() => _CorpTabState();
}

class _CorpTabState extends State<_CorpTab>
    with AutomaticKeepAliveClientMixin {
  final _plannerRepository = ServiceLocator.planners;

  @override
  bool get wantKeepAlive => true;

  Future<void> _toggleTask(Task task) async {
    await _plannerRepository.updateTask(DateTime.now(), task.toggleCompleted());
    widget.onRefresh();
  }

  Future<void> _addTaskToBlock(int block) async {
    await Navigator.pushNamed(
      context,
      AppRouter.taskForm,
      arguments: {
        'date': DateTime.now(),
        'pomodoroBlock': block,
        'taskCategory': TaskCategory.corporate,
      },
    );
    widget.onRefresh();
  }

  Future<void> _editTask(Task task) async {
    await Navigator.pushNamed(
      context,
      AppRouter.taskForm,
      arguments: {'task': task, 'date': DateTime.now()},
    );
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final corpTasks = (widget.todayPlanner?.tasks ?? [])
        .where((t) => t.effectiveCategory == TaskCategory.corporate)
        .toList();
    final done = corpTasks.where((t) => t.completed).length;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _GoalsRow(
            goals: widget.goals,
            planCounts: widget.planCounts,
            onViewAll: widget.onGoalsTabTap,
            onGoalTap: (goal) async {
              await Navigator.pushNamed(
                context,
                AppRouter.goalDetail,
                arguments: goal,
              );
              widget.onRefresh();
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Pomodoros",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '$done/${corpTasks.length} done',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int block = 1; block <= 4; block++) ...[
            _PomodoroBlockCard(
              block: block,
              tasks: corpTasks
                  .where((t) => t.pomodoroBlock == block)
                  .toList(),
              onAddTask: () => _addTaskToBlock(block),
              onToggleTask: _toggleTask,
              onEditTask: _editTask,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// Side hustle tab — Farm or App Dev
// ============================================================================

class _SideHustleTab extends StatefulWidget {
  final GoalType goalType;
  final TaskCategory taskCategory;
  final List<Goal> goals;
  final Map<String, int> planCounts;
  final DayPlanner? todayPlanner;
  final Future<void> Function() onRefresh;
  final VoidCallback onGoalsTabTap;

  const _SideHustleTab({
    required this.goalType,
    required this.taskCategory,
    required this.goals,
    required this.planCounts,
    required this.todayPlanner,
    required this.onRefresh,
    required this.onGoalsTabTap,
  });

  @override
  State<_SideHustleTab> createState() => _SideHustleTabState();
}

class _SideHustleTabState extends State<_SideHustleTab>
    with AutomaticKeepAliveClientMixin {
  final _plannerRepository = ServiceLocator.planners;

  @override
  bool get wantKeepAlive => true;

  Future<void> _toggleTask(Task task) async {
    await _plannerRepository.updateTask(DateTime.now(), task.toggleCompleted());
    widget.onRefresh();
  }

  Future<void> _deleteTask(Task task) async {
    await _plannerRepository.removeTask(DateTime.now(), task.id);
    widget.onRefresh();
  }

  Future<void> _addTask() async {
    await Navigator.pushNamed(
      context,
      AppRouter.taskForm,
      arguments: {
        'date': DateTime.now(),
        'taskCategory': widget.taskCategory,
      },
    );
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final tasks = (widget.todayPlanner?.tasks ?? [])
        .where((t) => t.effectiveCategory == widget.taskCategory)
        .toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _GoalsRow(
            goals: widget.goals,
            planCounts: widget.planCounts,
            onViewAll: widget.onGoalsTabTap,
            onGoalTap: (goal) async {
              await Navigator.pushNamed(
                context,
                AppRouter.goalDetail,
                arguments: goal,
              );
              widget.onRefresh();
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Tasks",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${tasks.where((t) => t.completed).length}/${tasks.length} done',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 40,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No tasks for today',
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
            ...tasks.map(
              (task) => TaskTile(
                task: task,
                onCompletedChanged: (_) => _toggleTask(task),
                onDelete: () => _deleteTask(task),
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRouter.taskForm,
                    arguments: {'task': task, 'date': DateTime.now()},
                  );
                  widget.onRefresh();
                },
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addTask,
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Home & Auto tab — external tasks + homeAuto goals
// ============================================================================

class _HomeAutoTab extends StatefulWidget {
  final List<Goal> goals;
  final Map<String, int> planCounts;
  final Future<void> Function() onRefresh;
  final VoidCallback onGoalsTabTap;

  const _HomeAutoTab({
    required this.goals,
    required this.planCounts,
    required this.onRefresh,
    required this.onGoalsTabTap,
  });

  @override
  State<_HomeAutoTab> createState() => _HomeAutoTabState();
}

class _HomeAutoTabState extends State<_HomeAutoTab>
    with AutomaticKeepAliveClientMixin {
  final _externalTaskService = ServiceLocator.externalTasks;

  List<ExternalTask> _homeTasks = [];
  List<ExternalTask> _vehicleTasks = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadExternalTasks();
  }

  Future<void> _loadExternalTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _externalTaskService.getHomeManagerTasks(),
        _externalTaskService.getVehicleManagerTasks(),
      ]);
      if (!mounted) return;
      setState(() {
        _homeTasks = results[0];
        _vehicleTasks = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_loadExternalTasks(), widget.onRefresh()]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _GoalsRow(
            goals: widget.goals,
            planCounts: widget.planCounts,
            onViewAll: widget.onGoalsTabTap,
            onGoalTap: (goal) async {
              await Navigator.pushNamed(
                context,
                AppRouter.goalDetail,
                arguments: goal,
              );
              widget.onRefresh();
            },
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Could not reach external services. Pull down to retry.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _ExternalTaskSection(
              title: 'Home',
              icon: Icons.home,
              color: Colors.purple.shade600,
              tasks: _homeTasks,
            ),
            const SizedBox(height: 12),
            _ExternalTaskSection(
              title: 'Vehicle',
              icon: Icons.directions_car,
              color: Colors.teal.shade600,
              tasks: _vehicleTasks,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// External task section (Home or Vehicle)
// ============================================================================

class _ExternalTaskSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<ExternalTask> tasks;

  const _ExternalTaskSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.tasks,
  });

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(width: 8),
            Text(
              '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (tasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Text(
                'No pending tasks',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ...tasks.map((task) {
            final overdue = task.isOverdue;
            return Card(
              child: ListTile(
                leading: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  task.title,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: task.dueDate != null
                    ? Text(
                        overdue
                            ? 'Overdue: ${_formatDate(task.dueDate!)}'
                            : 'Due: ${_formatDate(task.dueDate!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: overdue ? Colors.red : theme.colorScheme.outline,
                        ),
                      )
                    : null,
                trailing: Chip(
                  label: Text(task.category),
                  labelStyle: theme.textTheme.labelSmall,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';
}

// ============================================================================
// Bottom-nav tab wrappers
// ============================================================================

class _GoalsTab extends StatelessWidget {
  final VoidCallback onDataChanged;
  const _GoalsTab({required this.onDataChanged});

  @override
  Widget build(BuildContext context) => _GoalsScreen(onDataChanged: onDataChanged);
}

class _WeeklyTab extends StatelessWidget {
  final VoidCallback onDataChanged;
  const _WeeklyTab({required this.onDataChanged});

  @override
  Widget build(BuildContext context) => const _WeeklyScreen();
}

class _TodayTab extends StatelessWidget {
  final VoidCallback onDataChanged;
  const _TodayTab({required this.onDataChanged});

  @override
  Widget build(BuildContext context) => const _TodayScreen();
}

// ============================================================================
// Goals screen (bottom nav tab) — 5 filter tabs
// ============================================================================

class _GoalsScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;
  const _GoalsScreen({this.onDataChanged});

  @override
  State<_GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<_GoalsScreen>
    with SingleTickerProviderStateMixin {
  final _goalRepository = ServiceLocator.goals;
  final _planRepository = ServiceLocator.plans;
  late TabController _tabController;
  List<Goal> _allGoals = [];
  Map<String, int> _planCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        return _allGoals.where((g) => g.type == GoalType.farm).toList();
      case 3:
        return _allGoals
            .where((g) => g.type == GoalType.appDevelopment)
            .toList();
      case 4:
        return _allGoals.where((g) => g.type == GoalType.homeAuto).toList();
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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Corp'),
            Tab(text: 'Farm'),
            Tab(text: 'App Dev'),
            Tab(text: 'Home & Auto'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              for (int i = 0; i < 5; i++) _buildGoalList(i),
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

// ============================================================================
// Weekly screen (bottom nav tab)
// ============================================================================

class _WeeklyScreen extends StatefulWidget {
  const _WeeklyScreen();

  @override
  State<_WeeklyScreen> createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<_WeeklyScreen> {
  final _plannerRepository = ServiceLocator.planners;
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
    _currentWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: weekday - 1));
  }

  Future<void> _loadWeekPlanner() async {
    final planner = await _plannerRepository.getOrCreateWeekPlanner(
      _currentWeekStart,
    );
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
                    ..._weekPlanner!.weeklyGoals.map(
                      (goal) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8),
                            const SizedBox(width: 8),
                            Expanded(child: Text(goal)),
                          ],
                        ),
                      ),
                    ),
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
                final isToday =
                    DateTime.now().day == date.day &&
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
                          [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ][index],
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
                            value: taskCount > 0
                                ? completedCount / taskCount
                                : 0,
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

// ============================================================================
// Today screen (bottom nav tab)
// ============================================================================

class _TodayScreen extends StatefulWidget {
  const _TodayScreen();

  @override
  State<_TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<_TodayScreen> {
  final _plannerRepository = ServiceLocator.planners;
  DayPlanner? _todayPlanner;

  @override
  void initState() {
    super.initState();
    _loadTodayPlanner();
  }

  Future<void> _loadTodayPlanner() async {
    final planner = await _plannerRepository.getOrCreateDayPlanner(
      DateTime.now(),
    );
    setState(() {
      _todayPlanner = planner;
    });
  }

  Future<void> _toggleTaskCompleted(Task task) async {
    if (_todayPlanner == null) return;
    await _plannerRepository.updateTask(DateTime.now(), task.toggleCompleted());
    _loadTodayPlanner();
  }

  Future<void> _deleteTask(Task task) async {
    if (_todayPlanner == null) return;
    await _plannerRepository.removeTask(DateTime.now(), task.id);
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
                        onCompletedChanged: (_) =>
                            _toggleTaskCompleted(task),
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
