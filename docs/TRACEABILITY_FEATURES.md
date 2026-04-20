# Work Planner — Feature Traceability Matrix

Maps each user-facing feature from the product description through specification, unit/widget tests, end-to-end (integration) tests, and implementation files. The release smoke-test checklist is included as the final verification gate.

---

## Traceability Chain

```
OBJECTIVES.md (product description)
    → WORKFLOWS.md / ARCHITECTURE.md (specification)
        → Unit tests (test/unit/)
        → Widget tests (test/widget/)
        → Workflow tests (test/workflow/)
        → Integration tests (integration_test/)
        → Backend tests (services/work-planner/tests/)
            → Source implementation
                → DEPLOYMENT.md smoke test (release gate)
```

---

## How to Read This Matrix

| Column | Meaning |
|--------|---------|
| **ID** | Feature requirement identifier |
| **Feature** | User-visible capability |
| **Product Spec** | OBJECTIVES.md FR that defines the requirement |
| **Defined In** | Detailed spec doc(s) |
| **Unit / Widget Tests** | `test/unit/`, `test/widget/`, `test/workflow/` test names |
| **Integration Tests** | `integration_test/app_test.dart` group + test name |
| **Backend Tests** | `services/work-planner/tests/` pytest function names |
| **Implementation** | Source files |
| **Release Gate** | DEPLOYMENT.md smoke test step(s) |

---

## Discrepancies: Product Spec vs. Implementation

These are intentional divergences from OBJECTIVES.md that should be resolved or officially accepted:

| Item | OBJECTIVES.md says | Code says | Action needed |
|------|--------------------|-----------|---------------|
| Goal status values | `notStarted, inProgress, completed, archived` | `notStarted, inProgress, completed, abandoned` | Update OBJECTIVES.md to use `abandoned` |
| Goal types | `corporate, entrepreneurial, personal` | `corporate, farm, appDevelopment, homeAuto` | Update OBJECTIVES.md to match actual enum |

---

## FR-1 · Goal Management

Create, view, edit, and delete work goals. Goals are typed, carry a status lifecycle, and link to one or more plans.

| ID | Feature | Product Spec | Defined In | Unit / Widget / Workflow Tests | Integration Tests | Backend Tests | Implementation | Release Gate |
|----|---------|-------------|------------|-------------------------------|-------------------|---------------|----------------|--------------|
| FR-1.1 | Create goal (title, description, type: corporate / farm / appDevelopment / homeAuto, optional target date) | OBJECTIVES.md FR-1 | WORKFLOWS.md §1 Step 1 | `goal_execution_workflow_test` — "Step 1: create and retrieve a goal", "Step 1b: goal defaults to notStarted status" · `goal_form_screen_test` — "shows 'New Goal' in AppBar", "shows title and description form fields", "shows goal type dropdown", "shows 'Create Goal' submit button", "shows title validation error", "shows description validation error" | `Goal creation flow` — "creates a goal via Goals tab → New Goal form", "validation blocks save when title is empty" | `test_create_goal`, `test_create_goal_missing_title` | `lib/src/screens/goals/goal_form_screen.dart` · `lib/src/models/goal.dart` · `lib/src/services/goal_repository.dart` · `routers/goals.py` | Register → create a goal |
| FR-1.2 | Edit goal | OBJECTIVES.md FR-1 | WORKFLOWS.md §5 | `goal_form_screen_test` — "shows 'Edit Goal' in AppBar", "pre-fills title and description", "shows 'Save Changes' button" | — | `test_update_goal` | `lib/src/screens/goals/goal_form_screen.dart` · `lib/src/services/goal_repository.dart` · `routers/goals.py` | — |
| FR-1.3 | Delete goal (cascades to linked plans) | OBJECTIVES.md FR-1 | WORKFLOWS.md §1 | `goal_execution_workflow_test` — "Step 7: delete goal also removes its linked plans" | — | `test_delete_goal` | `lib/src/screens/goals/goal_detail_screen.dart` · `lib/src/services/goal_repository.dart` · `lib/src/services/plan_repository.dart` · `routers/goals.py` | — |
| FR-1.4 | View goal list filtered by type tab (All / Corp / Farm / App Dev / Home & Auto) | OBJECTIVES.md FR-1 | WORKFLOWS.md §5 | `goals_screen_test` — "shows All / Corp / Farm / App Dev / Home & Auto tabs", "shows seeded goals in All tab", "Corp tab shows only corporate goals", "shows empty state when no goals", "shows FAB" | `Goal creation flow` — goal appears in list after creation | `test_list_goals_empty`, `test_get_goal` | `lib/src/screens/goals/goals_screen.dart` · `lib/src/ui_components/goal_card.dart` · `routers/goals.py` | — |
| FR-1.5 | View goal detail — type label, status chips, linked plans section | OBJECTIVES.md FR-1 | WORKFLOWS.md §1 Step 5 | `goal_detail_screen_test` — "shows goal title and description", "shows goal type label", "shows all four status choice chips", "shows plan cards when plans exist", "shows 'No plans yet' when no plans", "shows 'Goal Details' in AppBar", "shows Plans section header and Add Plan button", "shows edit and delete action buttons", "shows Status section heading" | — | `test_get_goal` | `lib/src/screens/goals/goal_detail_screen.dart` · `lib/src/services/goal_repository.dart` · `lib/src/services/plan_repository.dart` | — |
| FR-1.6 | Advance goal status (notStarted → inProgress → completed / abandoned) | OBJECTIVES.md FR-1 | WORKFLOWS.md §1 Step 5 | `goal_execution_workflow_test` — "Step 6: advance goal status to inProgress" · `offline_sync_workflow_test` — "getByStatus filters by status correctly", "getActive returns notStarted and inProgress goals" | — | `test_update_goal` | `lib/src/screens/goals/goal_detail_screen.dart` · `lib/src/models/goal.dart` · `routers/goals.py` | — |
| FR-1.7 | Filter goals by status; get active goals (notStarted + inProgress only) | OBJECTIVES.md FR-1 | WORKFLOWS.md §1 | `offline_sync_workflow_test` — "getByStatus filters by status correctly", "getActive returns notStarted and inProgress goals", "getByType returns only goals of requested type" | — | — | `lib/src/services/goal_repository.dart` | — |

