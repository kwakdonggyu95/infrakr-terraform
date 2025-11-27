# ============================================================================
# EC2 모듈 출력값 정의
# ============================================================================

# AP 인스턴스 ID 목록
# AP 로드 밸런서의 타겟 그룹에 등록할 AP 서버 인스턴스들의 ID
output "ap_instance_ids" {
  description = "IDs of AP instances"
  value       = [aws_instance.ap_0.id, aws_instance.ap_1.id]
}

# Alpha 인스턴스 ID 목록
# Alpha 로드 밸런서의 타겟 그룹에 등록할 Alpha 서버 인스턴스들의 ID
output "alpha_instance_ids" {
  description = "IDs of Alpha instances"
  value       = [aws_instance.alpha_0.id, aws_instance.alpha_1.id]
}

# AP 인스턴스 0의 프라이빗 IP
# 내부 통신이나 설정 파일 작성 시 사용
output "ap_0_private_ip" {
  description = "Private IP of AP instance 0"
  value       = aws_instance.ap_0.private_ip
}

# AP 인스턴스 1의 프라이빗 IP
# 내부 통신이나 설정 파일 작성 시 사용
output "ap_1_private_ip" {
  description = "Private IP of AP instance 1"
  value       = aws_instance.ap_1.private_ip
}

# Alpha 인스턴스 0의 프라이빗 IP
# 내부 통신이나 설정 파일 작성 시 사용
output "alpha_0_private_ip" {
  description = "Private IP of Alpha instance 0"
  value       = aws_instance.alpha_0.private_ip
}

# Alpha 인스턴스 1의 프라이빗 IP
# 내부 통신이나 설정 파일 작성 시 사용
output "alpha_1_private_ip" {
  description = "Private IP of Alpha instance 1"
  value       = aws_instance.alpha_1.private_ip
}

# 모든 인스턴스 ID 목록
# 전체 인스턴스 목록이 필요한 경우 사용 (모니터링, 백업 등)
output "all_instance_ids" {
  description = "All instance IDs"
  value = [
    aws_instance.ap_0.id,
    aws_instance.ap_1.id,
    aws_instance.alpha_0.id,
    aws_instance.alpha_1.id
  ]
}
