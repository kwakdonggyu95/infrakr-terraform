# ============================================================================
# Load Balancer 모듈 - Application Load Balancer 구성
# ============================================================================
# 웹 트래픽을 여러 백엔드 서버로 분산하는 로드 밸런서를 생성합니다.
# 고가용성과 부하 분산을 제공합니다.

# ============================================================================
# Application Load Balancer (ALB)
# ============================================================================
# Layer 7 (애플리케이션 레이어) 로드 밸런서
# HTTP/HTTPS 트래픽을 여러 타겟으로 분산
resource "aws_lb" "main" {
  name               = var.alb_name  # 로드 밸런서 이름 (변수로 받음)
  internal           = false                # false = 인터넷 연결형 (퍼블릭), true = 내부용
  load_balancer_type = "application"        # Application Load Balancer 타입
  security_groups    = [var.security_group_id]  # 웹 트래픽 허용 보안 그룹
  subnets            = var.public_subnet_ids     # 퍼블릭 서브넷에 배치 (인터넷 접근 필요)

  enable_deletion_protection = false  # 삭제 보호 비활성화 (테스트 환경)

  tags = merge(var.tags, {
    Name = var.alb_name
  })
}

# ============================================================================
# Target Group (타겟 그룹)
# ============================================================================
# 로드 밸런서가 트래픽을 전달할 백엔드 서버들의 그룹
# 헬스 체크를 통해 정상 서버만 트래픽을 받도록 함
resource "aws_lb_target_group" "web" {
  name     = var.target_group_name  # 타겟 그룹 이름 (변수로 받음)
  port     = 80                      # 타겟 포트 (백엔드 서버의 HTTP 포트)
  protocol = "HTTP"                  # 프로토콜
  vpc_id   = var.vpc_id              # VPC ID

  # 헬스 체크 설정
  # 백엔드 서버의 상태를 주기적으로 확인하여 정상 서버만 트래픽 전달
  health_check {
    enabled             = true         # 헬스 체크 활성화
    healthy_threshold   = 2            # 정상 판정을 위한 연속 성공 횟수
    interval            = 30           # 헬스 체크 간격 (초)
    matcher             = "200"        # 정상 응답 코드 (HTTP 200)
    path                = "/"          # 헬스 체크 경로
    port                = "traffic-port"  # 트래픽 포트와 동일한 포트 사용
    protocol            = "HTTP"       # 헬스 체크 프로토콜
    timeout             = 5            # 헬스 체크 타임아웃 (초)
    unhealthy_threshold = 2            # 비정상 판정을 위한 연속 실패 횟수
  }

  tags = merge(var.tags, {
    Name = var.target_group_name
  })
}

# ============================================================================
# Target Group Attachments (타겟 그룹 연결)
# ============================================================================
# EC2 인스턴스들을 타겟 그룹에 등록
# 로드 밸런서가 이 인스턴스들로 트래픽을 분산
resource "aws_lb_target_group_attachment" "web" {
  count = length(var.target_instances)  # 타겟 인스턴스 개수만큼 생성

  target_group_arn = aws_lb_target_group.web.arn  # 위에서 생성한 타겟 그룹
  target_id        = var.target_instances[count.index]  # 각 웹 서버 인스턴스 ID
  port             = 80                              # 타겟 포트
}

# ============================================================================
# ALB Listener - HTTP (로드 밸런서 리스너)
# ============================================================================
# 로드 밸런서가 특정 포트에서 들어오는 트래픽을 처리하는 규칙
# 포트 80(HTTP)으로 들어오는 모든 트래픽을 타겟 그룹으로 전달
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn  # 위에서 생성한 로드 밸런서
  port              = "80"              # 리스너 포트 (HTTP)
  protocol          = "HTTP"            # 프로토콜

  # 기본 액션: 모든 트래픽을 타겟 그룹으로 전달
  default_action {
    type             = "forward"                    # 포워딩 액션
    target_group_arn = aws_lb_target_group.web.arn  # 타겟 그룹으로 전달
  }

  tags = merge(var.tags, {
    Name = "${var.alb_name}-http-listener"
  })
}

# ============================================================================
# ALB Listener - HTTPS (로드 밸런서 리스너)
# ============================================================================
# 포트 443(HTTPS)으로 들어오는 모든 트래픽을 타겟 그룹으로 전달
# SSL/TLS 인증서를 사용하여 암호화된 통신 제공
# HTTPS 리스너 (여러 인증서 지원 - SNI 사용)
# ALB listener는 첫 번째 인증서를 기본으로 사용
# 참고: Terraform의 aws_lb_listener는 여러 인증서를 동적으로 지원하지 않으므로
# 첫 번째 인증서만 사용 (추가 인증서가 필요한 경우 AWS 콘솔에서 수동 추가)
resource "aws_lb_listener" "https" {
  count             = length(var.certificate_arns) > 0 ? 1 : 0  # 인증서가 제공된 경우에만 생성
  load_balancer_arn = aws_lb.main.arn
  port              = "443"              # 리스너 포트 (HTTPS)
  protocol          = "HTTPS"             # 프로토콜
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"  # 최신 TLS 정책

  # 기본 인증서 (첫 번째 인증서 사용)
  # 여러 인증서가 제공된 경우 첫 번째 인증서만 사용
  certificate_arn = var.certificate_arns[0]

  # 기본 액션: 모든 트래픽을 타겟 그룹으로 전달
  default_action {
    type             = "forward"                    # 포워딩 액션
    target_group_arn = aws_lb_target_group.web.arn  # 타겟 그룹으로 전달
  }

  tags = merge(var.tags, {
    Name = "${var.alb_name}-https-listener"
  })
}
