import '../../models/plan.dart';
import '../../services/service_locator.dart';
import 'package:flutter/material.dart';

import '../../models/goal.dart';
import '../../ui_components/goal_card.dart';
import '../../ui_components/empty_state.dart';
import '../../navigation/app_router.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

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
    _tabController = TabController(length: 3, vsync: this);
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
        return _allGoals
            .where((g) => g.type == GoalType.entrepreneurial)
            .toList();
      default:
        return _allGoals;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Corporate'),
            Tab(text: 'Entrepreneurial'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGoalList(0),
                _buildGoalList(1),
                _buildGoalList(2),
              ],
            ),
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
