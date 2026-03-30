# 0-ssm-params

SSM Parameter Store stack for split `stagelog` services.

## What this stack creates
- Individual String parameters under scoped paths:
  - `shared`
  - `auth`
  - `events`
  - `posts`
  - `notifications`
  - `outbox-worker`
  - `auth-lambda`
- SecureString params for secrets:
  - `/stagelog/dev/shared/SECRET_KEY`
  - `/stagelog/dev/auth/DB_PASSWORD_AUTH`
  - `/stagelog/dev/events/DB_PASSWORD_EVENTS`
  - `/stagelog/dev/posts/DB_PASSWORD_POSTS`
  - `/stagelog/dev/notifications/DB_PASSWORD_NOTIFICATIONS`
  - `/stagelog/dev/auth-lambda/JWT_SECRET_KEY`
  - `/stagelog/dev/auth-lambda/KAKAO_REST_API_KEY`
- No unified `.env` SecureString is created.
  Each app `ExternalSecret` now pulls only the keys it needs and renders its own `.env` file.
  Auth Lambda reads SSM prefixes directly at cold start.

## Path convention
- Shared runtime values:
  - `/<project>/<environment>/shared/<KEY>`
  - example: `/stagelog/dev/shared/REDIS_HOST`
- App-specific runtime values:
  - `/<project>/<environment>/<app>/<KEY>`
  - example: `/stagelog/dev/posts/DB_NAME_POSTS`
  - example: `/stagelog/dev/notifications/NOTIFICATION_SQS_QUEUE_URL`
  - example: `/stagelog/dev/auth-lambda/JWT_SECRET_KEY`

## Apply
```bash
cd /home/woosupar/stagelog-infra/0-ssm-params
terraform init
terraform plan
terraform apply
```

## Redis Host Sync (ephemeral Redis lifecycle)
When Redis is managed in `2-ephemeral`, keep shared `REDIS_HOST` in sync:

```bash
# after 2-ephemeral apply (auto-detect endpoint from terraform output)
/home/woosupar/stagelog-infra/0-ssm-params/scripts/sync_redis_host.sh set \
  --project stagelog --env dev --scope shared --region ap-northeast-2

# or pass endpoint explicitly
/home/woosupar/stagelog-infra/0-ssm-params/scripts/sync_redis_host.sh set \
  --endpoint <redis-endpoint> --project stagelog --env dev --scope shared --region ap-northeast-2

# after 2-ephemeral destroy
/home/woosupar/stagelog-infra/0-ssm-params/scripts/sync_redis_host.sh clear \
  --project stagelog --env dev --scope shared --region ap-northeast-2
```
