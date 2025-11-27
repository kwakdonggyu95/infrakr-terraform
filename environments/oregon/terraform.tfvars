aws_region  = "us-west-2"
aws_profile = "kr-Infra"

# 리소스 이름 prefix (모든 리소스 이름을 통합 관리)
# 예: "infrakr-test" → "infrakr-test-vpc", "infrakr-test-ap-alb", "infrakr-test-ap-0" 등
name_prefix = "infrakr-test"

vpc_cidr = "10.160.0.0/16"

# 사용할 가용 영역 지정
availability_zones = ["us-west-2a", "us-west-2c"]

public_subnet_cidrs  = ["10.160.1.0/24", "10.160.2.0/24"]
private_subnet_cidrs = ["10.160.10.0/24", "10.160.20.0/24"]

key_name = "infra-nopass"

common_tags = {
  Service     = "test"
  Project     = "infrakr-test"
  ChorusCost_Tag1 = "infra-kr"
  ManagedBy   = "terraform"
}

# ACM 인증서 ARN 목록 (*.cocone.co.kr, *.cocone-m.com)
# us-west-2 리전의 인증서 ARN
certificate_arns = [
  "arn:aws:acm:us-west-2:611680202326:certificate/99cec898-d5bd-4e0a-b700-9dbcdf81d2da",  # *.cocone.co.kr
  "arn:aws:acm:us-west-2:611680202326:certificate/9f5c4cde-53c1-4a6a-b3ac-661cc249b986",  # *.cocone-m.com
]

# CloudFront 커스텀 도메인 설정
cloudfront_custom_domain = "infrakr-test-cdn.cocone.co.kr"

# VPN Gateway ID (Site-to-Site VPN 연결용) - 주석 처리됨
# 이 값이 설정되면 모든 Route Table에 10.15.0.0/16 -> VPN Gateway 라우트가 자동으로 추가됩니다
# vpn_gateway_id = "vgw-01b9cc782eed4d088"
