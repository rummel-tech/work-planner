import '../../services/service_locator.dart';
import 'package:flutter/material.dart';

import '../../models/goal.dart';
import '../../ui_components/goal_card.dart';
import '../../ui_components/empty_state.dart';
import '../../navigation/app_router.dart';

class GoalsScreen extends StatefulWidget {
  /// When true, suppresses Scaffold/AppBar/FAB for embedding in a parent shell.
  final bool embedded;

  const GoalsScreen({super.key, this.embedded = false});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  final _goalRepository = ServiceLocator.goals;
  final _planRepository = ServiceLocator.plans;
  late TabController _tabController;
  List<Goal> _allGoals = [];
  Map<String, int> _planCounts = {};
  bool _isLoading = true;

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
    setState(() => _isLoading = true);

    final goals = await _goalRepository.getAll();
    final planCounts = <String, int>{};
    for (final goal in goals) {
      planCounts[goal.id] = await _planRepository.countByGoalId(goal.id);
    }

    setState(() {
      _allGoals = goals;
      _planCounts = planCounts;
      _isLoading = false;
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
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildGoalList(0),
              _buildGoalList(1),
              _buildGoalList(2),
              _buildGoalList(3),
              _buildGoalList(4),
            ],
          );

    final tabBar = TabBar(
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
    );

    // Embedded mode: no Scaffold, inline "New Goal" button instead of FAB.
    if (widget.embedded) {
      return Column(
        children: [
          tabBar,
          Expanded(child: body),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        bottom: tabBar,
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRouter.goalForm);
          _loadGoals();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGoalList(int tabIndex) {
    final goals = _getFilteredGoals(tabIndex);

    if (goals.isEmpty) {
      return EmptyState(
        icon: Icons.flag_outlined,
        title: 'No goals yet',
        subtitle: 'Create your first goal to get started',
        action: FilledButton.icon(
          onPressed: () async {
            await Navigator.pushNamed(context, AppRouter.goalForm);
            _loadGoals();
          },
          icon: const Icon(Icons.add),
          label: const Text('Create Goal'),
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
