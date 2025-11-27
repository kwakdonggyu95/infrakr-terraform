# ============================================================================
# EC2 모듈 - 컴퓨팅 인스턴스 생성
# ============================================================================
# EC2 인스턴스들을 생성합니다:
# - AP 서버 인스턴스 (고가용성을 위해 2개)
# - Alpha 서버 인스턴스 (고가용성을 위해 2개)

# ============================================================================
# Data Source: Amazon Linux 2023 AMI
# ============================================================================
# 최신 Amazon Linux 2023 AMI를 동적으로 조회
# AMI ID는 리전별로 다르고 업데이트되므로 하드코딩 대신 동적 조회 사용
data "aws_ami" "amazon_linux_2023" {
  most_recent = true        # 가장 최신 버전 선택
  owners      = ["amazon"]  # Amazon이 공식 제공하는 AMI만 조회

  # 필터: AMI 이름 패턴
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]  # Amazon Linux 2023, x86_64 아키텍처
  }

  # 필터: 가상화 타입
  filter {
    name   = "virtualization-type"
    values = ["hvm"]  # 하드웨어 가상 머신 (최신 인스턴스 타입 지원)
  }
}

# ============================================================================
# AP Server Instance 0 (AP 서버 인스턴스 0)
# ============================================================================
# 첫 번째 AP 서버 인스턴스
# 프라이빗 서브넷에 배치하여 보안 강화
resource "aws_instance" "ap_0" {
  ami                    = data.aws_ami.amazon_linux_2023.id  # 위에서 조회한 AMI 사용
  instance_type          = "t3.small"                          # 인스턴스 타입 (2 vCPU, 1GB RAM)
  key_name              = var.key_name                         # SSH 접속용 키 페어
  subnet_id             = var.private_subnet_ids[0]            # 첫 번째 프라이빗 서브넷 (AZ-a: 10.160.10.0/24)
  vpc_security_group_ids = [
    var.security_group_ids["linux_default"],  # Linux 기본 보안 그룹
    var.security_group_ids["web_all"]         # 웹 서버 보안 그룹
  ]
  iam_instance_profile   = var.iam_instance_profile_ap != "" ? var.iam_instance_profile_ap : null  # AP 서버용 IAM Instance Profile

  # 루트 볼륨 설정
  root_block_device {
    volume_type = "gp3"    # 최신 GP3 볼륨 타입 (성능 및 비용 효율적)
    volume_size = 30       # 30GB 디스크 크기 (AMI 스냅샷 최소 크기)
    encrypted   = true     # 암호화 활성화 (보안 강화)
  }

  tags = merge(var.tags, {
    Name = "infrakr-test-ap-0"  # 인스턴스 이름
    Service = "test"             # 서비스 구분
    Env     = "production"       # 환경 구분 (production)
  })
}

# ============================================================================
# AP Server Instance 1 (AP 서버 인스턴스 1)
# ============================================================================
# 두 번째 AP 서버 인스턴스
# 다른 가용 영역에 배치하여 고가용성 확보
resource "aws_instance" "ap_1" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.small"                         # 인스턴스 타입 (2 vCPU, 1GB RAM)
  key_name              = var.key_name
  subnet_id             = var.private_subnet_ids[1]            # 두 번째 프라이빗 서브넷 (AZ-c: 10.160.20.0/24)
  vpc_security_group_ids = [
    var.security_group_ids["linux_default"],  # Linux 기본 보안 그룹
    var.security_group_ids["web_all"]         # 웹 서버 보안 그룹
  ]
  iam_instance_profile   = var.iam_instance_profile_ap != "" ? var.iam_instance_profile_ap : null  # AP 서버용 IAM Instance Profile

  root_block_device {
    volume_type = "gp3"
    volume_size = 30       # 30GB 디스크 크기 (AMI 스냅샷 최소 크기)
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name    = "infrakr-test-ap-1"
    Service = "test"
    Env     = "production"       # 환경 구분 (production)
  })
}

# ============================================================================
# Alpha Server Instance 0 (Alpha 서버 인스턴스 0)
# ============================================================================
# 첫 번째 Alpha 서버 인스턴스
# 프라이빗 서브넷에 배치하여 보안 강화
resource "aws_instance" "alpha_0" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.small"                         # 인스턴스 타입 (2 vCPU, 1GB RAM)
  key_name              = var.key_name
  subnet_id             = var.private_subnet_ids[0]            # 첫 번째 프라이빗 서브넷 (AZ-a)
  vpc_security_group_ids = [
    var.security_group_ids["linux_default"],  # Linux 기본 보안 그룹
    var.security_group_ids["web_all"]         # 웹 서버 보안 그룹
  ]
  iam_instance_profile   = var.iam_instance_profile_alpha != "" ? var.iam_instance_profile_alpha : null  # Alpha 서버용 IAM Instance Profile

  root_block_device {
    volume_type = "gp3"
    volume_size = 30       # 30GB 디스크 크기 (AMI 스냅샷 최소 크기)
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name    = "infrakr-test-alpha-0"
    Service = "test"
    Env     = "alpha"
  })
}

# ============================================================================
# Alpha Server Instance 1 (Alpha 서버 인스턴스 1)
# ============================================================================
# 두 번째 Alpha 서버 인스턴스
# 다른 가용 영역에 배치하여 고가용성 확보
resource "aws_instance" "alpha_1" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.small"                         # 인스턴스 타입 (2 vCPU, 1GB RAM)
  key_name              = var.key_name
  subnet_id             = var.private_subnet_ids[1]            # 두 번째 프라이빗 서브넷 (AZ-c: 10.160.20.0/24)
  vpc_security_group_ids = [
    var.security_group_ids["linux_default"],  # Linux 기본 보안 그룹
    var.security_group_ids["web_all"]         # 웹 서버 보안 그룹
  ]
  iam_instance_profile   = var.iam_instance_profile_alpha != "" ? var.iam_instance_profile_alpha : null  # Alpha 서버용 IAM Instance Profile

  root_block_device {
    volume_type = "gp3"
    volume_size = 30       # 30GB 디스크 크기 (AMI 스냅샷 최소 크기)
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name    = "infrakr-test-alpha-1"
    Service = "test"
    Env     = "alpha"
  })
}
