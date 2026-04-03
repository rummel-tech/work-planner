# Work Planner — Architecture

## System Overview

```
work-planner/ (Flutter app)
        │
        ▼
services/work-planner/ (FastAPI :8040)
        │
        ├── PostgreSQL (prod) / SQLite (dev)
        └── services/common/ (shared utilities)
```

## Frontend Architecture

**Pattern**: Service locator + repository pattern with manual dependency injection.

```
main.dart
  └── ServiceLocator.setup()
        ├── AuthService
        ├── ApiService
        ├── DatabaseService (sembast — offline cache)
        ├── GoalRepository
        ├── PlanRepository
        └── PlannerRepository
```

### Key Files

| File | Role |
|------|------|
| `lib/main.dart` | App init, service locator setup, routing |
| `lib/services/service_locator.dart` | Dependency injection container |
| `lib/services/auth_service.dart` | JWT storage, login/logout, token refresh |
| `lib/services/api_service.dart` | HTTP client (backend calls) |
| `lib/services/database_service.dart` | sembast offline DB |
| `lib/services/goal_repository.dart` | Goal CRUD (online + offline) |
| `lib/services/plan_repository.dart` | Plan CRUD (online + offline) |
| `lib/services/planner_repository.dart` | Day/week planner CRUD |
| `lib/services/connectivity_notifier.dart` | Online/offline state |

### Offline Strategy

1. Repositories write to local sembast DB immediately
2. Background sync posts queued changes to backend when online
3. Reads prefer local cache; stale indicator shown when offline
4. Platform-specific DB factory: `db_factory_io.dart` (native) / `db_factory_web.dart` (IndexedDB)

### Routing

Routes (via `go_router` or named routes):
- `/welcome` — landing/onboarding
- `/login` — login form
- `/register` — registration (requires invite code)
- `/home` — day planner (main screen)
- `/goals` — goal list
- `/goals/:id` — goal detail
- `/plans` — plan list
- `/week` — week planner

## Backend Architecture

**Service**: `services/work-planner/` — FastAPI, Python 3.11+

### Structure

```
services/work-planner/
├── main.py                 # App entry
├── core/
│   ├── settings.py         # Config (DATABASE_URL, JWT_SECRET, PORT=8040)
│   ├── database.py         # SQLite/PostgreSQL dual-mode
│   └── auth.py             # bcrypt + HS256 JWT
├── routers/
│   ├── auth.py             # /auth/register, /auth/login, /auth/refresh
│   ├── goals.py            # /goals CRUD
│   ├── plans.py            # /plans CRUD
│   ├── planners.py         # /day-planners, /week-planners
│   ├── tasks.py            # /tasks CRUD
│   └── artemis.py          # Artemis module contract endpoints
├── models/                 # Pydantic models
├── tests/                  # 5 test files, ~687 lines
└── migrate_db.py           # PostgreSQL migration script
```

### Database Schema

| Table | Purpose |
|-------|---------|
| `users` | User accounts with email/password |
| `registration_codes` | Invite codes for controlled rollout |
| `waitlist` | Pre-registration email list |
| `goals` | Work and personal goals |
| `plans` | Multi-step plans linked to goals |
| `day_planners` | One record per user per date |
| `tasks` | Time-blocked tasks within day planners |
| `week_planners` | Weekly intentions, one per user per week |

### Auth: Dual-Mode

```python
# routers/artemis.py
def require_token(token):
    # Try Artemis RS256 first (fetched from auth:8090)
    # Fall back to standalone HS256
    # Raise 401 if neither validates
```

### Artemis Contract Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/artemis/manifest` | GET | Module metadata, widget defs, agent tools |
| `/artemis/widget` | GET | Today's tasks count + top priority task |
| `/artemis/tools/create_task` | POST | Agent: create a task |
| `/artemis/tools/get_todays_tasks` | GET | Agent: list today's tasks |
| `/artemis/tools/create_goal` | POST | Agent: create a goal |
| `/artemis/data/task_schedule` | GET | Data: task timeline |
| `/artemis/data/goals_progress` | GET | Data: goal completion metrics |

## Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management (if used) |
| `sembast` | Local NoSQL DB for offline cache |
| `go_router` | Navigation |
| `dio` / `http` | HTTP client |
| `shared_preferences` | JWT token storage |
| `connectivity_plus` | Network state detection |
