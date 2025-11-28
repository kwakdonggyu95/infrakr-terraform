# ============================================================================
# 라우팅 모듈 변수 정의
# ============================================================================

# Public Route Table ID
variable "public_route_table_id" {
  description = "ID of the public route table"
  type        = string
}

# Private Route Table IDs
variable "private_route_table_ids" {
  description = "IDs of the private route tables"
  type        = list(string)
}

# VPN Gateway ID
variable "vpn_gateway_id" {
  description = "ID of the VPN Gateway"
  type        = string
  default     = ""
}

# VPN 원격 네트워크 CIDR
variable "vpn_remote_network_cidr" {
  description = "Remote network CIDR block for VPN routing (e.g., 10.15.0.0/16)"
  type        = string
  default     = ""
}


