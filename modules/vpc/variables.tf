# ============================================================================
# VPC 모듈 변수 정의
# ============================================================================

# VPC CIDR 블록
# VPC의 IP 주소 범위 (예: 10.160.0.0/16)
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

# 가용 영역 목록
# 서브넷을 배치할 AWS 가용 영역 목록 (예: ["us-west-2a", "us-west-2b"])
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# 퍼블릭 서브넷 CIDR 블록 목록
# 인터넷 게이트웨이와 연결된 퍼블릭 서브넷들의 IP 범위
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

# 프라이빗 서브넷 CIDR 블록 목록
# NAT 게이트웨이를 통해 외부 통신하는 프라이빗 서브넷들의 IP 범위
variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

# 리소스 이름 prefix
# 모든 VPC 리소스 이름을 생성할 때 사용할 prefix (루트에서 전달받음)
variable "name_prefix" {
  description = "Prefix for VPC resource names"
  type        = string
  default     = "infrakr-test"
}

# 리소스 태그
# 모든 리소스에 적용할 태그 맵 (환경, 프로젝트명 등)
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

# VPN Gateway ID (선택사항) - 주석 처리됨
# Site-to-Site VPN 연결 시 사용할 VPN Gateway ID
# 이 값이 설정되면 모든 Route Table에 10.15.0.0/16 -> VPN Gateway 라우트가 추가됩니다
# variable "vpn_gateway_id" {
#   description = "VPN Gateway ID for Site-to-Site VPN connection (optional)"
#   type        = string
#   default     = ""
# }
