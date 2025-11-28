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

# ============================================================================
# VPN 설정 (Site-to-Site VPN 연결)
# ============================================================================
# 사무실 네트워크(10.15.0.0/16)와 VPC를 연결하는 Site-to-Site VPN

# Customer Gateway 설정
customer_gateway_ip_address = "221.148.82.216"  # Fortigate 공인 IP 주소
customer_gateway_bgp_asn   = 65000              # BGP ASN (정적 라우팅 사용 시 선택사항)
customer_gateway_name      = "InfraKR-cgw-nonhyun"

# VPN Gateway 설정
vpn_gateway_name = "InfraKR-vgw-oregon"

# VPN Connection 설정
vpn_connection_name   = "InfraKR-vpn-nonhyun"
vpn_static_routes_only = true                   # 정적 라우팅 사용
vpn_remote_network_cidr = "10.15.0.0/16"        # 사무실 네트워크 CIDR

# ============================================================================
# VPC Peering 설정 (크로스 리전/크로스 계정) - 제거됨
# ============================================================================
# 초기 구성에서는 VPC Peering을 제외합니다.
# 필요시 나중에 추가할 수 있습니다.
