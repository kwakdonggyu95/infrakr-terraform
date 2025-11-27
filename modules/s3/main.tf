# ============================================================================
# S3 모듈 - 정적 웹 콘텐츠 저장소
# ============================================================================
# CloudFront와 함께 사용할 S3 버킷을 생성합니다.
# 정적 웹사이트 파일(HTML, CSS, 이미지 등)을 저장하고 CloudFront를 통해 전 세계에 배포합니다.

# ============================================================================
# S3 Bucket (S3 버킷)
# ============================================================================
# 정적 웹 콘텐츠를 저장할 S3 버킷 생성
# CloudFront Origin Access Control (OAC)을 통해 접근 제어
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name  # 버킷 이름 (전역적으로 고유해야 함)

  tags = merge(var.tags, {
    Name = var.bucket_name
  })
}

# ============================================================================
# S3 Bucket Versioning (버전 관리)
# ============================================================================
# S3 버킷의 객체 버전 관리 설정
# 비활성화: 동일한 키로 파일을 업로드하면 기존 파일이 덮어씌워짐
# 활성화 시: 이전 버전이 보관되어 복구 가능
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Disabled"  # 버전 관리 비활성화 (비용 절감)
  }
}

# ============================================================================
# S3 Bucket Public Access Block (퍼블릭 접근 차단)
# ============================================================================
# S3 버킷의 모든 퍼블릭 접근을 차단
# 보안 강화: CloudFront OAC를 통해서만 접근 가능하도록 설정
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true  # 퍼블릭 ACL 차단
  block_public_policy     = true  # 퍼블릭 정책 차단
  ignore_public_acls      = true  # 퍼블릭 ACL 무시
  restrict_public_buckets = true  # 퍼블릭 버킷 접근 제한
}

# ============================================================================
# S3 Bucket Policy for CloudFront OAC (CloudFront 접근 정책)
# ============================================================================
# CloudFront Origin Access Control (OAC)을 통한 접근만 허용
# S3 버킷에 직접 접근은 차단하고, CloudFront를 통해서만 접근 가능
# 
# 주의: 순환 참조 문제
# - 이 정책은 CloudFront Distribution ARN을 필요로 함
# - CloudFront는 S3 버킷 정보를 필요로 함
# - Terraform이 자동으로 의존성을 해결하지만, CloudFront가 먼저 생성되어야 함
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"  # CloudFront 서비스만 허용
        }
        Action   = "s3:GetObject"  # 객체 읽기 권한만 부여
        Resource = "${aws_s3_bucket.main.arn}/*"  # 버킷 내 모든 객체
        Condition = {
          StringEquals = {
            # 특정 CloudFront Distribution만 접근 허용 (보안 강화)
            "AWS:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      }
    ]
  })

  # Public Access Block이 먼저 생성되어야 정책 적용 가능
  depends_on = [aws_s3_bucket_public_access_block.main]
}

# ============================================================================
# 파일 업로드 안내
# ============================================================================
# S3 버킷에 파일(이미지 등)을 업로드하려면 EC2 인스턴스에서 AWS CLI를 사용하세요.
# 
# EC2 인스턴스에서 S3로 이미지 업로드 방법:
# 1. EC2 인스턴스에 SSM Session Manager로 접속
# 2. 이미지 파일을 EC2에 업로드 (scp 또는 직접 다운로드)
# 3. AWS CLI로 S3에 업로드:
#    aws s3 cp /path/to/image.jpg s3://${aws_s3_bucket.main.id}/images/image.jpg
#    aws s3 cp /path/to/image.jpg s3://${aws_s3_bucket.main.id}/images/image.jpg --content-type image/jpeg
# 
# CloudFront를 통해 접근:
# https://infrakr-test.cocone.co.kr/images/image.jpg
# 
# 참고: EC2 인스턴스는 IAM Role을 통해 S3 접근 권한을 가지고 있습니다.
