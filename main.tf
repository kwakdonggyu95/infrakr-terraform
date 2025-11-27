# ============================================================================
# Terraform 설정
# ============================================================================
# Terraform 버전 및 필요한 Provider 정의
terraform {
  required_version = ">= 1.0"  # 최소 Terraform 버전 요구사항
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # AWS Provider 소스
      version = "~> 5.0"         # AWS Provider 버전 (5.0 이상, 6.0 미만)
    }
  }
}

# ============================================================================
# AWS Provider 설정
# ============================================================================
# AWS 인증 및 리전 설정
provider "aws" {
  region  = var.aws_region   # 작업할 AWS 리전 (예: us-west-2)
  profile = var.aws_profile  # 사용할 AWS 프로필 이름 (예: kr-Infra)
}

# ============================================================================
# VPC Module (가상 네트워크 모듈)
# ============================================================================
# InfraKR 계정에서 VPC, 서브넷, 라우팅 테이블 등을 직접 생성합니다.
module "vpc" {
  source = "./modules/vpc"  # VPC 모듈 경로
  
  # VPC 및 서브넷 생성 설정
  vpc_cidr             = var.vpc_cidr              # VPC의 IP 주소 범위 (예: 10.160.0.0/16)
  availability_zones   = var.availability_zones     # 사용할 가용 영역 목록 (예: ["us-west-2a", "us-west-2c"])
  public_subnet_cidrs  = var.public_subnet_cidrs    # 퍼블릭 서브넷 IP 범위 목록
  private_subnet_cidrs = var.private_subnet_cidrs   # 프라이빗 서브넷 IP 범위 목록
  name_prefix          = var.name_prefix            # 리소스 이름 prefix (루트에서 전달)
  # vpn_gateway_id       = var.vpn_gateway_id        # VPN Gateway ID (Site-to-Site VPN용, 선택사항) - 주석 처리됨
  
  tags = var.common_tags  # 공통 태그 적용
}

# ============================================================================
# Security Groups Module (보안 그룹 모듈)
# ============================================================================
# 네트워크 트래픽을 제어하는 보안 그룹 생성
# - LinuxDefault: 기본 Linux 보안 그룹
# - WebAll: 웹 서버용 보안 그룹 (HTTP/HTTPS)
module "security_groups" {
  source = "./modules/security-groups"  # 보안 그룹 모듈 경로
  
  vpc_id = module.vpc.vpc_id  # VPC 모듈에서 생성된 VPC ID 전달
  tags   = var.common_tags     # 공통 태그 적용
}

# ============================================================================
# IAM Policy Documents (IAM 정책 문서)
# ============================================================================
# EC2 서비스가 IAM Role을 사용할 수 있도록 허용하는 Trust Policy
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ============================================================================
# IAM Role Module - Production (AP 서버용) - 주요 Role
# ============================================================================
# AP 서버용 IAM Role 생성 (주요 Role)
# - SSM Session Manager를 통한 원격 접속 권한 포함
# - S3 버킷 접근 권한 포함 (S3 Policy를 생성하여 Alpha와 공유)
module "iam_role_production" {
  source               = "./modules/iam"
  name_prefix          = "${var.name_prefix}-"  # 리소스 이름 prefix (루트에서 전달)
  role_name            = "production-ec2-role"
  assume_role_policy   = data.aws_iam_policy_document.ec2_assume_role.json
  managed_policy_arns  = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",  # SSM Session Manager 접속 권한
  ]
  # S3 버킷 접근 권한 (AP가 주요이므로 여기서 Policy 생성)
  s3_bucket_name       = var.s3_bucket_name != "" ? var.s3_bucket_name : "${var.name_prefix}-s3"
  
  tags = var.common_tags
}

