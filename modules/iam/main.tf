# ============================================================================
# IAM Role 모듈
# ============================================================================
# IAM Role과 Instance Profile을 생성합니다.
# EC2 인스턴스가 AWS 서비스에 접근할 수 있도록 권한을 부여합니다.

# ============================================================================
# IAM Role 생성
# ============================================================================
resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}${var.role_name}"
  assume_role_policy = var.assume_role_policy

  tags = merge(var.tags, {
    Name = "${var.name_prefix}${var.role_name}"
  })
}

# ============================================================================
# IAM Role에 관리형 정책 연결
# ============================================================================
# AWS에서 제공하는 관리형 정책들을 Role에 연결
resource "aws_iam_role_policy_attachment" "this" {
  count      = length(var.managed_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = var.managed_policy_arns[count.index]
}

# ============================================================================
# IAM Instance Profile 생성
# ============================================================================
# EC2 인스턴스는 Role을 직접 사용할 수 없고, Instance Profile을 통해야 함
resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}${var.role_name}-profile"
  role = aws_iam_role.this.name

  tags = merge(var.tags, {
    Name = "${var.name_prefix}${var.role_name}-profile"
  })
}

# ============================================================================
# S3 접근 정책 생성 (선택적)
# ============================================================================
# EC2 인스턴스가 특정 S3 버킷에 접근할 수 있도록 하는 커스텀 정책
# create_s3_policy가 true이고 s3_bucket_name이 제공될 때만 생성
resource "aws_iam_policy" "s3_access" {
  count = var.s3_bucket_name != "" && var.create_s3_policy ? 1 : 0

  name        = "${var.name_prefix}s3-access"
  description = "S3 access policy for ${var.s3_bucket_name} bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListAllBuckets"
        Effect = "Allow"
        Action = "s3:ListAllMyBuckets"
        Resource = "*"
      },
      {
        Sid    = "FullAccessToSpecificBucket"
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}s3-access"
  })
}

# ============================================================================
# S3 접근 정책을 Role에 연결
# ============================================================================
# 생성된 S3 정책 또는 외부에서 전달받은 S3 정책을 IAM Role에 연결
# s3_bucket_name이 있으면 항상 attachment 생성
resource "aws_iam_role_policy_attachment" "s3_access" {
  count = var.s3_bucket_name != "" ? 1 : 0

  role = aws_iam_role.this.name
  # create_s3_policy가 true이면 생성한 Policy 사용, false이면 외부 Policy ARN 사용
  policy_arn = var.create_s3_policy ? (
    length(aws_iam_policy.s3_access) > 0 ? aws_iam_policy.s3_access[0].arn : ""
  ) : var.s3_policy_arn
}