---

## FR-2 · Plan Management

Multi-step plans linked to a goal, with status lifecycle and ordered steps.

| ID | Feature | Product Spec | Defined In | Unit / Widget / Workflow Tests | Integration Tests | Backend Tests | Implementation | Release Gate |
|----|---------|-------------|------------|-------------------------------|-------------------|---------------|----------------|--------------|
| FR-2.1 | Create plan (title, description, goal link, steps, start/end dates, status) | OBJECTIVES.md FR-2 | WORKFLOWS.md §1 Step 2 | `goal_execution_workflow_test` — "Step 2: create a plan linked to a goal", "Step 2b: plan status advances from draft to active" | — | `test_create_plan`, `test_create_plan_missing_title`, `test_create_plan_invalid_goal` | `lib/src/screens/plans/plan_form_screen.dart` · `lib/src/models/plan.dart` · `lib/src/services/plan_repository.dart` · `routers/plans.py` | Create a plan linked to a goal |
| FR-2.2 | Edit plan | OBJECTIVES.md FR-2 | WORKFLOWS.md §5 | — | — | `test_update_plan`, `test_update_plan_not_found` | `lib/src/screens/plans/plan_form_screen.dart` · `lib/src/services/plan_repository.dart` · `routers/plans.py` | — |
| FR-2.3 | Delete plan | OBJECTIVES.md FR-2 | WORKFLOWS.md §1 | `goal_execution_workflow_test` — "Step 7: delete goal also removes its linked plans" | — | `test_delete_plan`, `test_delete_plan_not_found` | `lib/src/screens/plans/plan_detail_screen.dart` · `lib/src/services/plan_repository.dart` · `routers/plans.py` | — |
| FR-2.4 | View plan list for a goal | OBJECTIVES.md FR-2 | WORKFLOWS.md §5 | `goal_detail_screen_test` — "shows plan cards when plans exist", "does not show plans from a different goal", "shows 'No plans yet'" | — | `test_list_plans_empty`, `test_list_plans_filtered_by_goal` | `lib/src/screens/plans/plans_screen.dart` · `lib/src/ui_components/plan_card.dart` · `routers/plans.py` | — |
| FR-2.5 | View plan list filtered by status | OBJECTIVES.md FR-2 | WORKFLOWS.md §1 Step 2 | — | — | `test_list_plans_filtered_by_status` | `lib/src/screens/plans/plans_screen.dart` · `routers/plans.py` | — |
| FR-2.6 | View plan detail (steps, progress) | OBJECTIVES.md FR-2 | WORKFLOWS.md §1 Step 5 | `plan_detail_screen_test` | — | `test_get_plan`, `test_get_plan_not_found` | `lib/src/screens/plans/plan_detail_screen.dart` · `lib/src/services/plan_repository.dart` | — |
| FR-2.7 | Advance plan status (draft → active → completed) | OBJECTIVES.md FR-2 | WORKFLOWS.md §1 Step 2 | `goal_execution_workflow_test` — "Step 2b: plan status advances from draft to active" | — | `test_update_plan` | `lib/src/screens/plans/plan_detail_screen.dart` · `lib/src/models/plan.dart` | — |