# ============================================================================
# IAM Role Module - Alpha (Alpha 서버용) - 보조 Role
# ============================================================================
# Alpha 서버용 IAM Role 생성 (보조 Role)
# - SSM Session Manager를 통한 원격 접속 권한 포함
# - S3 버킷 접근 권한 포함 (AP 모듈에서 생성한 Policy를 공유)
module "iam_role_alpha" {
  source               = "./modules/iam"
  name_prefix          = "${var.name_prefix}-"  # 리소스 이름 prefix (루트에서 전달)
  role_name            = "alpha-ec2-role"
  assume_role_policy   = data.aws_iam_policy_document.ec2_assume_role.json
  managed_policy_arns  = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",  # SSM Session Manager 접속 권한
  ]
  # S3 버킷 접근 권한 (AP 모듈에서 생성한 Policy ARN을 전달하여 공유)
  s3_bucket_name       = var.s3_bucket_name != "" ? var.s3_bucket_name : "${var.name_prefix}-s3"
  create_s3_policy     = false  # AP 모듈에서 Policy를 생성하므로 여기서는 생성하지 않음
  s3_policy_arn        = module.iam_role_production.s3_policy_arn  # AP 모듈의 Policy를 공유
  
  tags = var.common_tags
}

# ============================================================================
# EC2 Module (compute 인스턴스 모듈)
# ============================================================================
# EC2 인스턴스 생성 (AP 서버, Alpha 서버)
module "ec2" {
  source = "./modules/ec2"  # EC2 모듈 경로
  
  # 네트워크 설정
  vpc_id             = module.vpc.vpc_id                    # VPC ID
  public_subnet_ids  = module.vpc.public_subnet_ids         # 퍼블릭 서브넷 ID 목록
  private_subnet_ids = module.vpc.private_subnet_ids         # 프라이빗 서브넷 ID 목록
  security_group_ids = module.security_groups.security_group_ids  # 보안 그룹 ID 맵
  
  # 인스턴스 설정
  key_name                    = var.key_name  # EC2 인스턴스 접속용 SSH 키 페어 이름
  iam_instance_profile_ap     = module.iam_role_production.instance_profile_name  # AP 서버용 IAM Instance Profile
  iam_instance_profile_alpha  = module.iam_role_alpha.instance_profile_name      # Alpha 서버용 IAM Instance Profile
  name_prefix                 = var.name_prefix  # 리소스 이름 prefix (루트에서 전달)
  
  tags = var.common_tags  # 공통 태그 적용
}

# ============================================================================
# Load Balancer Module - AP (AP 서버용)
# ============================================================================
# AP 서버용 Application Load Balancer 생성
module "load_balancer_ap" {
  source = "./modules/load-balancer"  # 로드 밸런서 모듈 경로
  
  # 로드 밸런서 설정
  alb_name          = "${var.name_prefix}-ap-alb"  # ALB 이름 (name_prefix 기반 자동 생성)
  target_group_name = "${var.name_prefix}-ap-tg"   # Target Group 이름 (name_prefix 기반 자동 생성)
  
  # 네트워크 설정
  vpc_id            = module.vpc.vpc_id                                    # VPC ID
  public_subnet_ids = module.vpc.public_subnet_ids                         # 퍼블릭 서브넷 ID 목록 (ALB는 퍼블릭 서브넷에 배치)
  security_group_id = module.security_groups.security_group_ids["web_all"] # 웹 트래픽용 보안 그룹 ID
  
  # 타겟 설정
  target_instances = module.ec2.ap_instance_ids  # AP 서버 인스턴스 ID 목록
  
  # 인증서 설정
  certificate_arns = var.certificate_arns  # 인증서 ARN 목록 (*.cocone.co.kr, *.cocone-m.com)
  
  tags = var.common_tags  # 공통 태그 적용
}

# ============================================================================
# Load Balancer Module - Alpha (Alpha 서버용)
# ============================================================================
# Alpha 서버용 Application Load Balancer 생성
module "load_balancer_alpha" {
  source = "./modules/load-balancer"  # 로드 밸런서 모듈 경로
  
