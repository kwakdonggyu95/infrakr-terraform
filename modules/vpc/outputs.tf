# ============================================================================
# VPC 모듈 출력값 정의
# ============================================================================
# 생성된 VPC와 서브넷 정보를 다른 모듈에서 참조할 수 있도록 출력합니다.

# VPC ID
# 생성된 VPC의 고유 식별자
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

# VPC CIDR 블록
# 생성된 VPC의 IP 주소 범위
output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# 인터넷 게이트웨이 ID
# VPC와 인터넷을 연결하는 게이트웨이의 ID
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# 퍼블릭 서브넷 ID 목록
# 생성된 모든 퍼블릭 서브넷의 ID 배열 (CIDR 순서대로 정렬)
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

# 프라이빗 서브넷 ID 목록
# 생성된 모든 프라이빗 서브넷의 ID 배열 (CIDR 순서대로 정렬)
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

# NAT 게이트웨이 ID 목록
# 생성된 모든 NAT 게이트웨이의 ID 배열
output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

# 퍼블릭 라우팅 테이블 ID
# 퍼블릭 서브넷들이 사용하는 라우팅 테이블의 ID
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

# 프라이빗 라우팅 테이블 ID 목록
# 각 프라이빗 서브넷이 사용하는 라우팅 테이블들의 ID 배열
output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}
