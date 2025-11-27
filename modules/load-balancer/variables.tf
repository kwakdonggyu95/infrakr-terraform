# ============================================================================
# Load Balancer 모듈 변수 정의
# ============================================================================

# ALB 이름
# Application Load Balancer의 이름
variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

# Target Group 이름
# 타겟 그룹의 이름
variable "target_group_name" {
  description = "Name of the target group"
  type        = string
}

# VPC ID
# 로드 밸런서와 타겟 그룹이 속할 VPC의 ID
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

# 퍼블릭 서브넷 ID 목록
# 로드 밸런서를 배치할 퍼블릭 서브넷들의 ID
# 여러 AZ에 배치하여 고가용성 확보
variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

# 보안 그룹 ID
# 로드 밸런서에 적용할 보안 그룹 ID
# HTTP/HTTPS 트래픽을 허용하는 보안 그룹이어야 함
variable "security_group_id" {
  description = "Security group ID for the load balancer"
  type        = string
}

# 타겟 인스턴스 ID 목록
# 로드 밸런서가 트래픽을 분산할 백엔드 서버(EC2 인스턴스)들의 ID
variable "target_instances" {
  description = "List of target instance IDs"
  type        = list(string)
}

# ACM 인증서 ARN 목록
# HTTPS 리스너에서 사용할 SSL/TLS 인증서 ARN 목록
# 여러 도메인 인증서를 지원 (예: *.cocone.co.kr, *.cocone-m.com)
variable "certificate_arns" {
  description = "List of ACM certificate ARNs for HTTPS listener"
  type        = list(string)
  default     = []
}

# 리소스 태그
# 모든 로드 밸런서 리소스에 적용할 태그 맵
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
