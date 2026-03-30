import '../../services/service_locator.dart';
import 'package:flutter/material.dart';

import '../../models/plan.dart';
import '../../ui_components/plan_card.dart';
import '../../ui_components/empty_state.dart';
import '../../navigation/app_router.dart';

class PlansScreen extends StatefulWidget {
  final String goalId;

  const PlansScreen({super.key, required this.goalId});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final _planRepository = ServiceLocator.plans;
  List<Plan> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);

    final plans = await _planRepository.getByGoalId(widget.goalId);

    setState(() {
      _plans = plans;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? EmptyState(
                  icon: Icons.list_alt_outlined,
                  title: 'No plans yet',
                  subtitle: 'Create a plan to work towards your goal',
                  action: FilledButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRouter.planForm,
                        arguments: {'goalId': widget.goalId},
                      );
                      _loadPlans();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Plan'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlans,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      return PlanCard(
                        plan: plan,
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRouter.planDetail,
                            arguments: plan,
                          );
                          _loadPlans();
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(
            context,
            AppRouter.planForm,
            arguments: {'goalId': widget.goalId},
          );
          _loadPlans();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