---

## FR-3 · Day Planner

Tasks scheduled for a specific date, organised into 4 pomodoro blocks. Completion rate shown live.

| ID | Feature | Product Spec | Defined In | Unit / Widget / Workflow Tests | Integration Tests | Backend Tests | Implementation | Release Gate |
|----|---------|-------------|------------|-------------------------------|-------------------|---------------|----------------|--------------|
| FR-3.1 | Create task (title, priority, duration, pomodoro block 1–4, optional plan link) | OBJECTIVES.md FR-3 | WORKFLOWS.md §1 Steps 3–4 | `goal_execution_workflow_test` — "Step 3: add a task to a day planner", "Step 3b: tasks can be assigned to specific pomodoro blocks", "Step 4: link a task to a plan via planId" · `day_planner_screen_test` — "has a FAB to add unassigned tasks" | `Task creation flow` — "adds a task from the Today tab", "task form validation blocks save when title is empty" | `test_create_task`, `test_create_task_missing_title`, `test_create_task_creates_day_planner_if_missing` | `lib/src/screens/daily/task_form_screen.dart` · `lib/src/planners/day_planner.dart` · `lib/src/services/planner_repository.dart` · `routers/planners.py` · `routers/tasks.py` | Add tasks to today's day planner |
| FR-3.2 | Edit task | OBJECTIVES.md FR-3 | WORKFLOWS.md §5 | `offline_sync_workflow_test` — "updateTask modifies the task in-place" | — | `test_update_task`, `test_update_task_not_found` | `lib/src/screens/daily/task_form_screen.dart` · `lib/src/services/planner_repository.dart` · `routers/tasks.py` | — |
| FR-3.3 | Delete task | OBJECTIVES.md FR-3 | WORKFLOWS.md §1 | `offline_sync_workflow_test` — "removeTask deletes a task from the planner" | — | `test_delete_task`, `test_delete_task_not_found` | `lib/src/screens/daily/day_planner_screen.dart` · `lib/src/services/planner_repository.dart` · `routers/tasks.py` | — |
| FR-3.4 | Toggle task completion; live completion rate | OBJECTIVES.md FR-3 | WORKFLOWS.md §1 Step 4 | `goal_execution_workflow_test` — "Step 5: complete a task and verify completion rate", "Step 5b: toggleCompleted updates the task", "Step 5c: completion rate is 1.0 when all done" · `day_planner_screen_test` — "displays correct task count summary" | `Task completion` — "toggling a task marks it as completed" | `test_update_task` | `lib/src/screens/daily/day_planner_screen.dart` · `lib/src/ui_components/task_tile.dart` · `lib/src/planners/day_planner.dart` · `lib/src/ui_components/completion_indicator.dart` | — |
| FR-3.5 | View tasks by pomodoro block (4 blocks + Unassigned section) | OBJECTIVES.md FR-3 | WORKFLOWS.md §1 Step 3 | `day_planner_screen_test` — "renders 4 block sections", "shows task in correct block after seeding", "shows Unassigned section when task has no block", "does not show Unassigned when no tasks", "shows empty state in each block" | `Day planner — Pomodoro block layout` — "renders 4 labelled blocks", "tapping + for a block pre-selects that block in the task form", "seeded task appears under its assigned block" | `test_list_tasks` | `lib/src/screens/daily/day_planner_screen.dart` · `lib/src/planners/day_planner.dart` | — |
| FR-3.6 | Day planner notes | OBJECTIVES.md FR-3 | WORKFLOWS.md §1 | `day_planner_screen_test` — "shows Notes section" · `offline_sync_workflow_test` — "updateDayPlannerNotes persists notes" | — | `test_update_day_planner_notes`, `test_update_day_planner_not_found` | `lib/src/screens/daily/day_planner_screen.dart` · `lib/src/services/planner_repository.dart` · `routers/planners.py` | — |
| FR-3.7 | Retrieve tasks linked to a specific plan (cross-day aggregation) | OBJECTIVES.md FR-3 | WORKFLOWS.md §1 Step 4 | `goal_execution_workflow_test` — "Step 4: link a task to a plan via planId" · `offline_sync_workflow_test` — "getTasksForPlan aggregates tasks across multiple days" | — | — | `lib/src/services/planner_repository.dart` | — |

