import 'dart:async';
import '../../services/service_locator.dart';
import 'package:flutter/material.dart';

import '../../planners/day_planner.dart';
import '../../planners/week_planner.dart';
import '../../ui_components/completion_indicator.dart';
import '../../navigation/app_router.dart';

class WeeklyPlannerScreen extends StatefulWidget {
  final DateTime? initialWeekStart;

  /// When true, suppresses Scaffold/AppBar for embedding in a parent shell.
  final bool embedded;

  const WeeklyPlannerScreen({
    super.key,
    this.initialWeekStart,
    this.embedded = false,
  });

  @override
  State<WeeklyPlannerScreen> createState() => _WeeklyPlannerScreenState();
}

class _WeeklyPlannerScreenState extends State<WeeklyPlannerScreen> {
  final _plannerRepository = ServiceLocator.planners;
  final _goalController = TextEditingController();
  final _notesController = TextEditingController();
  Timer? _notesDebounce;
  WeekPlanner? _weekPlanner;
  Map<int, DayPlanner> _dayPlanners = {};
  late DateTime _currentWeekStart;
  double _weekCompletionRate = 0.0;

  @override
  void initState() {
    super.initState();
    _initWeekStart();
    _loadWeekPlanner();
  }

  @override
  void dispose() {
    _notesDebounce?.cancel();
    _goalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initWeekStart() {
    final date = widget.initialWeekStart ?? DateTime.now();
    final weekday = date.weekday;
    _currentWeekStart = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: weekday - 1));
  }

  Future<void> _loadWeekPlanner() async {
    final planner = await _plannerRepository.getOrCreateWeekPlanner(
      _currentWeekStart,
    );
    final dayPlanners = await _plannerRepository.getDayPlannersForWeek(planner);
    final stats = await _plannerRepository.getWeekStats(planner);

    setState(() {
      _weekPlanner = planner;
      _dayPlanners = dayPlanners;
      _weekCompletionRate = stats.completionRate;
      _notesController.text = planner.notes ?? '';
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

  void _goToToday() {
    final now = DateTime.now();
    final weekday = now.weekday;
    setState(() {
      _currentWeekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: weekday - 1));
    });
    _loadWeekPlanner();
  }

  Future<void> _addWeeklyGoal() async {
    final goal = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Weekly Goal'),
        content: TextField(
          controller: _goalController,
          decoration: const InputDecoration(
            hintText: 'Enter goal description',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = _goalController.text.trim();
              _goalController.clear();
              Navigator.pop(context, text);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (goal != null && goal.isNotEmpty && _weekPlanner != null) {
      final updatedGoals = [..._weekPlanner!.weeklyGoals, goal];
      await _plannerRepository.updateWeekPlannerGoals(
        _currentWeekStart,
        updatedGoals,
      );
      _loadWeekPlanner();
    }
  }

  Future<void> _removeWeeklyGoal(String goal) async {
    if (_weekPlanner == null) return;

    final updatedGoals = _weekPlanner!.weeklyGoals
        .where((g) => g != goal)
        .toList();
    await _plannerRepository.updateWeekPlannerGoals(
      _currentWeekStart,
      updatedGoals,
    );
    _loadWeekPlanner();
  }

  void _onNotesChanged(String value) {
    if (_notesDebounce?.isActive ?? false) _notesDebounce!.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 500), () {
      _saveNotes();
    });
  }

  Future<void> _saveNotes() async {
    if (_weekPlanner == null) return;
    await _plannerRepository.updateWeekPlannerNotes(
      _currentWeekStart,
      _notesController.text,
    );
  }

  String _formatWeekRange() {
    final end = _currentWeekStart.add(const Duration(days: 6));
    return '${_currentWeekStart.month}/${_currentWeekStart.day} - ${end.month}/${end.day}';
  }

  bool _isCurrentWeek() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final currentWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: weekday - 1));
    return _currentWeekStart.isAtSameMomentAs(currentWeekStart);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = RefreshIndicator(
        onRefresh: _loadWeekPlanner,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
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
                    Column(
                      children: [
                        Text(
                          _formatWeekRange(),
                          style: theme.textTheme.titleMedium,
                        ),
                        if (_isCurrentWeek())
                          Text(
                            'Current Week',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextWeek,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
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
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_weekCompletionRate * 100).toInt()}% complete',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Weekly Goals',
                              style: theme.textTheme.titleSmall,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addWeeklyGoal,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        if (_weekPlanner?.weeklyGoals.isEmpty ?? true)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No weekly goals set',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          )
                        else
                          ...(_weekPlanner?.weeklyGoals ?? []).map(
                            (goal) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.flag_outlined,
                                size: 20,
                              ),
                              title: Text(goal),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => _removeWeeklyGoal(goal),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notes', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            hintText: 'Notes for this week...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          onChanged: _onNotesChanged,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate(7, (index) {
                    final date = _currentWeekStart.add(Duration(days: index));
                    final dayPlanner = _dayPlanners[index];
                    final taskCount = dayPlanner?.tasks.length ?? 0;
                    final completedCount =
                        dayPlanner?.completedTasks.length ?? 0;
                    final now = DateTime.now();
                    final isToday =
                        date.day == now.day &&
                        date.month == now.month &&
                        date.year == now.year;

                    return Card(
                      color: isToday
                          ? theme.colorScheme.primaryContainer
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
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: isToday ? FontWeight.bold : null,
                              ),
                            ),
                            Text(
                              '${date.day}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: isToday ? FontWeight.bold : null,
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          taskCount == 0
                              ? 'No tasks'
                              : '$completedCount/$taskCount completed',
                        ),
                        subtitle: taskCount > 0
                            ? LinearProgressIndicator(
                                value: completedCount / taskCount,
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_right),
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
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    // Embedded mode: no Scaffold/AppBar.
    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Planner'),
        actions: [
          if (!_isCurrentWeek())
            TextButton(onPressed: _goToToday, child: const Text('Today')),
        ],
      ),
      body: content,
    );
  }
}
