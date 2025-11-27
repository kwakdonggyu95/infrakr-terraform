# ============================================================================
# 출력값 정의 (Outputs)
# ============================================================================
# Terraform 실행 후 생성된 리소스의 중요한 정보를 출력합니다.
# terraform output 명령어로 확인하거나 다른 모듈에서 참조할 수 있습니다.

# VPC ID
# 생성된 VPC의 고유 식별자
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

# VPC CIDR 블록
# VPC의 IP 주소 범위
output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

# 퍼블릭 서브넷 ID 목록
# 인터넷 게이트웨이와 연결된 퍼블릭 서브넷들의 ID
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

# 프라이빗 서브넷 ID 목록
# NAT 게이트웨이를 통해 외부 통신하는 프라이빗 서브넷들의 ID
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# 인터넷 게이트웨이 ID
# VPC와 인터넷을 연결하는 게이트웨이의 ID
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

# NAT 게이트웨이 ID 목록
# 프라이빗 서브넷의 아웃바운드 인터넷 트래픽을 처리하는 NAT 게이트웨이들의 ID
output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

# AP 로드 밸런서 DNS 이름
# AP 서버용 Application Load Balancer의 DNS 주소
output "ap_load_balancer_dns_name" {
  description = "DNS name of the AP load balancer"
  value       = module.load_balancer_ap.dns_name
}

# Alpha 로드 밸런서 DNS 이름
# Alpha 서버용 Application Load Balancer의 DNS 주소
output "alpha_load_balancer_dns_name" {
  description = "DNS name of the Alpha load balancer"
  value       = module.load_balancer_alpha.dns_name
}

# AP 인스턴스 ID 목록
# 생성된 AP 서버 EC2 인스턴스들의 ID
output "ap_instance_ids" {
  description = "IDs of AP instances"
  value       = module.ec2.ap_instance_ids
}

# Alpha 인스턴스 ID 목록
# 생성된 Alpha 서버 EC2 인스턴스들의 ID
output "alpha_instance_ids" {
  description = "IDs of Alpha instances"
  value       = module.ec2.alpha_instance_ids
}

# 모든 인스턴스 ID 목록
# 생성된 모든 EC2 인스턴스들의 ID
output "all_instance_ids" {
  description = "IDs of all instances"
  value       = module.ec2.all_instance_ids
}
# ============================================================================
# S3 + CloudFront Outputs
# ============================================================================

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3.bucket_arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cloudfront.distribution_domain_name
}

output "cloudfront_custom_domain" {
  description = "Custom domain for CloudFront"
  value       = var.cloudfront_custom_domain
}

output "dns_setup_instruction" {
  description = "DNS setup instruction for Route53"
  value = "Add CNAME record: ${var.cloudfront_custom_domain} -> ${module.cloudfront.distribution_domain_name}"
}
