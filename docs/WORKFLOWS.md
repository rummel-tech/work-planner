# Typical Workflows

This document captures the main user-facing workflows in the Work Planner app.

---

## 1. Goal → Plan → Daily Execution

The primary workflow for turning a goal into actionable daily work.

### Step 1: Create a Goal

**Entry point:** Home screen → "+" / Goals section

- Choose goal type: **Corporate** or **Entrepreneurial**
- Provide: title, description, optional target date
- Status starts at `notStarted`

### Step 2: Create a Plan for the Goal

**Entry point:** Goal Detail screen → Plans → "+" 

- Provide: title, description, start/end dates, ordered steps
- Status starts at `draft`, advance to `active` when ready
- A goal can have multiple plans (e.g. phase 1, phase 2)

### Step 3: Schedule Tasks in the Day Planner

**Entry point:** Home screen → Day Planner → "+"

- Provide: title, priority (`low` / `medium` / `high` / `urgent`), scheduled time, duration in minutes
- Optionally link the task to an active plan (`planId`) and assign a pomodoro block (1–4)
- Each day has its own `DayPlanner` keyed by date

### Step 4: Complete Tasks

- Tap a task to toggle `completed`
- Day Planner shows live `completionRate` (completed / total tasks)

### Step 5: Track Goal Progress

- Open Goal Detail → see linked Plans and their statuses
- Advance plan status manually: `draft` → `active` → `completed`
- Advance goal status: `notStarted` → `inProgress` → `completed`

---

## 2. Weekly Planning

Use the Week Planner for higher-level weekly intention-setting alongside daily execution.

### Step 1: Open the Week Planner

**Entry point:** Home screen → Weekly Planner

- Displays the current week (Monday–Sunday)
- Each day links to its `DayPlanner`

### Step 2: Set Weekly Goals

- Add free-text weekly goals (e.g. "Complete sprint", "Prepare presentation")
- These are stored as `weeklyGoals: List<String>` on the `WeekPlanner`

### Step 3: Review Weekly Progress

- Backend aggregates: `total_tasks`, `completed_tasks`, `completion_rate`
- A completion bar shows progress across the full week

---

## 3. Authentication

### New User Registration

1. Navigate to the Register screen
2. Provide: email, password, invite code
3. Backend validates the invite code and creates an account
4. JWT is issued and stored in shared preferences

### Returning User Login

1. Navigate to the Login screen
2. Provide email and password
3. JWT is issued and stored; user lands on Home screen

### Token Lifecycle

- Auth service auto-refreshes expired tokens in the background
- On unrecoverable auth failure, user is redirected to the Welcome screen

---

## 4. Offline-First / Auto-Sync

The app is fully usable without a network connection.

| Action | Online behaviour | Offline behaviour |
|--------|-----------------|-------------------|
| Read data | Fetches from API, caches locally | Serves from local Sembast cache |
| Write data | Writes to API immediately, syncs to cache | Writes to local cache; syncs to API when reconnected |
| Conflict resolution | API response is the source of truth | Local cache is overwritten on next sync |

A `ConnectivityNotifier` tracks online/offline state and surfaces a stale-data indicator in the UI when working from cache.

---

## 5. Screen / Route Map

| Route | Screen | Purpose |
|-------|--------|---------|
| `/welcome` | WelcomeScreen | Landing / onboarding |
| `/login` | LoginScreen | Email + password login |
| `/register` | RegisterScreen | Registration with invite code |
| `/` | HomeScreen | Dashboard — day planner, goals summary, week overview |
| `/goal` | GoalDetailScreen | View a goal and its linked plans |
| `/goal/form` | GoalFormScreen | Create or edit a goal |
| `/plans` | PlansScreen | List plans for a goal |
| `/plan` | PlanDetailScreen | View a plan's steps and progress |
| `/plan/form` | PlanFormScreen | Create or edit a plan |
| `/day` | DayPlannerScreen | Schedule and complete tasks for a date |
| `/task/form` | TaskFormScreen | Create or edit a task |
| `/week` | WeeklyPlannerScreen | Set weekly goals and view aggregate progress |

---

## 6. Artemis Agent Tools (AI Integration)

The backend exposes Artemis-compatible agent tool endpoints for AI-driven interactions:

| Tool | Description |
|------|-------------|
| `create_task` | Add a task to today's day planner |
| `get_todays_tasks` | Retrieve all tasks scheduled for today |
| *(additional tools per Artemis contract)* | See `GET /artemis/manifest` |

Full contract: `rummel-tech/resources/ARTEMIS_MODULE_CONTRACT.md`
