# 리소스 이름 관리 가이드

## 📋 개요

모든 리소스 이름은 **루트 `variables.tf`의 `name_prefix` 변수 하나로 통합 관리**됩니다.

## 🎯 이름 변경 방법

### 방법 1: terraform.tfvars에서 변경 (권장)

**가장 간단하고 권장되는 방법**

```hcl
# environments/oregon/terraform.tfvars
name_prefix = "my-project"
```

**결과:**
- 모든 리소스 이름이 자동으로 변경됨
- `my-project-vpc`
- `my-project-ap-alb`
- `my-project-ap-0`
- `my-project-alpha-alb`
- 등등...

---

### 방법 2: variables.tf의 기본값 변경

```hcl
# variables.tf
variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "infrakr-prod"  # 기본값 변경
}
```

---

### 방법 3: 환경별로 다른 이름 사용

```hcl
# environments/dev/terraform.tfvars
name_prefix = "infrakr-dev"

# environments/staging/terraform.tfvars
name_prefix = "infrakr-staging"

# environments/prod/terraform.tfvars
name_prefix = "infrakr-prod"
```

---

## 📝 생성되는 리소스 이름 목록

현재 `name_prefix = "infrakr-test"`일 때:

### VPC 리소스
- VPC: `infrakr-test-vpc`
- Internet Gateway: `infrakr-test-igw`
- Public Subnet (a): `infrakr-test-public-a`
- Public Subnet (c): `infrakr-test-public-c`
- Private Subnet (a): `infrakr-test-private-a`
- Private Subnet (c): `infrakr-test-private-c`
- NAT Gateway EIP (a): `infrakr-test-nat-eip-a`
- NAT Gateway EIP (c): `infrakr-test-nat-eip-c`
- NAT Gateway (a): `infrakr-test-nat-a`
- NAT Gateway (c): `infrakr-test-nat-c`
- Public Route Table: `infrakr-test-public-rt`
- Private Route Table (a): `infrakr-test-private-rt-a`
- Private Route Table (c): `infrakr-test-private-rt-c`

### EC2 인스턴스
- AP 서버 0: `infrakr-test-ap-0`
- AP 서버 1: `infrakr-test-ap-1`
- Alpha 서버 0: `infrakr-test-alpha-0`
- Alpha 서버 1: `infrakr-test-alpha-1`

### Load Balancer
- AP ALB: `infrakr-test-ap-alb`
- AP Target Group: `infrakr-test-ap-tg`
- Alpha ALB: `infrakr-test-alpha-alb`
- Alpha Target Group: `infrakr-test-alpha-tg`

### IAM
- Production Role: `infrakr-test-production-ec2-role`
- Alpha Role: `infrakr-test-alpha-ec2-role`

### VPN 리소스
- Customer Gateway: `InfraKR-cgw-nonhyun` (또는 terraform.tfvars에서 오버라이드)
- VPN Gateway: `InfraKR-vgw-oregon` (또는 terraform.tfvars에서 오버라이드)
- VPN Connection: `InfraKR-vpn-nonhyun` (또는 terraform.tfvars에서 오버라이드)

### S3 & CloudFront
- S3 Bucket: `infrakr-test-s3` (또는 terraform.tfvars에서 오버라이드)
- CloudFront Distribution: `infrakr-test-cdn` (또는 terraform.tfvars에서 오버라이드)
- CloudFront Domain: `infrakr-test.cocone.co.kr` (또는 terraform.tfvars에서 오버라이드)

---

## 🔧 특정 리소스만 다른 이름 사용하기

대부분의 리소스는 `name_prefix` 기반으로 자동 생성되지만, 특정 리소스만 다른 이름을 사용하고 싶다면:

### S3, CloudFront는 별도 변수로 오버라이드 가능

```hcl
# terraform.tfvars
name_prefix = "infrakr-test"

# 특정 리소스만 다른 이름 사용
s3_bucket_name = "my-custom-bucket"
cloudfront_distribution_name = "my-custom-cdn"
cloudfront_custom_domain = "custom.cocone.co.kr"
```

---

## ✅ 체크리스트

이름을 변경한 후 확인할 사항:

1. **terraform.tfvars 확인**
   ```bash
   cat environments/oregon/terraform.tfvars | grep name_prefix
   ```

2. **Plan 실행하여 변경사항 확인**
   ```bash
   terraform plan -var-file=environments/oregon/terraform.tfvars
   ```

3. **생성될 리소스 이름 확인**
   - Plan 출력에서 모든 리소스 이름 확인
   - 예상한 이름 패턴과 일치하는지 확인

---

## 🚨 주의사항

1. **기존 리소스 이름 변경 시**
   - Terraform은 리소스를 삭제하고 재생성할 수 있음
   - 중요한 리소스는 이름 변경 전 백업 확인

2. **S3 버킷 이름**
   - S3 버킷 이름은 전역적으로 고유해야 함
   - 다른 계정에서 이미 사용 중인 이름은 사용 불가

3. **IAM Role 이름**
   - IAM Role 이름은 계정 내에서 고유해야 함
   - 기존 Role과 중복되지 않도록 주의

---

## 📚 예시 시나리오

### 시나리오 1: 프로젝트 이름 변경

**Before:**
```hcl
name_prefix = "infrakr-test"
```

**After:**
```hcl
name_prefix = "infrakr-prod"
```

**결과:** 모든 리소스 이름이 `infrakr-prod-*`로 변경됨

---

### 시나리오 2: 환경별 배포

```hcl
# environments/dev/terraform.tfvars
name_prefix = "infrakr-dev"

# environments/prod/terraform.tfvars
name_prefix = "infrakr-prod"
```

각 환경별로 독립적인 리소스 이름 생성

---

### 시나리오 3: 특정 리소스만 커스텀 이름

```hcl
# terraform.tfvars
name_prefix = "infrakr-test"

# S3만 다른 이름 사용
s3_bucket_name = "my-special-bucket"
```

나머지는 `infrakr-test-*`, S3만 `my-special-bucket`

---

## 💡 요약

- **한 곳에서 관리**: `variables.tf`의 `name_prefix` 하나만 수정
- **자동 생성**: 모든 리소스 이름이 자동으로 생성됨
- **일관성**: 모든 리소스가 동일한 패턴 사용
- **유연성**: 특정 리소스만 오버라이드 가능 (S3, CloudFront)

**이름 변경 = `terraform.tfvars`에서 `name_prefix` 하나만 수정!** ✨

