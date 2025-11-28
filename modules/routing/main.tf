# ============================================================================
# 라우팅 모듈 - 모든 라우팅 테이블 설정 통합 관리
# ============================================================================
# VPN Gateway, VPC Peering 등 추가 라우팅을 한 곳에서 관리

# ============================================================================
# VPN Gateway 라우팅 (사무실 네트워크: 10.15.0.0/16)
# ============================================================================
# 모든 라우팅 테이블에 사무실 네트워크로의 라우트 추가

# Public Route Table에 VPN Gateway 라우트 추가
resource "aws_route" "public_to_office_vpn" {
  route_table_id         = var.public_route_table_id
  destination_cidr_block = var.vpn_remote_network_cidr  # 10.15.0.0/16
  gateway_id             = var.vpn_gateway_id
}

# Private Route Tables에 VPN Gateway 라우트 추가
resource "aws_route" "private_to_office_vpn" {
  count = length(var.private_route_table_ids)

  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = var.vpn_remote_network_cidr  # 10.15.0.0/16
  gateway_id             = var.vpn_gateway_id
}


