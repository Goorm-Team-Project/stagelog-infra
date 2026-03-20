# Auth Deploy TODO

## 1) GitHub Secrets 등록

### stagelog-auth repo
- [ ] `AWS_GITHUB_ACTIONS_ROLE_ARN`

### stagelog-infra repo
- [ ] auth lambda bootstrap용 Terraform apply에 필요한 secret/var 준비 여부 확인

## 2) Terraform bootstrap 선행값 준비

- [ ] `1-permanent/terraform.tfvars` 또는 `TF_VAR_*`로 bootstrap artifact 경로 준비
  - [ ] `auth_lambda_s3_key`
  - [ ] `authorizer_lambda_s3_key`
- [ ] bootstrap artifact가 실제로 S3 bucket에 존재하는지 확인
- [ ] auth lambda SSM prefix 값 준비
  - [ ] `/stagelog/dev/shared/*`
  - [ ] `/stagelog/dev/auth-lambda/*`

## 3) Terraform 반영 전 선행 수정

- [ ] `/home/woosupar/stagelog-infra/1-permanent/waf.tf` 이름 규칙 오류 수정
- [ ] 현재 오류: `Global=API-WAF` (허용되지 않는 문자 `=`)

## 4) Terraform 계획/적용

- [ ] `cd /home/woosupar/stagelog-infra/1-permanent`
- [ ] `terraform init`
- [ ] `terraform validate`
- [ ] `terraform plan`
- [ ] `terraform apply`
- [ ] 이후 auth lambda 리소스의 코드 필드는 `ignore_changes`로 CI 배포와 충돌하지 않는지 확인

## 5) Auth CI 코드 배포 검증

- [ ] `stagelog-auth` push 또는 수동 실행
- [ ] `aws lambda update-function-code` 성공 확인
- [ ] `stagelog-auth-api`
- [ ] `stagelog-auth-authorizer`

## 6) 배포 후 기능 검증

- [ ] `POST /api/auth/login/{provider}`
- [ ] `GET /api/auth/keep`
- [ ] `POST /api/auth/refresh` (cookie refresh_token)
- [ ] `POST /api/auth/logout`
- [ ] logout 직후 access token 차단(authorizer + redis blacklist)

## 7) 운영 안정화

- [ ] CloudWatch 로그/알람 연결
- [ ] Redis 블랙리스트 조회 정책 확정 (`fail-open` vs `fail-closed`)
- [ ] 쿠키 속성 운영값 점검 (`Secure`, `SameSite`, `Domain`)
