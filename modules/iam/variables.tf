# ============================================================================
# IAM 모듈 변수 정의
# ============================================================================

# 이름 접두사
# Role 이름 앞에 붙는 접두사 (예: "Infra-", "infrakr-test-")
variable "name_prefix" {
  description = "Prefix for the IAM role name"
  type        = string
}

# Role 이름
# Role의 논리적 이름 (접두사와 결합되어 최종 이름이 됨)
variable "role_name" {
  description = "Logical name of the IAM role"
  type        = string
}

# Assume Role Policy
# 이 Role을 누가 사용할 수 있는지 정의하는 JSON 정책
# 일반적으로 EC2 서비스가 사용할 수 있도록 설정
variable "assume_role_policy" {
  description = "Assume role policy (usually JSON)"
  type        = string
}

# 관리형 정책 ARN 목록
# AWS에서 제공하는 관리형 정책들을 Role에 연결
# 예: AmazonSSMManagedInstanceCore, AmazonS3ReadOnlyAccess 등
variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

# 리소스 태그
# 모든 IAM 리소스에 적용할 태그 맵
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

# S3 버킷 이름 (선택적)
# S3 접근 정책을 생성할 때 사용
# 빈 문자열이면 S3 정책을 생성하지 않음
variable "s3_bucket_name" {
  description = "S3 bucket name for access policy. If empty, S3 policy will not be created."
  type        = string
  default     = ""
}

# S3 Policy 생성 여부
# true이면 S3 Policy를 생성하고, false이면 생성하지 않음
# s3_policy_arn과 함께 사용할 때는 false로 설정
variable "create_s3_policy" {
  description = "Whether to create S3 access policy. Set to false when sharing existing policy."
  type        = bool
  default     = true
}

# S3 Policy ARN (선택적)
# 외부에서 생성된 S3 Policy ARN을 전달받아 Role에 연결
# create_s3_policy가 false일 때 사용
variable "s3_policy_arn" {
  description = "ARN of existing S3 policy to attach. Used when create_s3_policy is false."
  type        = string
  default     = ""
}