---

## FR-4 · Week Planner

Weekly intentions, aggregate completion stats, day-by-day navigation.

| ID | Feature | Product Spec | Defined In | Unit / Widget / Workflow Tests | Integration Tests | Backend Tests | Implementation | Release Gate |
|----|---------|-------------|------------|-------------------------------|-------------------|---------------|----------------|--------------|
| FR-4.1 | Open / create week planner for current or past week (idempotent) | OBJECTIVES.md FR-4 | WORKFLOWS.md §2 Step 1 | `weekly_planning_workflow_test` — "creates a new week planner for a given Monday", "returns the same week planner on repeated calls", "getCurrentWeekPlanner returns planner whose start is this Monday", "different week starts produce different planners", "normalises time component" | — | `test_create_week_planner`, `test_create_week_planner_idempotent`, `test_get_week_planner`, `test_get_week_planner_not_found` | `lib/src/screens/weekly/weekly_planner_screen.dart` · `lib/src/planners/week_planner.dart` · `lib/src/services/planner_repository.dart` · `routers/planners.py` | Week planner loads with correct week dates |
| FR-4.2 | Set / update weekly goals (add, remove, clear free-text items) | OBJECTIVES.md FR-4 | WORKFLOWS.md §2 Step 2 | `weekly_planning_workflow_test` — "add weekly goals", "remove a weekly goal", "clear all weekly goals" | — | `test_update_week_planner`, `test_update_week_planner_not_found` | `lib/src/screens/weekly/weekly_planner_screen.dart` · `lib/src/services/planner_repository.dart` · `routers/planners.py` | — |
| FR-4.3 | View weekly aggregate stats (total tasks, completed, completion rate) | OBJECTIVES.md FR-4 | WORKFLOWS.md §2 Step 3 | `weekly_planning_workflow_test` — "week stats are zero when no tasks exist" | — | `test_week_stats_no_tasks`, `test_week_stats_with_tasks` | `lib/src/screens/weekly/weekly_planner_screen.dart` · `lib/src/services/planner_repository.dart` · `routers/planners.py` | — |
| FR-4.4 | Week planner notes | OBJECTIVES.md FR-4 | WORKFLOWS.md §2 | `weekly_planning_workflow_test` — "update notes for the week" | — | `test_update_week_planner` | `lib/src/screens/weekly/weekly_planner_screen.dart` · `lib/src/services/planner_repository.dart` | — |
| FR-4.5 | Week date boundary (Mon–Sun; 6-day span; date normalisation) | OBJECTIVES.md FR-4 | WORKFLOWS.md §2 | `weekly_planning_workflow_test` — "week end date is 6 days after start", "normalises time component" | — | `test_create_week_planner` | `lib/src/planners/week_planner.dart` · `lib/src/services/planner_repository.dart` | — |
| FR-4.6 | View and navigate to day planners within the week | OBJECTIVES.md FR-4 | WORKFLOWS.md §2 Step 1 | `weekly_planner_screen_test` | — | `test_list_day_planners_empty`, `test_get_day_planner`, `test_get_day_planner_not_found` | `lib/src/screens/weekly/weekly_planner_screen.dart` · `lib/src/services/planner_repository.dart` | — |

