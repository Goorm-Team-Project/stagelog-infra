#!/bin/bash
set -e

DB_ID="stagelog-db-managed"
REPO_BACK="Goorm-Team-Project/stagelog-backend"
REPO_FRONT="Goorm-Team-Project/stagelog-frontend"
DIR_EPHEM="./2-ephemeral"

LOCK_FILE=".deployed"

if [ -f "$LOCK_FILE" ]; then
  echo "🚫 [경고] 이미 배포가 완료된 상태입니다!"
  echo "   (다시 배포하려면 'make down'을 하거나, '$LOCK_FILE' 파일을 삭제하세요.)"
  exit 1
fi

echo "Github CLI 로그인 상태를 확인합니다."
if ! gh auth status > /dev/null 2>&1; then
  echo "Error: GitHub CLI에 로그인이 되어 있지 않습니다."
  echo "터미널에 'gh auth login'을 입력해서 먼저 로그인해주세요."
  exit 1
fi
echo "로그인 확인 완료."

echo "AWS CLI 접근 권한을 확인합니다."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
  echo "Error: AWS에 접근할 수 없습니다."
  echo "'aws configure'로 자격 증명이 설정되었는지 확인하세요."
  exit 1
fi
echo "AWS 연결 확인 완료."

echo "RDS를 실행합니다."
aws rds start-db-instance --db-instance-identifier $DB_ID > /dev/null 2>&1 || true

echo "Terraform이 인프라를 생성합니다."
cd $DIR_EPHEM
terraform apply -auto-approve
cd ..

echo "RDS가 실행될 때 까지 대기..."
aws rds wait db-instance-available --db-instance-identifier $DB_ID
echo "RDS 준비 완료."

echo "백엔드 배포를 시작합니다."
gh workflow run api-cicd.yaml --repo $REPO_BACK --ref develop

echo "프론트 배포를 시작합니다."
gh workflow run frontend-cicd.yml --repo $REPO_FRONT --ref develop

echo "============================================================"
echo "작업이 완료 되었습니다."

touch "$LOCK_FILE"