# ============================================================================
# Security Groups 모듈 - 네트워크 보안 규칙 정의
# ============================================================================
# 보안 그룹은 인바운드/아웃바운드 트래픽을 제어하는 가상 방화벽입니다.
# 각 보안 그룹은 특정 용도에 맞는 포트와 프로토콜을 허용합니다.

# ============================================================================
# Linux Default Security Group
# ============================================================================
# 기본 Linux 서버용 보안 그룹
# SSH 접속, VPC 내부 통신, 다양한 서비스 포트 허용
resource "aws_security_group" "linux_default" {
  name        = "LinuxDefault"
  description = "LinuxDefault security group"
  vpc_id      = var.vpc_id  # 이 보안 그룹이 속할 VPC

  # 인바운드 규칙: VPC 내부에서 모든 트래픽 허용
  # VPC 내부 리소스 간 통신을 위해 필요
  ingress {
    description = "All traffic from VPC"
    from_port   = 0          # 모든 포트
    to_port     = 0          # 모든 포트
    protocol    = "-1"       # 모든 프로토콜
    cidr_blocks = ["10.160.0.0/16"]  # VPC CIDR 블록
  }

  # 인바운드 규칙: 전체 트래픽 허용 (특정 사무실 및 AWS VPC)
  # Tokyo/Seoul 사무실, AWS VPC, VPN, Gnosis EKS 등에서의 접근 허용
  ingress {
    description = "All traffic from offices and AWS VPCs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "10.10.0.0/16",        # tokyo office
      "10.15.0.0/16",        # seoul office
      "10.70.0.0/16",        # tokyo aws vpc
      "10.71.0.0/16",        # seoul aws vpc
      "221.148.82.216/32",   # nonhyun office
      "13.125.17.124/32",    # QA VPN natgateway a
      "3.36.236.7/32",       # QA VPN natgateway c
      "220.151.36.122/32",   # tokyo office
      "10.210.0.0/16",       # gnosis eks tokyo subnet
      "52.192.170.174/32",   # gnosis eks tokyo nat a
      "52.193.179.245/32",   # gnosis eks tokyo nat c
    ]
  }

  # 인바운드 규칙: SSH 접속 허용 (포트 22)
  # 서버 관리 및 원격 접속을 위해 필요 (특정 NAT Gateway 및 사무실 IP만 허용)
  ingress {
    description = "SSH from NAT Gateways and offices"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "54.65.195.20/32",     # tokyo natgateway a
      "52.199.176.73/32",    # tokyo natgateway c
      "152.165.119.105/32",  # tokyo office
      "52.79.102.179/32",    # seoul natgateway a
      "52.79.103.88/32",     # seoul natgateway c
      "221.148.82.216/32",   # nonhyun office
      "220.151.36.122/32",   # Tokyo Office IP
    ]
  }

  # 인바운드 규칙: PostgreSQL (포트 5432)
  # 데이터베이스 접근 허용
  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # 인바운드 규칙: Redash (포트 5000)
  # 데이터 시각화 도구 접근 허용
  ingress {
    description = "Redash"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 인바운드 규칙: Filebeat (포트 5044)
  # 로그 수집 도구 접근 허용
  ingress {
    description = "Filebeat"
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # 인바운드 규칙: Logstash (포트 9600)
  # 로그 처리 도구 접근 허용
  ingress {
    description = "Logstash"
    from_port   = 9600
    to_port     = 9600
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # 인바운드 규칙: Kibana (포트 5601)
  # 로그 시각화 도구 접근 허용
  ingress {
    description = "Kibana"
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # 인바운드 규칙: Custom Port (포트 50001)
  # Nonhyun 사무실에서의 접근 허용
  ingress {
    description = "Custom port 50001 from nonhyun office"
    from_port   = 50001
    to_port     = 50001
    protocol    = "tcp"
    cidr_blocks = ["221.148.82.216/32"]
  }

  # 인바운드 규칙: Redash Internal (포트 18080)
  # Redash 내부 통신 허용
  ingress {
    description = "Redash Internal"
    from_port   = 18080
    to_port     = 18080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # 인바운드 규칙: ICMP 허용 (핑 테스트 등)
  # 네트워크 진단 및 모니터링을 위해 필요 (특정 IP만 허용)
  ingress {
    description = "ICMP from NAT Gateways and offices"
    from_port   = -1         # ICMP는 포트 개념이 없음
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [
      "54.65.195.20/32",     # tokyo natgateway a
      "52.199.176.73/32",    # tokyo natgateway c
      "152.165.119.105/32",  # tokyo office
      "52.79.102.179/32",    # seoul natgateway a
      "52.79.103.88/32",     # seoul natgateway c
      "221.148.82.216/32",   # nonhyun office
      "220.151.36.122/32",   # Tokyo Office IP
      "10.210.0.0/16",       # gnosis eks tokyo subnet
      "52.192.170.174/32",   # gnosis eks tokyo nat a
      "52.193.179.245/32",   # gnosis eks tokyo nat c
    ]
  }

  # 인바운드 규칙: Elasticsearch (포트 9200)
  # 검색 엔진 접근 허용
  ingress {
    description = "Elasticsearch"
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # 아웃바운드 규칙: 모든 트래픽 허용
  # 인스턴스가 외부로 나가는 모든 통신 허용
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "LinuxDefault"
  })
}

# ============================================================================
# Web All Security Group
# ============================================================================
# 웹 서버 및 로드 밸런서용 보안 그룹
# HTTP, HTTPS, 커스텀 포트를 허용
resource "aws_security_group" "web_all" {
  name        = "web-all"
  description = "WebAll security group"
  vpc_id      = var.vpc_id

  # 인바운드 규칙: HTTP 트래픽 허용 (포트 80)
  # 웹 브라우저에서 접속할 때 사용
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 인터넷에서 접속 가능
  }

  # 인바운드 규칙: HTTPS 트래픽 허용 (포트 443)
  # 암호화된 웹 트래픽
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 인바운드 규칙: 커스텀 포트 8090 허용
  # 애플리케이션별 특정 포트가 필요한 경우 사용
  ingress {
    description = "Custom port 8090"
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드 규칙: 모든 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "web-all"
  })
}