---

## FR-5 · Authentication

Email/password registration with invite codes, waitlist, JWT lifecycle, admin code management.

| ID | Feature | Product Spec | Defined In | Unit / Widget / Workflow Tests | Integration Tests | Backend Tests | Implementation | Release Gate |
|----|---------|-------------|------------|-------------------------------|-------------------|---------------|----------------|--------------|
| FR-5.1 | Registration with invite code | OBJECTIVES.md FR-5 | WORKFLOWS.md §3 | `authentication_workflow_test` — "register creates an authenticated session" · `register_screen_test` | — | `test_register_success`, `test_register_duplicate_email`, `test_validate_code_valid`, `test_validate_code_invalid`, `test_validate_code_too_short` | `lib/src/screens/auth/register_screen.dart` · `lib/src/services/auth_service.dart` · `routers/auth.py` | Register with invite code; login succeeds |
| FR-5.2 | Waitlist (no code or invalid code goes to waitlist, not error) | OBJECTIVES.md FR-5 | WORKFLOWS.md §3 | `authentication_workflow_test` — "register without a code also authenticates (fake always succeeds)" | — | `test_register_without_code_goes_to_waitlist`, `test_register_with_invalid_code_goes_to_waitlist` | `lib/src/screens/auth/register_screen.dart` · `routers/auth.py` | — |
| FR-5.3 | Login with email and password | OBJECTIVES.md FR-5 | WORKFLOWS.md §3 | `authentication_workflow_test` — "login with valid credentials authenticates the user", "login with wrong credentials throws AuthException", "user remains unauthenticated after failed login" · `login_screen_test` | `Welcome screen` — "Sign In button navigates to login screen" | `test_login_success`, `test_login_wrong_password`, `test_login_unknown_email`, `test_me`, `test_me_unauthenticated` | `lib/src/screens/auth/login_screen.dart` · `lib/src/services/auth_service.dart` · `routers/auth.py` | Register → login succeeds |
| FR-5.4 | Logout (clears all tokens) | OBJECTIVES.md FR-5 | WORKFLOWS.md §3 | `authentication_workflow_test` — "logout removes authentication and clears tokens", "full auth lifecycle: unauthenticated → login → logout" | — | `test_logout` | `lib/src/services/auth_service.dart` · `routers/auth.py` | — |
| FR-5.5 | Welcome / onboarding screen with navigation to login and register | OBJECTIVES.md FR-5 | WORKFLOWS.md §5 (route `/welcome`) | — | `Welcome screen` — "shows Sign In and Create Account buttons", "Sign In button navigates to login screen" | — | `lib/src/screens/auth/welcome_screen.dart` · `lib/src/navigation/app_router.dart` | — |
| FR-5.6 | Token persistence and pre-authentication check on app launch | OBJECTIVES.md FR-5 | WORKFLOWS.md §3 | `authentication_workflow_test` — "pre-authenticated user has tokens immediately" | — | `test_me` | `lib/src/services/auth_service.dart` · `lib/main.dart` | — |
| FR-5.7 | Admin: generate registration codes | OBJECTIVES.md FR-5 | ARCHITECTURE.md §Backend | — | — | *(no test — gap)* | `routers/auth.py` — `POST /admin/codes` | — |
| FR-5.8 | Admin: list registration codes | OBJECTIVES.md FR-5 | ARCHITECTURE.md §Backend | — | — | *(no test — gap)* | `routers/auth.py` — `GET /admin/codes` | — |

---

## FR-6 · Artemis Platform Integration

Artemis Module Contract endpoints — widgets, agent tools, data summaries, dual-mode auth.

