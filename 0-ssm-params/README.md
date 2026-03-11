# 0-ssm-params

SSM Parameter Store only stack for `stagelog-backend-migration` runtime configuration.

## What this stack creates
- String params for:
  - `core-api`
  - `events-api`
  - `auth-api`
  - `outbox-worker`
  - `notification-consumer`
- SecureString params for secrets:
  - `SECRET_KEY`
  - `DB_PASSWORD_CORE`
  - `DB_PASSWORD_AUTH`
  - `DB_PASSWORD_EVENTS`

## Path convention
- `/<project>/<environment>/<service>/<KEY>`
- Example: `/stagelog/dev/core-api/DB_HOST`

## Apply
```bash
cd /home/woosupar/stagelog-infra/0-ssm-params
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Redis Host Sync (ephemeral Redis lifecycle)
When Redis is managed in `2-ephemeral`, keep SSM `REDIS_HOST` in sync:

```bash
# after 2-ephemeral apply (auto-detect endpoint from terraform output)
/home/woosupar/stagelog-infra/0-ssm-params/scripts/sync_redis_host.sh set \
  --project stagelog --env dev --region ap-northeast-2

# or pass endpoint explicitly
/home/woosupar/stagelog-infra/0-ssm-params/scripts/sync_redis_host.sh set \
  --endpoint <redis-endpoint> --project stagelog --env dev --region ap-northeast-2

# after 2-ephemeral destroy
/home/woosupar/stagelog-infra/0-ssm-params/scripts/sync_redis_host.sh clear \
  --project stagelog --env dev --region ap-northeast-2
```
