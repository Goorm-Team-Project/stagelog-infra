#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  sync_redis_host.sh set   [--endpoint <redis-endpoint>] [--project stagelog] [--env dev] [--region ap-northeast-2]
  sync_redis_host.sh clear [--project stagelog] [--env dev] [--region ap-northeast-2]

Behavior:
  - set:   Writes REDIS_HOST to SSM for api + notification-consumer.
           If --endpoint is omitted, tries terraform output from ../2-ephemeral.
  - clear: Writes REDIS_HOST as empty string for api + notification-consumer.
USAGE
}

MODE="${1:-}"
if [[ -z "$MODE" ]]; then
  usage
  exit 1
fi
shift || true

PROJECT="stagelog"
ENVIRONMENT="dev"
REGION="ap-northeast-2"
ENDPOINT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --endpoint)
      ENDPOINT="${2:-}"
      shift 2
      ;;
    --project)
      PROJECT="${2:-}"
      shift 2
      ;;
    --env)
      ENVIRONMENT="${2:-}"
      shift 2
      ;;
    --region)
      REGION="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ "$MODE" != "set" && "$MODE" != "clear" ]]; then
  echo "MODE must be one of: set, clear"
  usage
  exit 1
fi

TF_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EPHEMERAL_DIR="$TF_ROOT/2-ephemeral"

if [[ "$MODE" == "set" && -z "$ENDPOINT" ]]; then
  if command -v terraform >/dev/null 2>&1 && [[ -d "$EPHEMERAL_DIR" ]]; then
    # Try common output names in order.
    for out_name in redis_primary_endpoint redis_endpoint redis_host elasticache_primary_endpoint; do
      if ENDPOINT_VAL=$(terraform -chdir="$EPHEMERAL_DIR" output -raw "$out_name" 2>/dev/null); then
        if [[ -n "$ENDPOINT_VAL" ]]; then
          ENDPOINT="$ENDPOINT_VAL"
          break
        fi
      fi
    done
  fi
fi

if [[ "$MODE" == "set" && -z "$ENDPOINT" ]]; then
  echo "Could not resolve Redis endpoint automatically."
  echo "Provide --endpoint <redis-endpoint> or expose a redis output in 2-ephemeral."
  exit 1
fi

if [[ "$MODE" == "clear" ]]; then
  ENDPOINT=""
fi

PARAM_API="/${PROJECT}/${ENVIRONMENT}/api/REDIS_HOST"
PARAM_NOTI="/${PROJECT}/${ENVIRONMENT}/notification-consumer/REDIS_HOST"

for p in "$PARAM_API" "$PARAM_NOTI"; do
  aws ssm put-parameter \
    --name "$p" \
    --type String \
    --value "$ENDPOINT" \
    --overwrite \
    --region "$REGION" \
    >/dev/null
  echo "Updated $p"
done

if [[ -n "$ENDPOINT" ]]; then
  echo "REDIS_HOST set to: $ENDPOINT"
else
  echo "REDIS_HOST cleared (empty string)."
fi
