import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_services.dart';

void main() {
  late FakePlannerRepository plannerRepo;

  final weekStart = DateTime(2025, 6, 16); // Monday

  setUp(() {
    plannerRepo = FakePlannerRepository();
  });

  group('Workflow 2: Weekly Planning', () {
    test('creates a new week planner for a given Monday', () async {
      final planner = await plannerRepo.getOrCreateWeekPlanner(weekStart);
      expect(planner.weekStartDate, weekStart);
      expect(planner.weeklyGoals, isEmpty);
    });

    test('returns the same week planner on repeated calls', () async {
      final first = await plannerRepo.getOrCreateWeekPlanner(weekStart);
      final second = await plannerRepo.getOrCreateWeekPlanner(weekStart);
      expect(first.id, second.id);
    });

    test('normalises time component — same date at different times is one planner',
        () async {
      final withTime = DateTime(2025, 6, 16, 9, 30);
      final noTime = DateTime(2025, 6, 16);
      final first = await plannerRepo.getOrCreateWeekPlanner(withTime);
      final second = await plannerRepo.getOrCreateWeekPlanner(noTime);
      expect(first.id, second.id);
    });

    test('add weekly goals', () async {
      final goals = ['Complete sprint', 'Prepare presentation', 'Review OKRs'];
      final planner = await plannerRepo.updateWeekPlannerGoals(weekStart, goals);
      expect(planner.weeklyGoals, goals);
    });

    test('remove a weekly goal', () async {
      await plannerRepo.updateWeekPlannerGoals(
          weekStart, ['Goal A', 'Goal B', 'Goal C']);
      final updated = await plannerRepo.updateWeekPlannerGoals(
          weekStart, ['Goal A', 'Goal C']);
      expect(updated.weeklyGoals, ['Goal A', 'Goal C']);
      expect(updated.weeklyGoals, isNot(contains('Goal B')));
    });

    test('clear all weekly goals', () async {
      await plannerRepo.updateWeekPlannerGoals(weekStart, ['A', 'B', 'C']);
      final cleared = await plannerRepo.updateWeekPlannerGoals(weekStart, []);
      expect(cleared.weeklyGoals, isEmpty);
    });

    test('update notes for the week', () async {
      final planner = await plannerRepo.updateWeekPlannerNotes(
          weekStart, 'Focus on delivery this week');
      expect(planner.notes, 'Focus on delivery this week');
    });

    test('week stats are zero when no tasks exist', () async {
      final weekPlanner = await plannerRepo.getOrCreateWeekPlanner(weekStart);
      final stats = await plannerRepo.getWeekStats(weekPlanner);
      expect(stats.totalTasks, 0);
      expect(stats.completedTasks, 0);
      expect(stats.completionRate, 0.0);
    });

    test('week end date is 6 days after start', () async {
      final planner = await plannerRepo.getOrCreateWeekPlanner(weekStart);
      expect(planner.weekEndDate, weekStart.add(const Duration(days: 6)));
    });

    test('getCurrentWeekPlanner returns a planner whose start is this Monday',
        () async {
      final planner = await plannerRepo.getCurrentWeekPlanner();
      final now = DateTime.now();
      final expectedStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      expect(planner.weekStartDate, expectedStart);
    });

    test('different week starts produce different planners', () async {
      final week1 = await plannerRepo.getOrCreateWeekPlanner(weekStart);
      final nextWeek = weekStart.add(const Duration(days: 7));
      final week2 = await plannerRepo.getOrCreateWeekPlanner(nextWeek);
      expect(week1.id, isNot(week2.id));
      expect(week2.weekStartDate, nextWeek);
    });
  });
}
