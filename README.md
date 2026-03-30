# Stagelog Infra

`stagelog-infra`는 Stagelog 서비스의 AWS 인프라와 EKS 운영 구성을 Terraform으로 관리하는 레포입니다.

이 레포는 인프라를 수명주기 기준으로 나눕니다.
- `0-*`: bootstrap 성격의 보조 스택
- `1-permanent`: 오래 유지되는 기반 인프라
- `2-eks`: EKS 클러스터와 클러스터 운영 구성
- `3-ephemeral`: EKS 상단의 교체 가능한 API 계층

## 디렉터리 구조
- `0-bastion-access`
  - Bastion 접속용 보조 리소스
- `0-ssm-params`
  - 앱과 Lambda가 사용하는 SSM Parameter Store 값 관리
  - 서비스별 파라미터를 소스 오브 트루스로 유지
- `1-permanent`
  - 장기 유지 대상 인프라
  - VPC, Subnet, Route Table, Security Group
  - S3, CloudFront, Route53, ACM, WAF
  - Redis, DynamoDB, EventBridge, SQS
  - auth Lambda, GitHub Actions IAM role
  - Gateway VPC Endpoint
- `2-eks`
  - EKS 클러스터와 클러스터 운영 구성
  - managed node group, add-on, IRSA, NAT Gateway
  - ALB Controller, ArgoCD, Karpenter
  - Interface VPC Endpoint
- `3-ephemeral`
  - API Gateway와 VPC Link
  - Lambda authorizer 연동
  - internal ALB를 upstream으로 사용하는 API 계층

## 스택 역할
### `1-permanent`
- EKS가 없어도 유지되는 리소스를 관리합니다.
- 프론트 정적 자산, 업로드 버킷, DNS, 인증서, WAF, 알림 저장소와 이벤트 버스를 포함합니다.
- 비용이 거의 없고 VPC 기본 네트워크 성격이 강한 `S3`, `DynamoDB` Gateway Endpoint를 이 스택에서 관리합니다.

### `2-eks`
- 클러스터 자체와 클러스터 운영에 필요한 부속 리소스를 관리합니다.
- 워크로드용 IAM role, ALB Controller, ArgoCD, Karpenter를 포함합니다.
- 클러스터가 떠 있을 때만 필요한 `STS`, `ECR`, `Logs`, `SQS`, `EventBridge` Interface Endpoint를 이 스택에서 관리합니다.

### `3-ephemeral`
- EKS ingress가 실제로 존재할 때만 의미가 있는 상위 API 계층을 관리합니다.
- API Gateway, VPC Link, Lambda authorizer를 포함합니다.
- 교체 비용이 상대적으로 낮고, 클러스터 재생성 시 함께 재구성되는 리소스를 여기에 둡니다.

## 현재 인프라 흐름
1. `0-ssm-params`가 서비스별 SSM 파라미터를 준비합니다.
2. `1-permanent`가 기반 네트워크와 장기 유지 리소스를 생성합니다.
3. `2-eks`가 EKS 클러스터, 노드, 컨트롤러, 클러스터 운영용 리소스를 생성합니다.
4. GitOps/ArgoCD가 백엔드 앱과 ingress를 배포합니다.
5. `3-ephemeral`이 internal ALB를 upstream으로 삼아 API Gateway를 구성합니다.
6. `1-permanent`의 CloudFront는 `3-ephemeral` output이 존재할 때만 `/api/*` origin을 연결합니다.

## 환경변수와 시크릿
운영 환경변수는 `.env` 파일을 직접 배포하지 않고, `0-ssm-params`에서 개별 SSM 파라미터로 관리합니다.

주요 prefix 예시:
- `/stagelog/dev/shared/*`
- `/stagelog/dev/auth/*`
- `/stagelog/dev/events/*`
- `/stagelog/dev/posts/*`
- `/stagelog/dev/notifications/*`
- `/stagelog/dev/outbox-worker/*`
- `/stagelog/dev/auth-lambda/*`
- `/stagelog/dev/bootstrap/auth-lambda/*`

애플리케이션은 SSM을 직접 읽지 않고, ExternalSecret이 필요한 키만 Kubernetes Secret으로 동기화한 뒤 환경변수로 주입받습니다.

## 적용 순서
일반적인 apply 순서는 아래와 같습니다.

1. `0-ssm-params`
2. `1-permanent`
3. `2-eks`
4. ArgoCD bootstrap 및 앱 배포
5. `3-ephemeral`
6. 필요 시 `1-permanent` 재적용

마지막에 `1-permanent`를 다시 보는 이유는 CloudFront가 `3-ephemeral` output을 참조해 `/api/*` origin을 구성하기 때문입니다.

## 운영 시 주의점
- `3-ephemeral` state가 비어 있으면 CloudFront는 정적 프론트 origin만 유지하고 `/api/*` behavior는 생성하지 않습니다.
- `2-eks`의 일부 data source는 ingress controller가 실제로 ALB를 만든 뒤에야 유효합니다.
- 서비스 코드의 EventBridge `source` 값과 infra rule filter가 어긋나면 알림 이벤트가 SQS에 도달하지 못할 수 있습니다.
- IRSA role 이름과 ServiceAccount annotation이 어긋나면 `AssumeRoleWithWebIdentity` 오류가 납니다.
- Interface VPC Endpoint는 `2-eks` 수명주기에 맞춰 관리하므로, 클러스터를 내리면 함께 정리되는 것이 정상입니다.

## 관련 레포
- 앱 코드: `stagelog-auth-user`, `stagelog-events`, `stagelog-posts`, `stagelog-notifications`, `stagelog-outbox-worker`
- 공용 패키지: `stagelog-shared`
- 배포 매니페스트: `stagelog-gitops`
- Lambda 코드: `stagelog-auth`
