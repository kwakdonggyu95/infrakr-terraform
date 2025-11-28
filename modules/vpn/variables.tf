# ============================================================================
# VPN 모듈 변수 정의
# ============================================================================

# VPC ID
# VPN Gateway를 연결할 VPC의 ID
variable "vpc_id" {
  description = "ID of the VPC to attach the VPN Gateway"
  type        = string
}

# Customer Gateway BGP ASN
# Customer Gateway의 BGP 자율 시스템 번호 (정적 라우팅 사용 시 선택사항)
variable "customer_gateway_bgp_asn" {
  description = "BGP ASN for the Customer Gateway"
  type        = number
  default     = 65000
}

# Customer Gateway IP 주소
# 온프레미스 네트워크(Fortigate)의 공인 IP 주소
variable "customer_gateway_ip_address" {
  description = "Public IP address of the Customer Gateway (Fortigate)"
  type        = string
}

# Customer Gateway 이름
variable "customer_gateway_name" {
  description = "Name of the Customer Gateway"
  type        = string
  default     = ""
}

# VPN Gateway 이름
variable "vpn_gateway_name" {
  description = "Name of the VPN Gateway"
  type        = string
  default     = ""
}

# VPN Connection 이름
variable "vpn_connection_name" {
  description = "Name of the VPN Connection"
  type        = string
  default     = ""
}

# 정적 라우팅 사용 여부
variable "static_routes_only" {
  description = "Whether to use static routes only (true) or dynamic routing (false)"
  type        = bool
  default     = true
}

# 원격 네트워크 CIDR (정적 라우팅 사용 시)
# 사무실 네트워크의 CIDR 블록 (예: 10.15.0.0/16)
variable "remote_network_cidr" {
  description = "Remote network CIDR block for static routing (e.g., 10.15.0.0/16)"
  type        = string
  default     = ""
}

# 리소스 태그
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

