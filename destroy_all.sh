#!/bin/bash
set -e

DB_ID="stagelog-db-managed"
DIR_EPHEM="./2-ephemeral"

LOCK_FILE=".deployed"

if [ ! -f "$LOCK_FILE" ]; then
  echo "🚫 [경고] 삭제할 인프라가 없거나, 이미 삭제된 상태입니다."
  echo "   (강제로 실행하려면 '$LOCK_FILE' 파일을 생성하고 다시 시도하세요.)"
  exit 1
fi

echo "AWS CLI 접근 권한을 확인합니다."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
  echo "Error: AWS에 접근할 수 없습니다."
  echo "'aws configure'로 자격 증명이 설정되었는지 확인하세요."
  exit 1
fi
echo "AWS 연결 확인 완료."

echo "Terraform이 인프라를 삭제합니다."
cd $DIR_EPHEM
terraform destroy -auto-approve
cd ..

echo "RDS를 일시 정지 합니다."
aws rds stop-db-instance --db-instance-identifier $DB_ID > /dev/null 2>&1 || true

echo "============================================================"
echo "작업이 완료 되었습니다."

rm -f "$LOCK_FILE"
