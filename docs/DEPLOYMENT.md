# Work Planner — Deployment

## Deployment Targets

| Target | Method |
|--------|--------|
| Web (GitHub Pages) | GitHub Actions via `infrastructure/.github/workflows/deploy-work-planner-frontend.yml` |
| Android | Manual / Play Store |
| iOS | Manual / App Store |
| Backend (ECS) | `infrastructure/.github/workflows/deploy-work-planner-backend.yml` |

## Backend Deployment

**ECS task definition**: `infrastructure/aws/ecs-task-definitions/work-planner.json`
- CPU: 256, Memory: 512 MB
- Port: 8040
- Secrets from AWS Secrets Manager: `work-planner/database-url`, `work-planner/jwt-secret`

**Deploy:**
```bash
gh workflow run deploy-services.yml \
  --repo rummel-tech/services \
  -f service=work-planner -f environment=production
```

**Run database migrations:**
```bash
TASK=$(aws ecs list-tasks --cluster app-cluster \
  --service-name work-planner-service \
  --region us-east-1 --query 'taskArns[0]' --output text)

aws ecs execute-command --cluster app-cluster --task $TASK \
  --container work-planner \
  --command "python migrate_db.py" --interactive
```

## Secrets Setup

Add these to AWS Secrets Manager before deploying:

```bash
aws secretsmanager create-secret \
  --name work-planner/database-url \
  --secret-string "postgresql://user:pass@rds-host:5432/work_planner_db" \
  --region us-east-1

aws secretsmanager create-secret \
  --name work-planner/jwt-secret \
  --secret-string "$(openssl rand -hex 32)" \
  --region us-east-1
```

## Frontend Deployment

### Web (GitHub Pages)

```bash
cd work-planner
flutter build web --release \
  --dart-define=API_BASE_URL=http://<ECS_IP>:8040
```

Set GitHub Secrets in `rummel-tech/work-planner`:
- `API_BASE_URL` — backend public URL

### iOS / Android

```bash
flutter build ios --release
flutter build appbundle --release
```

## Environment Configuration

### Development `.env`

```bash
DATABASE_URL=sqlite:///work_dev.db
JWT_SECRET=dev-secret-key-change-in-production
ENVIRONMENT=development
PORT=8040
REDIS_ENABLED=false
CORS_ORIGINS=["http://localhost:3000","http://localhost:8080"]
```

## Health Check

```bash
curl http://localhost:8040/health
# {"status":"healthy","service":"work-planner"}
```

## Smoke Test Checklist

After deployment:
- [ ] `GET /health` returns healthy
- [ ] Register with invite code; login succeeds
- [ ] Create a goal; create a plan linked to it
- [ ] Add tasks to today's day planner
- [ ] Week planner loads with correct week dates
- [ ] Artemis: `GET /artemis/manifest` returns module definition
- [ ] Artemis: `GET /artemis/widget` returns today's task count
