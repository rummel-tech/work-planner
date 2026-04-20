# Work Planner — Non-Functional Requirements Traceability Matrix

Maps each non-functional requirement from the product description (OBJECTIVES.md) through specification, automated tests, implementation, and release verification.

---

## Traceability Chain

```
OBJECTIVES.md (product description)
    → ARCHITECTURE.md / DEPLOYMENT.md (specification)
        → Backend tests (services/work-planner/tests/)
        → Flutter tests (test/)
            → Source implementation
                → DEPLOYMENT.md smoke test (release gate)
```

---

## How to Read This Matrix

| Column | Meaning |
|--------|---------|
| **ID** | NFR identifier |
| **Requirement** | The measurable property |
| **Product Spec** | OBJECTIVES.md NFR entry |
| **Defined In** | Detailed spec file |
| **Tests** | Automated tests that validate it |
| **Implementation** | Source files / config that enforce it |
| **Release Gate** | DEPLOYMENT.md smoke test step |

---

## NFR-1 · Performance

| ID | Requirement | Product Spec | Defined In | Tests | Implementation | Release Gate |
|----|-------------|-------------|------------|-------|----------------|--------------|
| NFR-1.1 | API p95 response time ≤ 200 ms under normal load | OBJECTIVES.md NFR table: "Response time < 200ms p95" | ARCHITECTURE.md §Backend | None — requires load testing (Locust/k6) | `core/metrics.py` · `core/database.py` (connection pool) · ECS 256 CPU / 512 MB | — |
| NFR-1.2 | Day planner screen renders without jank on first load | OBJECTIVES.md NFR table | WORKFLOWS.md §5 (route `/day`) | `day_planner_screen_test` — pump-and-settle within test timeout | `lib/src/screens/daily/day_planner_screen.dart` · `lib/src/planners/day_planner.dart` | — |
| NFR-1.3 | Database queries use indexed columns (user\_id, date, goal\_id) | OBJECTIVES.md NFR table | ARCHITECTURE.md §Database Schema | None — relies on PostgreSQL EXPLAIN | `migrate_db.py` · `core/database.py` | — |
| NFR-1.4 | Artemis widget cache TTL: 5 min (todays\_tasks), 60 min (weekly\_progress) | — | ARCHITECTURE.md §Artemis | None — client-side cache TTL | `routers/artemis.py` (`refresh_seconds: 300 / 3600` in manifest) | `GET /artemis/manifest` returns module definition |

---

## NFR-2 · Security — Password Storage

| ID | Requirement | Product Spec | Defined In | Tests | Implementation | Release Gate |
|----|-------------|-------------|------------|-------|----------------|--------------|
| NFR-2.1 | Passwords stored as bcrypt hashes; never plaintext | OBJECTIVES.md NFR table: "bcrypt passwords" | ARCHITECTURE.md §Auth | `test_register_success`, `test_login_success` (hash round-trip implied by login succeeding after registration) | `core/auth_service.py` — `hash_password()` (bcrypt salt + hash), `verify_password()` | — |
| NFR-2.2 | Plaintext passwords never returned by any API endpoint | OBJECTIVES.md NFR table | ARCHITECTURE.md §Auth | `test_me` (response contains no password field) | `routers/auth.py` · Pydantic response schemas (password field excluded) | — |

---

## NFR-3 · Security — JWT Token Management

| ID | Requirement | Product Spec | Defined In | Tests | Implementation | Release Gate |
|----|-------------|-------------|------------|-------|----------------|--------------|
| NFR-3.1 | Access tokens expire after 24 hours | OBJECTIVES.md NFR table: "JWT expiry 24h" | ARCHITECTURE.md §Auth · WORKFLOWS.md §3 | `test_login_success` (token issued), `test_me` (token accepted) | `core/auth_service.py` — `ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24` | — |
| NFR-3.2 | Standalone tokens signed with HS256 | OBJECTIVES.md NFR table | ARCHITECTURE.md §Auth Dual-Mode | `test_login_success` | `core/auth_service.py` — `ALGORITHM = 'HS256'` | — |
| NFR-3.3 | Artemis platform tokens accepted via RS256 (dual-mode) | OBJECTIVES.md FR-5: "Dual-mode: standalone HS256 JWT OR Artemis RS256 JWT" | ARCHITECTURE.md §Auth Dual-Mode | None — gap; needs integration test with mocked RS256 token | `routers/artemis.py` · `common/artemis_auth.py` — `create_artemis_token_dependency()` | — |
| NFR-3.4 | Logout adds token to Redis blacklist | OBJECTIVES.md NFR table | ARCHITECTURE.md §Auth · WORKFLOWS.md §3 | `test_logout` | `routers/auth.py` · `core/redis_client.py` — `blacklist_token()`, `is_token_blacklisted()` | — |
| NFR-3.5 | JWT secret loaded from AWS Secrets Manager in production | — | DEPLOYMENT.md §Secrets Setup | None — infra-level | `core/settings.py` · `infrastructure/aws/ecs-task-definitions/work-planner.json` (`work-planner/jwt-secret`) | — |

