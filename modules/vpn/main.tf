# ============================================================================
# VPN 모듈 - Site-to-Site VPN 연결
# ============================================================================
# 사무실 네트워크(10.15.0.0/16)와 VPC를 연결하는 Site-to-Site VPN 구성

# ============================================================================
# Customer Gateway 생성
# ============================================================================
# 온프레미스 네트워크(Fortigate)의 공인 IP 주소를 등록
resource "aws_customer_gateway" "main" {
  bgp_asn    = var.customer_gateway_bgp_asn
  ip_address = var.customer_gateway_ip_address
  type       = "ipsec.1"

  tags = merge(var.tags, {
    Name = var.customer_gateway_name
  })
}

# ============================================================================
# VPN Gateway 생성
# ============================================================================
# VPC에 연결할 가상 프라이빗 게이트웨이 생성
resource "aws_vpn_gateway" "main" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = var.vpn_gateway_name
  })
}

# ============================================================================
# VPN Connection 생성
# ============================================================================
# Customer Gateway와 VPN Gateway 간의 Site-to-Site VPN 연결 생성
resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = var.static_routes_only

  tags = merge(var.tags, {
    Name = var.vpn_connection_name
  })
}

# ============================================================================
# Static Routes (선택사항)
# ============================================================================
# 정적 라우팅을 사용하는 경우, 원격 네트워크 CIDR을 지정
# 동적 라우팅(BGP)을 사용하는 경우 이 리소스는 필요 없음
resource "aws_vpn_connection_route" "office_network" {
  count = var.static_routes_only && var.remote_network_cidr != "" ? 1 : 0

  vpn_connection_id      = aws_vpn_connection.main.id
  destination_cidr_block = var.remote_network_cidr
}

