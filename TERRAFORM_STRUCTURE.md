# Terraform 구조 설명: 루트 vs 모듈

## 📁 파일 구조

```
infrakr/
├── main.tf                    # 루트 모듈의 main.tf
├── variables.tf               # 루트 모듈의 variables.tf
├── outputs.tf                 # 루트 모듈의 outputs.tf
├── terraform.tfvars           # 루트 모듈의 변수 값
└── modules/
    ├── vpc/
    │   ├── main.tf            # VPC 모듈의 main.tf
    │   ├── variables.tf       # VPC 모듈의 variables.tf
    │   └── outputs.tf         # VPC 모듈의 outputs.tf
    ├── ec2/
    │   ├── main.tf            # EC2 모듈의 main.tf
    │   └── variables.tf       # EC2 모듈의 variables.tf
    └── ...
```

---

## 🔑 핵심 차이점

### 1. **루트 모듈 (Root Module)**

**위치**: `/infrakr/main.tf`, `/infrakr/variables.tf`

**역할**:
- **전체 인프라의 조합 및 오케스트레이션**
- 여러 모듈을 호출하고 연결
- Provider 설정 (AWS, 리전, 프로필)
- Terraform 버전 및 Provider 버전 정의
- Data source 정의 (모듈 간 공유되는 데이터)

**특징**:
- `module` 블록을 사용하여 하위 모듈 호출
- 모듈 간 의존성 관리
- 최상위 레벨의 설정

**예시 (루트 main.tf)**:
```hcl
# Provider 설정
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# VPC 모듈 호출
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = var.common_tags
}

# EC2 모듈 호출 (VPC 모듈의 출력값 사용)
module "ec2" {
  source = "./modules/ec2"
  
  vpc_id             = module.vpc.vpc_id  # VPC 모듈의 출력값 참조
  private_subnet_ids = module.vpc.private_subnet_ids
  # ...
}
```

**예시 (루트 variables.tf)**:
```hcl
# 전체 프로젝트 레벨의 변수
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.160.0.0/16"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project = "infrakr-test"
  }
}
```

---

### 2. **모듈 (Module)**

**위치**: `/infrakr/modules/vpc/main.tf`, `/infrakr/modules/vpc/variables.tf`

**역할**:
- **특정 리소스 그룹의 생성 및 관리**
- 재사용 가능한 코드 블록
- 캡슐화된 로직 (내부 구현은 숨김)
- 입력값을 받아서 리소스 생성

**특징**:
- `resource` 블록으로 실제 AWS 리소스 생성
- `variable`로 입력값 정의
- `output`으로 생성된 리소스 정보 반환
- 독립적으로 테스트 가능

**예시 (모듈 main.tf)**:
```hcl
# 실제 AWS 리소스 생성
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr  # 모듈의 변수 사용
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "infrakr-test-vpc"
  })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  # ...
}
```

**예시 (모듈 variables.tf)**:
```hcl
# 모듈이 받아야 하는 입력값 정의
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  # default가 없음 = 필수 입력값
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}  # 선택적 입력값
}
```

---

## 🔄 데이터 흐름

```
terraform.tfvars (루트)
    ↓
루트 variables.tf (변수 정의)
    ↓
루트 main.tf (모듈 호출 시 변수 전달)
    ↓
모듈 variables.tf (모듈이 받을 변수 정의)
    ↓
모듈 main.tf (변수를 사용하여 리소스 생성)
    ↓
모듈 outputs.tf (생성된 리소스 정보 반환)
    ↓
루트 outputs.tf (최종 출력값)
```

**실제 예시**:

1. **terraform.tfvars** (사용자가 값 입력):
   ```hcl
   vpc_cidr = "10.160.0.0/16"
   ```

2. **루트 variables.tf** (변수 정의):
   ```hcl
   variable "vpc_cidr" {
     type = string
   }
   ```

3. **루트 main.tf** (모듈에 전달):
   ```hcl
   module "vpc" {
     source = "./modules/vpc"
     vpc_cidr = var.vpc_cidr  # 루트 변수를 모듈에 전달
   }
   ```

4. **모듈 variables.tf** (모듈이 받을 변수):
   ```hcl
   variable "vpc_cidr" {
     type = string
   }
   ```

5. **모듈 main.tf** (변수 사용):
   ```hcl
   resource "aws_vpc" "main" {
     cidr_block = var.vpc_cidr  # 모듈 변수 사용
   }
   ```

---

## 📊 비교표

| 항목 | 루트 모듈 | 모듈 |
|------|----------|------|
| **위치** | `/infrakr/` | `/infrakr/modules/*/` |
| **주요 내용** | `module` 블록, Provider 설정 | `resource` 블록 |
| **변수 역할** | 전체 프로젝트 설정 | 모듈별 입력값 |
| **재사용성** | 프로젝트별 1개 | 여러 프로젝트에서 재사용 가능 |
| **의존성** | 모듈 간 의존성 관리 | 모듈 내부 리소스 간 의존성 |
| **출력값** | 최종 결과값 | 모듈 생성 리소스 정보 |

---

## 💡 왜 이렇게 나눴을까?

### 장점:

1. **재사용성**: VPC 모듈을 다른 프로젝트에서도 사용 가능
2. **관심사 분리**: VPC는 VPC 모듈에서, EC2는 EC2 모듈에서 관리
3. **유지보수성**: 모듈만 수정하면 모든 사용처에 반영
4. **테스트 용이성**: 모듈을 독립적으로 테스트 가능
5. **가독성**: 루트 main.tf가 간결해짐

### 예시:

**루트 main.tf (간결함)**:
```hcl
module "vpc" { ... }
module "ec2" { ... }
module "alb" { ... }
```

**모듈 main.tf (상세함)**:
```hcl
resource "aws_vpc" "main" { ... }
resource "aws_subnet" "public" { ... }
resource "aws_subnet" "private" { ... }
# ... 수십 개의 리소스
```

---

## 🎯 요약

- **루트 모듈**: "무엇을 만들지" 정의 (조합 및 오케스트레이션)
- **모듈**: "어떻게 만들지" 정의 (실제 리소스 생성)

루트는 레고 블록을 조립하는 설계도이고, 모듈은 각 레고 블록의 제작 방법입니다!

