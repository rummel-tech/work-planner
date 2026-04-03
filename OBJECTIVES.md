# Work Planner — Objectives

## Mission

Provide a structured planning system for corporate and entrepreneurial goals, helping users break down ambitions into executable daily and weekly plans.

## Primary Objectives

1. **Goal management** — define, track, and achieve corporate and personal work goals
2. **Plan creation** — break goals into actionable plans with steps and timelines
3. **Day planner** — schedule tasks across the day with priority and time blocks
4. **Week planner** — set weekly intentions and track goal progress
5. **Offline-first** — all data accessible without a network connection

## Functional Requirements

### FR-1: Goal Management

- Create goals with types: `corporate`, `entrepreneurial`, `personal`
- Track goal status: `notStarted`, `inProgress`, `completed`, `archived`
- Set target dates; view overdue and upcoming goals
- Link plans to goals for progress tracking

### FR-2: Plan Management

- Create multi-step plans linked to goals
- Plan statuses: `draft`, `active`, `completed`
- Set start/end dates; define ordered steps with completion tracking
- View plan progress as percentage of completed steps

### FR-3: Day Planner

- One day-planner entry per user per date
- Add time-blocked tasks with priority (low/medium/high) and duration
- Mark tasks complete; link tasks to active plans
- View today's schedule at a glance

### FR-4: Week Planner

- One week-planner entry per user per week
- Set weekly goals (free text, ordered list)
- Aggregate task completion across the week
- Navigate between weeks

### FR-5: Authentication

- Email/password registration with invite codes (controlled rollout)
- Waitlist for unregistered users
- Dual-mode: standalone HS256 JWT OR Artemis RS256 JWT
- Admin role for registration code management

### FR-6: Artemis Integration

- Implements Artemis Module Contract
- Widget: today's tasks count and top priority task
- Agent tools: `create_task`, `get_todays_tasks`, `create_goal`, `get_goals`, `get_weekly_summary`
- Data endpoints: `task_schedule`, `goals_progress`

## Non-Functional Requirements

| Requirement | Target |
|-------------|--------|
| Response time | < 200ms p95 |
| Offline availability | Full read access; writes queue for sync |
| Auth security | bcrypt passwords, JWT expiry 24h |
| Data isolation | Per-user; no cross-user data access |

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Frontend | Flutter 3.x, Dart |
| Local DB | sembast (offline cache) |
| State | Service locator + repositories |
| Backend | FastAPI, Python 3.11+ |
| Auth | bcrypt + HS256 JWT (standalone), RS256 (Artemis mode) |
| DB (prod) | PostgreSQL via RDS |
| DB (dev) | SQLite |
| Port | 8040 |

## Development Phases

| Phase | Scope | Status |
|-------|-------|--------|
| 1 — Core | Goals, plans, day planner, week planner, auth | Complete |
| 2 — Artemis | Module contract, widget, agent tools | In progress |
| 3 — Intelligence | AI-suggested plans, goal insights | Planned |
