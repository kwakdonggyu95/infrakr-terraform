# ============================================================================
# Security Groups 모듈 변수 정의
# ============================================================================

# VPC ID
# 보안 그룹을 생성할 VPC의 ID
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

# 리소스 태그
# 모든 보안 그룹에 적용할 태그 맵
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