  # 로드 밸런서 설정
  alb_name          = "${var.name_prefix}-alpha-alb"  # ALB 이름 (name_prefix 기반 자동 생성)
  target_group_name = "${var.name_prefix}-alpha-tg"  # Target Group 이름 (name_prefix 기반 자동 생성)
  
  # 네트워크 설정
  vpc_id            = module.vpc.vpc_id                                    # VPC ID
  public_subnet_ids = module.vpc.public_subnet_ids                         # 퍼블릭 서브넷 ID 목록 (ALB는 퍼블릭 서브넷에 배치)
  security_group_id = module.security_groups.security_group_ids["web_all"] # 웹 트래픽용 보안 그룹 ID
  
  # 타겟 설정
  target_instances = module.ec2.alpha_instance_ids  # Alpha 서버 인스턴스 ID 목록
  
  # 인증서 설정
  certificate_arns = var.certificate_arns  # 인증서 ARN 목록 (*.cocone.co.kr, *.cocone-m.com)
  
  tags = var.common_tags  # 공통 태그 적용
}

# ============================================================================
# S3 Module (정적 파일 저장소)
# ============================================================================
# 정적 웹 콘텐츠를 저장할 S3 버킷 생성
# CloudFront와 연동하여 전 세계에 콘텐츠를 배포합니다.
#
# 주의: 순환 참조 문제
# - S3 모듈이 CloudFront Distribution ARN을 필요로 함 (버킷 정책용)
# - CloudFront 모듈이 S3 버킷 정보를 필요로 함 (Origin 설정용)
# - Terraform이 자동으로 의존성을 해결:
#   1. S3 버킷 생성 (버킷 자체는 CloudFront ARN 없이도 생성 가능)
#   2. CloudFront Distribution 생성 (S3 정보 사용)
#   3. S3 버킷 정책 업데이트 (CloudFront ARN 사용)
module "s3" {
  source = "./modules/s3"  # S3 모듈 경로
  
  # S3 버킷 이름: 명시적으로 지정된 경우 사용, 없으면 name_prefix 기반 자동 생성
  bucket_name                 = var.s3_bucket_name != "" ? var.s3_bucket_name : "${var.name_prefix}-s3"
  cloudfront_distribution_arn = module.cloudfront.distribution_arn # CloudFront ARN (버킷 정책용)
  
  tags = var.common_tags  # 공통 태그 적용
}

# ============================================================================
# CloudFront Module (CDN 배포)
# ============================================================================
# 전 세계 사용자에게 빠른 콘텐츠 제공을 위한 CloudFront 배포 생성
# S3 버킷의 정적 콘텐츠를 전 세계 엣지 로케이션에 캐시하여 제공합니다.
#
# 참고: S3 모듈과의 의존성
# - CloudFront는 S3 버킷 정보를 Origin으로 사용
# - CloudFront 생성 후 S3 버킷 정책이 업데이트됨
module "cloudfront" {
  source = "./modules/cloudfront"  # CloudFront 모듈 경로
  
  # 배포 설정: 명시적으로 지정된 경우 사용, 없으면 name_prefix 기반 자동 생성
  distribution_name = var.cloudfront_distribution_name != "" ? var.cloudfront_distribution_name : "${var.name_prefix}-cdn"
  custom_domain     = var.cloudfront_custom_domain != "" ? var.cloudfront_custom_domain : "${var.name_prefix}.cocone.co.kr"
  
  # Origin 설정 (S3 버킷)
  # CloudFront가 콘텐츠를 가져올 원본 서버 정보
  s3_bucket_id                    = module.s3.bucket_id                        # S3 버킷 ID
  s3_bucket_regional_domain_name  = module.s3.bucket_regional_domain_name      # S3 버킷 리전 도메인
  
  # SSL 인증서
  # 중요: CloudFront는 us-east-1 리전의 ACM 인증서만 사용 가능
  ssl_certificate_arn = var.ssl_certificate_arn  # *.cocone.co.kr 인증서 ARN (us-east-1)
  
  tags = var.common_tags  # 공통 태그 적용
}
