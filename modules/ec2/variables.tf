# ============================================================================
# EC2 모듈 변수 정의
# ============================================================================

# VPC ID
# 인스턴스를 생성할 VPC의 ID
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

# 퍼블릭 서브넷 ID 목록
# 퍼블릭 서브넷 ID 목록 (현재 사용되지 않지만 향후 확장을 위해 유지)
variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

# 프라이빗 서브넷 ID 목록
# EC2 인스턴스를 배치할 프라이빗 서브넷들의 ID
variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

# 보안 그룹 ID 맵
# 보안 그룹 이름을 키로 하는 맵
# 인스턴스에 적용할 보안 그룹을 선택할 때 사용
variable "security_group_ids" {
  description = "Map of security group IDs"
  type        = map(string)
}

# 키 페어 이름
# EC2 인스턴스 SSH 접속에 사용할 AWS 키 페어 이름
# AWS 콘솔에서 미리 생성된 키 페어를 지정
variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
}

# IAM Instance Profile 이름 - AP 서버용
# AP 서버에 연결할 IAM Instance Profile 이름
# IAM Role을 통해 AWS 서비스 접근 권한 부여 (예: SSM Session Manager)
variable "iam_instance_profile_ap" {
  description = "Name of the IAM instance profile to attach to AP EC2 instances"
  type        = string
  default     = ""
}

# IAM Instance Profile 이름 - Alpha 서버용
# Alpha 서버에 연결할 IAM Instance Profile 이름
# IAM Role을 통해 AWS 서비스 접근 권한 부여 (예: SSM Session Manager)
variable "iam_instance_profile_alpha" {
  description = "Name of the IAM instance profile to attach to Alpha EC2 instances"
  type        = string
  default     = ""
}

# 리소스 태그
# 모든 EC2 인스턴스에 적용할 태그 맵
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

# 리소스 이름 prefix
# EC2 인스턴스 이름을 생성할 때 사용할 prefix (루트에서 전달받음)
variable "name_prefix" {
  description = "Prefix for EC2 instance names"
  type        = string
  default     = "infrakr-test"
}