| ID | Feature | Product Spec | Defined In | Unit / Widget / Workflow Tests | Integration Tests | Backend Tests | Implementation | Release Gate |
|----|---------|-------------|------------|-------------------------------|-------------------|---------------|----------------|--------------|
| FR-6.1 | Module manifest (metadata, widget defs, agent tools, data endpoints) | OBJECTIVES.md FR-6 | ARCHITECTURE.md §Artemis · WORKFLOWS.md §6 | — | — | *(no test — gap)* | `routers/artemis.py` · `lib/src/services/api_config.dart` | Artemis: `GET /artemis/manifest` returns module definition |
| FR-6.2 | Today's Tasks widget (task count + completion rate) | OBJECTIVES.md FR-6 | ARCHITECTURE.md §Artemis | — | — | *(no test — gap)* | `routers/artemis.py` | Artemis: `GET /artemis/widget` returns today's task count |
| FR-6.3 | Weekly Progress widget | OBJECTIVES.md FR-6 | ARCHITECTURE.md §Artemis | — | — | *(no test — gap)* | `routers/artemis.py` | — |
| FR-6.4 | Agent tool: create\_task | OBJECTIVES.md FR-6 | WORKFLOWS.md §6 | — | — | *(no test — gap)* | `routers/artemis.py` · `routers/tasks.py` | — |
| FR-6.5 | Agent tool: get\_todays\_tasks | OBJECTIVES.md FR-6 | WORKFLOWS.md §6 | — | — | *(no test — gap)* | `routers/artemis.py` · `routers/planners.py` | — |
| FR-6.6 | Agent tool: create\_goal | OBJECTIVES.md FR-6 | WORKFLOWS.md §6 | — | — | *(no test — gap)* | `routers/artemis.py` · `routers/goals.py` | — |
| FR-6.7 | Agent tool: get\_weekly\_summary | OBJECTIVES.md FR-6 | ARCHITECTURE.md §Artemis | — | — | *(no test — gap)* | `routers/artemis.py` | — |
| FR-6.8 | Data endpoint: task\_schedule | OBJECTIVES.md FR-6 | ARCHITECTURE.md §Artemis | — | — | *(no test — gap)* | `routers/artemis.py` | — |
| FR-6.9 | Data endpoint: goals\_progress | OBJECTIVES.md FR-6 | ARCHITECTURE.md §Artemis | — | — | *(no test — gap)* | `routers/artemis.py` | — |
| FR-6.10 | Dual-mode auth: accepts Artemis RS256 token OR standalone HS256 | OBJECTIVES.md FR-5 / FR-6 | ARCHITECTURE.md §Auth Dual-Mode | — | — | *(no test — gap)* | `routers/artemis.py` · `common/artemis_auth.py` · `core/auth_service.py` | — |

---

## Home Screen Dashboard

The home screen is the primary launch surface — confirmed by integration tests but not explicitly listed in OBJECTIVES.md FRs.

| ID | Feature | Defined In | Integration Tests | Implementation |
|----|---------|------------|-------------------|----------------|
| HS-1 | App title + bottom nav (Home / Goals / Week / Today) | WORKFLOWS.md §5 | `Home screen` — "shows app title and bottom nav destinations" | `lib/src/screens/home/home_screen.dart` · `lib/src/navigation/app_router.dart` |
| HS-2 | Dashboard shows Today's Tasks and Active Goals sections | WORKFLOWS.md §5 | `Home screen` — "dashboard shows Today's Tasks and Active Goals sections" | `lib/src/screens/home/home_screen.dart` |

---

## Coverage Summary

| Feature Group | Sub-features | Unit/Widget Tests | Integration Tests | Backend Tests | Gaps |
|---------------|-------------|-------------------|-------------------|---------------|------|
| FR-1 Goal Management | 7 | 20+ | 2 (goal creation flow) | 6 | None |
| FR-2 Plan Management | 7 | 10+ | 0 | 8 | Integration tests |
| FR-3 Day Planner | 7 | 18+ | 4 (task flow + pomodoro) | 10 | None |
| FR-4 Week Planner | 6 | 11+ | 0 | 8 | Integration tests |
| FR-5 Authentication | 8 | 10+ | 2 (welcome screen) | 13 | Admin endpoints have no tests |
| FR-6 Artemis Integration | 10 | 0 | 0 | 0 | Entire feature uncovered |

> **Priority gaps to address:**
> 1. Create `tests/test_artemis.py` covering manifest, widget, all agent tools, data endpoints, and RS256 dual-auth
> 2. Add admin endpoint tests (`test_create_code`, `test_list_codes`) to `tests/test_auth.py`
> 3. Add integration tests for plan management and week planner flows
> 4. Resolve OBJECTIVES.md discrepancies (goal types, `archived` vs `abandoned`)
