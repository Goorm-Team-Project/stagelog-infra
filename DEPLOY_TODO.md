# Auth Deploy TODO

## 1) GitHub Secrets 등록

### stagelog-auth repo
- [ ] `AWS_GITHUB_ACTIONS_ROLE_ARN`
- [ ] `AUTH_LAMBDA_ARTIFACT_BUCKET`

### stagelog-infra repo
- [ ] `TF_VAR_auth_lambda_s3_bucket`
- [ ] `TF_VAR_auth_lambda_s3_key`
- [ ] `TF_VAR_authorizer_lambda_s3_key`
- [ ] `TF_VAR_jwt_secret_key`
- [ ] `TF_VAR_db_host`
- [ ] `TF_VAR_db_user`
- [ ] `TF_VAR_db_password`
- [ ] `TF_VAR_db_name`
- [ ] `TF_VAR_redis_host`
- [ ] `TF_VAR_redis_password`
- [ ] `TF_VAR_kakao_rest_api_key`
- [ ] `TF_VAR_kakao_access_token_client_secret`
- [ ] `TF_VAR_kakao_redirect_uri`
- [ ] `TF_VAR_google_rest_api_key`
- [ ] `TF_VAR_google_access_token_client_secret`
- [ ] `TF_VAR_google_redirect_uri`
- [ ] `TF_VAR_naver_rest_api_key`
- [ ] `TF_VAR_naver_access_token_client_secret`
- [ ] `TF_VAR_naver_redirect_uri`
- [ ] `TF_VAR_api_domain_certificate_arn`
- [ ] `TF_VAR_core_api_url`
- [ ] `TF_VAR_ingress_alb_https_listener_arn` (or `TF_VAR_ingress_alb_arn`)

## 2) Auth CI 워크플로 활성화

- [ ] `/home/woosupar/stagelog-auth/.github/workflows/build-and-upload-lambda.yml`
- [ ] `if: ${{ false }}` 제거
- [ ] 필요 시 `on.push.branches` 추가

## 3) Lambda Artifact 업로드 확인

- [ ] 워크플로 실행 후 S3 업로드 성공 확인
- [ ] 업로드된 key를 infra 변수에 반영
  - [ ] `auth_lambda_s3_key`
  - [ ] `authorizer_lambda_s3_key`

## 4) Terraform 반영 전 선행 수정

- [ ] `/home/woosupar/stagelog-infra/1-permanent/waf.tf` 이름 규칙 오류 수정
- [ ] 현재 오류: `Global=API-WAF` (허용되지 않는 문자 `=`)

## 5) Terraform 계획/적용

- [ ] `cd /home/woosupar/stagelog-infra/1-permanent`
- [ ] `terraform init`
- [ ] `terraform validate`
- [ ] `terraform plan`
- [ ] `terraform apply`

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
