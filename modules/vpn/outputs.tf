# ============================================================================
# VPN 모듈 출력값 정의
# ============================================================================

# Customer Gateway ID
output "customer_gateway_id" {
  description = "ID of the Customer Gateway"
  value       = aws_customer_gateway.main.id
}

# VPN Gateway ID
output "vpn_gateway_id" {
  description = "ID of the VPN Gateway"
  value       = aws_vpn_gateway.main.id
}

# VPN Connection ID
output "vpn_connection_id" {
  description = "ID of the VPN Connection"
  value       = aws_vpn_connection.main.id
}

# VPN Connection 터널 정보 (Fortigate 설정용)
output "vpn_connection_tunnel1_address" {
  description = "The public IP address of the first VPN tunnel"
  value       = aws_vpn_connection.main.tunnel1_address
}

output "vpn_connection_tunnel2_address" {
  description = "The public IP address of the second VPN tunnel"
  value       = aws_vpn_connection.main.tunnel2_address
}

output "vpn_connection_tunnel1_preshared_key" {
  description = "The preshared key of the first VPN tunnel (for Fortigate configuration)"
  value       = aws_vpn_connection.main.tunnel1_preshared_key
  sensitive   = true
}

output "vpn_connection_tunnel2_preshared_key" {
  description = "The preshared key of the second VPN tunnel (for Fortigate configuration)"
  value       = aws_vpn_connection.main.tunnel2_preshared_key
  sensitive   = true
}