---

## NFR-4 · Security — Rate Limiting

| ID | Requirement | Product Spec | Defined In | Tests | Implementation | Release Gate |
|----|-------------|-------------|------------|-------|----------------|--------------|
| NFR-4.1 | Registration: 5 requests/minute per IP | — | `routers/auth.py` source | None — gap; needs HTTP 429 assertion test | `routers/auth.py` — `REGISTER_LIMIT = '5/minute'` · `slowapi.Limiter` | — |
| NFR-4.2 | Login: 10 requests/minute per IP | — | `routers/auth.py` source | None — gap | `routers/auth.py` — `LOGIN_LIMIT = '10/minute'` · `slowapi.Limiter` | — |
| NFR-4.3 | Token refresh: 10 requests/minute per IP | — | `routers/auth.py` source | None — gap | `routers/auth.py` — `REFRESH_LIMIT = '10/minute'` | — |
| NFR-4.4 | Logout: 20 requests/minute per IP | — | `routers/auth.py` source | None — gap | `routers/auth.py` — `LOGOUT_LIMIT = '20/minute'` | — |
| NFR-4.5 | Rate limits disabled (10 000/min no-op) when `REDIS_ENABLED=false` | — | DEPLOYMENT.md §Environment Config | None | `routers/auth.py` — conditional limiter · `core/settings.py` | — |

---

## NFR-5 · Data Isolation

| ID | Requirement | Product Spec | Defined In | Tests | Implementation | Release Gate |
|----|-------------|-------------|------------|-------|----------------|--------------|
| NFR-5.1 | All data scoped per user — no cross-user access possible | OBJECTIVES.md NFR table: "Per-user; no cross-user data access" | ARCHITECTURE.md §Database Schema | `test_list_goals_empty`, `test_list_day_planners_empty`, `test_list_plans_empty` (each user starts with empty state; no bleed-through from fixtures) | All routers filter by `current_user.user_id` — `routers/goals.py`, `routers/plans.py`, `routers/planners.py`, `routers/tasks.py` | — |
| NFR-5.2 | Admin role required to view or generate registration codes | OBJECTIVES.md FR-5 | ARCHITECTURE.md §Backend | None — gap; no `test_admin_*` tests exist | `routers/auth.py` — `get_admin_user()` dependency on `POST /admin/codes`, `GET /admin/codes` | — |

---

## NFR-6 · Availability — Offline-First

| ID | Requirement | Product Spec | Defined In | Tests | Implementation | Release Gate |
|----|-------------|-------------|------------|-------|----------------|--------------|
| NFR-6.1 | App fully usable with no network (reads from local cache) | OBJECTIVES.md objective 5 + NFR table: "Full read access; writes queue for sync" | WORKFLOWS.md §4 · ARCHITECTURE.md §Offline | `offline_sync_workflow_test` — all GoalRepository and PlannerRepository cache-layer tests | `lib/src/services/goal_repository.dart` · `lib/src/services/plan_repository.dart` · `lib/src/services/planner_repository.dart` · `lib/src/services/database_service.dart` (Sembast) | — |
| NFR-6.2 | Writes queue locally when offline and sync to backend when reconnected | OBJECTIVES.md NFR table | WORKFLOWS.md §4 | `offline_sync_workflow_test` — "save persists a goal and getById retrieves it", "save updates an existing goal (upsert)" | `lib/src/services/goal_repository.dart` · `lib/src/services/plan_repository.dart` · `lib/src/services/planner_repository.dart` | — |
| NFR-6.3 | Stale-data indicator shown when serving from cache | OBJECTIVES.md NFR table | WORKFLOWS.md §4 | None — gap; no widget test for stale banner | `lib/src/services/connectivity_notifier.dart` · `lib/src/screens/home/home_screen.dart` | — |
| NFR-6.4 | Platform-specific DB factory (native IO vs. browser IndexedDB) | — | ARCHITECTURE.md §Offline | None — platform-conditional at build time | `lib/src/services/db_factory_io.dart` · `lib/src/services/db_factory_web.dart` | — |
| NFR-6.5 | Conflict resolution: API response overwrites local cache on next sync | OBJECTIVES.md NFR table | WORKFLOWS.md §4 | None — gap; needs end-to-end sync test | `lib/src/services/goal_repository.dart` · `lib/src/services/planner_repository.dart` | — |

---

## NFR-7 · Deployment & Infrastructure

