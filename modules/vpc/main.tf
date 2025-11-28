# ============================================================================
# VPC 모듈 - 네트워크 인프라 생성
# ============================================================================
# 이 모듈은 InfraKR 계정에서 VPC, 서브넷, 라우팅 테이블 등을 직접 생성합니다.

# ============================================================================
# VPC 생성
# ============================================================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# ============================================================================
# Internet Gateway 생성
# ============================================================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# ============================================================================
# Public Subnets 생성
# ============================================================================
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${substr(var.availability_zones[count.index], -1, 1)}"
    Type = "Public"
  })
}

# ============================================================================
# Private Subnets 생성
# ============================================================================
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${substr(var.availability_zones[count.index], -1, 1)}"
    Type = "Private"
  })
}

# ============================================================================
# Elastic IPs for NAT Gateways
# ============================================================================
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${substr(var.availability_zones[count.index], -1, 1)}"
  })
}

# ============================================================================
# NAT Gateways 생성
# ============================================================================
resource "aws_nat_gateway" "main" {
  count = length(var.public_subnet_cidrs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-${substr(var.availability_zones[count.index], -1, 1)}"
  })

  depends_on = [aws_internet_gateway.main]
}

# ============================================================================
# Public Route Table 생성
# ============================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # 기본 라우트는 별도 aws_route 리소스로 관리 (routing 모듈에서)
  # route 블록을 제거하여 aws_route 리소스와의 충돌 방지

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

# Public Route Table 기본 라우트 (0.0.0.0/0 → Internet Gateway)
resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# ============================================================================
# Private Route Tables 생성
# ============================================================================
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  # 기본 라우트는 별도 aws_route 리소스로 관리
  # route 블록을 제거하여 aws_route 리소스와의 충돌 방지

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt-${substr(var.availability_zones[count.index], -1, 1)}"
  })
}

# Private Route Tables 기본 라우트 (0.0.0.0/0 → NAT Gateway)
resource "aws_route" "private_default" {
  count = length(var.private_subnet_cidrs)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# ============================================================================
# Public Route Table Associations
# ============================================================================
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================================================
# Private Route Table Associations
# ============================================================================
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
