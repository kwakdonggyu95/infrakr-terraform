# ============================================================================
# IAM 모듈 출력값 정의
# ============================================================================

# Role ARN
# 생성된 IAM Role의 ARN (Amazon Resource Name)
output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

# Role 이름
# 생성된 IAM Role의 이름
output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}

# Instance Profile 이름
# EC2 인스턴스에 연결할 때 사용하는 Instance Profile 이름
output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.this.name
}

# ARN (별칭)
# role_arn과 동일한 값 (호환성을 위해 제공)
output "arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

# S3 Policy ARN
# 생성된 S3 접근 정책의 ARN (다른 Role과 공유할 때 사용)
output "s3_policy_arn" {
  description = "ARN of the S3 access policy (if created)"
  value       = var.s3_bucket_name != "" && var.create_s3_policy ? aws_iam_policy.s3_access[0].arn : null
}

