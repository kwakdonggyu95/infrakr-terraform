variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

# 파일 업로드는 EC2 인스턴스에서 AWS CLI를 사용하여 수행합니다.
# S3 버킷에 대한 접근 권한은 EC2 인스턴스의 IAM Role을 통해 부여됩니다.
