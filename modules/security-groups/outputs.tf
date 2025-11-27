# ============================================================================
# Security Groups 모듈 출력값 정의
# ============================================================================

# 보안 그룹 ID 맵
# 보안 그룹 이름을 키로, ID를 값으로 하는 맵
# 다른 모듈에서 특정 보안 그룹을 쉽게 참조할 수 있도록 함
output "security_group_ids" {
  description = "Map of security group names to IDs"
  value = {
    linux_default = aws_security_group.linux_default.id  # 기본 Linux 보안 그룹
    web_all       = aws_security_group.web_all.id        # 웹 서버 보안 그룹 (web-all)
  }
}

# Linux Default 보안 그룹 ID
# 개별 보안 그룹 ID를 직접 참조할 때 사용
output "linux_default_sg_id" {
  description = "ID of the Linux Default security group"
  value       = aws_security_group.linux_default.id
}

# Web All 보안 그룹 ID
# 웹 서버 및 로드 밸런서에 사용
output "web_all_sg_id" {
  description = "ID of the Web All security group"
  value       = aws_security_group.web_all.id
}

