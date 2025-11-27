variable "distribution_name" {
  description = "Name of the CloudFront distribution"
  type        = string
}

variable "custom_domain" {
  description = "Custom domain for CloudFront"
  type        = string
}

variable "s3_bucket_id" {
  description = "ID of the S3 bucket"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  type        = string
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