| ID | Requirement | Product Spec | Defined In | Tests | Implementation | Release Gate |
|----|-------------|-------------|------------|-------|----------------|--------------|
| NFR-7.1 | Backend on AWS ECS: 256 CPU units, 512 MB memory, port 8040 | — | DEPLOYMENT.md §Backend | `test_health`, `test_ready`, `test_healthz_liveness`, `test_readyz_readiness` | `infrastructure/aws/ecs-task-definitions/work-planner.json` · `core/settings.py` — `PORT=8040` | `GET /health` returns healthy |
| NFR-7.2 | Database URL injected from AWS Secrets Manager | — | DEPLOYMENT.md §Secrets | None — infra-level | `core/settings.py` · `infrastructure/aws/ecs-task-definitions/work-planner.json` (`work-planner/database-url`) | — |
| NFR-7.3 | PostgreSQL in production; SQLite in development | — | ARCHITECTURE.md §Backend · DEPLOYMENT.md | `tests/conftest.py` applies migrations to SQLite test DB | `core/database.py` — dual-mode `DATABASE_URL` · `core/settings.py` | — |
| NFR-7.4 | Frontend deployed to GitHub Pages (web) | — | DEPLOYMENT.md §Frontend | None — CI pipeline validation | `infrastructure/.github/workflows/deploy-work-planner-frontend.yml` | — |
| NFR-7.5 | Database schema managed by migration script | — | ARCHITECTURE.md §Backend | `tests/conftest.py` (migrations applied in fixture) | `migrate_db.py` | — |
| NFR-7.6 | Health and readiness probes at `/health`, `/ready`, `/healthz`, `/readyz` | — | DEPLOYMENT.md §Health Check | `test_health`, `test_ready`, `test_healthz_liveness`, `test_readyz_readiness` | Health router · `main.py` | `GET /health` returns healthy |

---

## NFR-8 · Data Integrity

| ID | Requirement | Product Spec | Defined In | Tests | Implementation | Release Gate |
|----|-------------|-------------|------------|-------|----------------|--------------|
| NFR-8.1 | Goal deletion cascades to linked plans | — | WORKFLOWS.md §1 Step 7 | `goal_execution_workflow_test` — "Step 7: delete goal also removes its linked plans" | `lib/src/services/plan_repository.dart` — `deleteByGoalId()` · `routers/goals.py` | — |
| NFR-8.2 | Day planner auto-created when first task is added (idempotent upsert) | — | WORKFLOWS.md §1 Step 3 | `offline_sync_workflow_test` — "addTask creates planner if missing" · `test_create_task_creates_day_planner_if_missing` | `lib/src/services/planner_repository.dart` — `addTask()` · `routers/planners.py` | Add tasks to today's day planner |
| NFR-8.3 | Week planner creation idempotent (same Monday → same record) | — | WORKFLOWS.md §2 | `weekly_planning_workflow_test` — "returns the same week planner on repeated calls", "normalises time component" · `test_create_week_planner_idempotent` | `lib/src/services/planner_repository.dart` · `routers/planners.py` | Week planner loads with correct week dates |
| NFR-8.4 | Duplicate email registration rejected | — | WORKFLOWS.md §3 | `test_register_duplicate_email` | `routers/auth.py` · `core/database.py` (UNIQUE constraint on `users.email`) | — |
| NFR-8.5 | Plan cannot reference a non-existent goal\_id | — | WORKFLOWS.md §1 Step 2 | `test_create_plan_invalid_goal` | `routers/plans.py` | — |

---

## Coverage Summary

| NFR Group | Items | Automated Tests | Release Gate | Gaps |
|-----------|-------|-----------------|--------------|------|
| NFR-1 Performance | 4 | Partial (Flutter pump tests only) | — | No load/p95 test |
| NFR-2 Password Security | 2 | Partial (implicit via login round-trip) | — | No explicit hash-only assertion |
| NFR-3 JWT | 5 | Partial (HS256 only) | — | RS256 dual-mode path untested |
| NFR-4 Rate Limiting | 5 | None | — | All rate limit assertions missing |
| NFR-5 Data Isolation | 2 | Partial (empty-state tests) | — | No explicit cross-user access test; no admin role test |
| NFR-6 Offline-First | 5 | Partial (cache CRUD covered; sync/conflict not) | — | Stale indicator and conflict resolution untested |
| NFR-7 Deployment | 6 | Health probes | `GET /health` | Load test, iOS CI not covered |
| NFR-8 Data Integrity | 5 | Good | 2 smoke tests | None |

> **Priority gaps to address:**
> 1. `tests/test_artemis.py` — RS256 dual-auth path (NFR-3.3)
> 2. Rate limit tests sending > threshold and asserting HTTP 429 (NFR-4.1–4.4)
> 3. Cross-user isolation test — create data as user A, assert user B gets 404 (NFR-5.1)
> 4. Admin role tests for `POST /admin/codes` and `GET /admin/codes` (NFR-5.2)
> 5. Offline stale-data banner widget test (NFR-6.3)
> 6. Load test script targeting ≤ 200 ms p95 (NFR-1.1)
