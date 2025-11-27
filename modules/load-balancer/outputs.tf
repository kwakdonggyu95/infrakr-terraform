# ============================================================================
# Load Balancer 모듈 출력값 정의
# ============================================================================

# 로드 밸런서 ARN
# 로드 밸런서의 Amazon Resource Name
# 다른 리소스에서 참조하거나 IAM 정책 작성 시 사용
output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

# 로드 밸런서 DNS 이름
# 웹 브라우저에서 접속할 때 사용하는 주소
# 예: infrakr-test-alb-1234567890.us-west-2.elb.amazonaws.com
output "dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

# 로드 밸런서 호스팅 영역 ID
# Route 53에서 별칭 레코드를 생성할 때 사용
output "zone_id" {
  description = "Canonical hosted zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

# 타겟 그룹 ARN
# 타겟 그룹의 Amazon Resource Name
# 다른 리소스에서 참조할 때 사용
output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.web.arn
}
