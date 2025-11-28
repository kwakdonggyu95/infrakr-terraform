# ============================================================================
# 변수 정의 (Variables)
# ============================================================================
# Terraform에서 사용할 변수들을 정의합니다.
# 각 변수는 기본값을 가지며, terraform.tfvars 파일에서 덮어쓸 수 있습니다.

# AWS 리전 설정
# 인프라를 생성할 AWS 리전 (예: us-west-2는 오레곤 리전)
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

# AWS 프로필 이름
# AWS CLI 설정 파일(~/.aws/credentials)에 정의된 프로필 이름
variable "aws_profile" {
  description = "AWS profile name"
  type        = string
  default     = "kr-Infra"
}

# VPC CIDR 블록
# VPC의 IP 주소 범위를 정의 (10.160.0.0/16 = 10.160.0.0 ~ 10.160.255.255)
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.160.0.0/16"
}

# 가용 영역 목록
# 서브넷을 배치할 AWS 가용 영역 목록
# 서브넷 개수와 동일한 개수로 지정해야 함 (예: 2개 서브넷 = 2개 AZ)
variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2c"]  # 기본값: us-west-2a, us-west-2c
}

# 퍼블릭 서브넷 CIDR 블록 목록
# 인터넷 게이트웨이를 통해 외부와 통신 가능한 서브넷들의 IP 범위
# 각 서브넷은 다른 가용 영역에 배치됨
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.160.1.0/24", "10.160.2.0/24"]  # 각 서브넷은 /24 (256개 IP)
}

# 프라이빗 서브넷 CIDR 블록 목록
# NAT 게이트웨이를 통해서만 외부와 통신 가능한 서브넷들의 IP 범위
# 애플리케이션 서버나 데이터베이스 서버를 배치하는 용도
variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.160.10.0/24", "10.160.20.0/24"]  # 각 서브넷은 /24 (256개 IP)
}

# EC2 키 페어 이름
# EC2 인스턴스에 SSH 접속할 때 사용할 키 페어 이름
# AWS 콘솔에서 미리 생성된 키 페어 이름을 지정
variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "infra-nopass"
}

# ACM 인증서 ARN 목록
# ALB의 HTTPS 리스너에서 사용할 SSL/TLS 인증서 ARN 목록
# 여러 도메인 인증서를 지원 (예: *.cocone.co.kr, *.cocone-m.com)
variable "certificate_arns" {
  description = "List of ACM certificate ARNs for HTTPS listener"
  type        = list(string)
  default     = []
}

# 리소스 이름 prefix (통합 관리)
# 모든 리소스 이름을 생성할 때 사용할 prefix
# 예: "infrakr-test" → "infrakr-test-vpc", "infrakr-test-ap-alb", "infrakr-test-ap-0" 등
variable "name_prefix" {
  description = "Prefix for all resource names (VPC, EC2, ALB, S3, etc.)"
  type        = string
  default     = "infrakr-test"
}

# 공통 태그
# 모든 리소스에 자동으로 적용되는 태그
# 리소스 관리, 비용 추적, 환경 구분 등에 활용
variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Environment = "test"        # 환경 구분 (test, staging, production 등)
    Project     = "infrakr-test" # 프로젝트 이름
    ManagedBy   = "terraform"   # 관리 도구 표시
  }
}

# ============================================================================
# VPN Variables (Site-to-Site VPN 연결)
# ============================================================================

# Customer Gateway IP 주소
# 온프레미스 네트워크(Fortigate)의 공인 IP 주소
variable "customer_gateway_ip_address" {
  description = "Public IP address of the Customer Gateway (Fortigate)"
  type        = string
  default     = ""
}

# Customer Gateway BGP ASN
# Customer Gateway의 BGP 자율 시스템 번호 (정적 라우팅 사용 시 선택사항)
variable "customer_gateway_bgp_asn" {
  description = "BGP ASN for the Customer Gateway"
  type        = number
  default     = 65000
}

# Customer Gateway 이름
variable "customer_gateway_name" {
  description = "Name of the Customer Gateway"
  type        = string
  default     = ""
}

# VPN Gateway 이름
variable "vpn_gateway_name" {
  description = "Name of the VPN Gateway"
  type        = string
  default     = ""
}

# VPN Connection 이름
variable "vpn_connection_name" {
  description = "Name of the VPN Connection"
  type        = string
  default     = ""
}

# VPN 정적 라우팅 사용 여부
variable "vpn_static_routes_only" {
  description = "Whether to use static routes only for VPN (true) or dynamic routing (false)"
  type        = bool
  default     = true
}

# VPN 원격 네트워크 CIDR
# 사무실 네트워크의 CIDR 블록 (예: 10.15.0.0/16)
variable "vpn_remote_network_cidr" {
  description = "Remote network CIDR block for VPN static routing (e.g., 10.15.0.0/16)"
  type        = string
  default     = ""
}

# ============================================================================
# VPC Peering Variables (크로스 리전/크로스 계정 VPC Peering) - 제거됨
# ============================================================================
# 초기 구성에서는 VPC Peering을 제외합니다.
# 필요시 나중에 주석을 해제하여 사용할 수 있습니다.

# # Peer VPC ID
# # 베이스 계정의 VPC ID
# variable "peer_vpc_id" {
#   description = "ID of the peer VPC (base account)"
#   type        = string
#   default     = ""
# }

# # Peer Region
# # 베이스 계정 VPC의 리전
# variable "peer_region" {
#   description = "Region of the peer VPC"
#   type        = string
#   default     = "ap-northeast-2"  # 서울 리전
# }

# # Peer Owner ID
# # 베이스 계정의 AWS Account ID (크로스 계정 Peering인 경우)
# variable "peer_owner_id" {
#   description = "AWS Account ID of the peer VPC owner (for cross-account peering)"
#   type        = string
#   default     = ""
# }

# # Peer VPC CIDR
# # 베이스 계정 VPC의 CIDR 블록 (라우팅용)
# variable "peer_vpc_cidr" {
#   description = "CIDR block of the peer VPC (for routing)"
#   type        = string
#   default     = "10.71.0.0/16"
# }

# # Peering 자동 수락 여부
# # 같은 계정 내 Peering인 경우 true, 크로스 계정인 경우 false (수동 수락 필요)
# variable "peering_auto_accept" {
#   description = "Whether to automatically accept the peering connection (same account only)"
#   type        = bool
#   default     = false
# }

# # Peering Connection 이름
# variable "peering_connection_name" {
#   description = "Name of the VPC Peering Connection"
#   type        = string
#   default     = ""
# }

# ============================================================================
# S3 + CloudFront Variables
# ============================================================================

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for static content (default: name_prefix-s3)"
  type        = string
  default     = ""  # 빈 문자열이면 name_prefix 기반으로 자동 생성
}

variable "cloudfront_distribution_name" {
  description = "Name of the CloudFront distribution (default: name_prefix-cdn)"
  type        = string
  default     = ""  # 빈 문자열이면 name_prefix 기반으로 자동 생성
}

variable "cloudfront_custom_domain" {
  description = "Custom domain for CloudFront (default: name_prefix.cocone.co.kr)"
  type        = string
  default     = ""  # 빈 문자열이면 name_prefix 기반으로 자동 생성
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate for CloudFront (us-east-1)"
  type        = string
  default     = "arn:aws:acm:us-east-1:611680202326:certificate/ca3f42ae-0b13-4151-aeb5-3b5d7d70b199"  # *.cocone.co.kr
}
