# 0-ssm-params

SSM Parameter Store only stack for unified runtime configuration of `stagelog-backend-migration`.

## What this stack creates
- String params under one service path (`service_name`, default: `migration`)
- SecureString params for secrets:
  - `SECRET_KEY`
  - `DB_PASSWORD_CORE`
  - `DB_PASSWORD_AUTH`
  - `DB_PASSWORD_EVENTS`
- Unified SecureString `.env` parameter for ExternalSecret file mount:
  - default: `/stagelog/backend/.env`

## Path convention
- `/<project>/<environment>/<service_name>/<KEY>`
- Example: `/stagelog/dev/migration/DB_HOST`
- Unified `.env` path (separate, fixed by variable):
  - default: `/stagelog/backend/.env`

## Apply
```bash
cd /home/woosupar/stagelog-infra/0-ssm-params
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
  --project stagelog --env dev --service migration --region ap-northeast-2

# or pass endpoint explicitly
/home/woosupar/stagelog-infra/0-ssm-params/scripts/sync_redis_host.sh set \
  --endpoint <redis-endpoint> --project stagelog --env dev --service migration --region ap-northeast-2

# after 2-ephemeral destroy
/home/woosupar/stagelog-infra/0-ssm-params/scripts/sync_redis_host.sh clear \
  --project stagelog --env dev --service migration --region ap-northeast-2
```
