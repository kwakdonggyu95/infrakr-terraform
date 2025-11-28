# InfraKR 계정 오레곤 리전 프로비저닝 계획

## 1. 프로젝트 개요

### 목적
- **계정**: InfraKR (kr-Infra 프로필)
- **리전**: 오레곤 (us-west-2)
- **환경**: 테스트 환경
- **목적**: InfraKR 계정의 오레곤 리전에 테스트 인프라 구축

### 주요 특징
- VPC, 서브넷, 라우팅 테이블을 InfraKR 계정에서 직접 생성
- Amazon Linux 2023 AMI 사용
- 고가용성을 위한 다중 AZ 구성

---

## 2. 아키텍처 개요

### 네트워크 구성
```
VPC (10.160.0.0/16) - InfraKR 계정에서 생성
├── Internet Gateway
├── Public Subnets
│   ├── us-west-2a: 10.160.1.0/24
│   └── us-west-2c: 10.160.2.0/24
├── NAT Gateways (2개)
└── Private Subnets
    ├── us-west-2a: 10.160.10.0/24
    └── us-west-2c: 10.160.20.0/24
```

### 리소스 배치
- **Public Subnets**: Application Load Balancer
- **Private Subnets**: EC2 인스턴스들 (ap 서버, alpha서버)
- **S3 버킷**: 정적 콘텐츠 저장 (이미지 파일 등)
- **CloudFront**: S3 버킷의 콘텐츠를 전 세계에 배포하는 CDN

### 네트워크 연결
- **VPN 연결**: 사무실 네트워크(10.15.0.0/16)와 VPC 연결
  - Customer Gateway: Fortigate 공인 IP 등록
  - VPN Gateway: VPC에 연결
  - Site-to-Site VPN Connection: 양쪽 게이트웨이 연결
  - 라우팅: 모든 Route Table에 10.15.0.0/16 → VPN Gateway 라우트 추가

---

## 3. 프로비저닝할 리소스 목록

### 3.1 네트워크 리소스 (생성)
- ✅ **VPC** (10.160.0.0/16)
  - DNS 호스트네임 활성화
  - DNS 지원 활성화
- ✅ **Internet Gateway**
  - VPC와 인터넷 연결
- ✅ **Public Subnets** (2개)
  - us-west-2a: 10.160.1.0/24
  - us-west-2c: 10.160.2.0/24
  - 자동 퍼블릭 IP 할당 활성화
- ✅ **Private Subnets** (2개)
  - us-west-2a: 10.160.10.0/24
  - us-west-2c: 10.160.20.0/24
- ✅ **Elastic IPs** (2개)
  - NAT Gateway용 Elastic IP
- ✅ **NAT Gateways** (2개)
  - 각 Public Subnet에 1개씩 배치
  - Private Subnet의 인터넷 접근 제공
- ✅ **Route Tables**
  - Public Route Table (1개): Internet Gateway로 라우팅
  - Private Route Tables (2개): 각 NAT Gateway로 라우팅
- ✅ **Route Table Associations**
  - Public Subnets → Public Route Table
  - Private Subnets → Private Route Tables
- ✅ **기본 라우트** (aws_route 리소스)
  - Public Route Table: 0.0.0.0/0 → Internet Gateway
  - Private Route Tables: 0.0.0.0/0 → NAT Gateway (각각)

### 3.2 보안 그룹 (생성)
- ✅ **LinuxDefault**: 기본 Linux 서버용
  - VPC 내부 통신 허용 (10.160.0.0/16)
  - 전체 트래픽 허용 (특정 사무실 및 AWS VPC)
    - 10.10.0.0/16 (tokyo office)
    - 10.15.0.0/16 (seoul office)
    - 10.70.0.0/16 (tokyo aws vpc)
    - 10.71.0.0/16 (seoul aws vpc)
    - 221.148.82.216/32 (nonhyun office)
    - 13.125.17.124/32 (QA VPN natgateway a)
    - 3.36.236.7/32 (QA VPN natgateway c)
    - 220.151.36.122/32 (tokyo office)
    - 10.210.0.0/16 (gnosis eks tokyo subnet)
    - 52.192.170.174/32 (gnosis eks tokyo nat a)
    - 52.193.179.245/32 (gnosis eks tokyo nat c)
  - SSH (22) 허용 (특정 NAT Gateway 및 사무실 IP만)
    - 54.65.195.20/32 (tokyo natgateway a)
    - 52.199.176.73/32 (tokyo natgateway c)
    - 152.165.119.105/32 (tokyo office)
    - 52.79.102.179/32 (seoul natgateway a)
    - 52.79.103.88/32 (seoul natgateway c)
    - 221.148.82.216/32 (nonhyun office)
    - 220.151.36.122/32 (Tokyo Office IP)
  - PostgreSQL (5432) 허용 (10.0.0.0/8)
  - Redash (5000) 허용 (0.0.0.0/0)
  - Filebeat (5044) 허용 (10.0.0.0/8)
  - Logstash (9600) 허용 (10.0.0.0/8)
  - Kibana (5601) 허용 (10.0.0.0/8)
  - Custom Port (50001) 허용 (221.148.82.216/32 - nonhyun office)
  - Redash Internal (18080) 허용 (10.0.0.0/8)
  - ICMP 허용 (특정 NAT Gateway 및 사무실 IP만)
    - 54.65.195.20/32, 52.199.176.73/32, 152.165.119.105/32
    - 52.79.102.179/32, 52.79.103.88/32, 221.148.82.216/32
    - 220.151.36.122/32, 10.210.0.0/16
    - 52.192.170.174/32, 52.193.179.245/32
  - Elasticsearch (9200) 허용 (10.0.0.0/8)
  - 아웃바운드: 모든 트래픽 허용 (0.0.0.0/0)
- ✅ **WebAll**: 웹 서버 및 ALB용
  - HTTP (80) 허용
  - HTTPS (443) 허용
  - 커스텀 포트 8090 허용


### 3.3 IAM 리소스 (생성)
- ✅ **IAM Role**: `infrakr-test-production-ec2-role` - infrakr-test-ap* 서버들에 적용
  - EC2 서비스가 assume할 수 있도록 설정
  - AmazonSSMManagedInstanceCore 정책 연결 (SSM 접속용)
  - S3 접근 정책 연결 (S3 버킷 읽기/쓰기 권한)
- ✅ **IAM Instance Profile**: `infrakr-test-production-ec2-role-profile`
- ✅ **IAM Policy**: `infrakr-test-s3-{버킷이름}` - S3 버킷 접근 정책 (자동 생성)

- ✅ **IAM Role**: `infrakr-test-alpha-ec2-role` - infrakr-test-alpha* 서버들에 적용
  - EC2 서비스가 assume할 수 있도록 설정
  - AmazonSSMManagedInstanceCore 정책 연결 (SSM 접속용)
  - S3 접근 정책 연결 (S3 버킷 읽기/쓰기 권한)
- ✅ **IAM Instance Profile**: `infrakr-test-alpha-ec2-role-profile`
- ✅ **IAM Policy**: `infrakr-test-s3-{버킷이름}` - S3 버킷 접근 정책 (자동 생성)


### 3.4 EC2 인스턴스 (생성)
- ✅ **infrakr-test-ap-0**
  - 인스턴스 타입: t3.micro (2 vCPU, 1GB RAM)
  - 서브넷: Private Subnet (us-west-2a)
  - 볼륨: GP3, 30GB, 암호화
  - 보안 그룹: LinuxDefault
  - IAM Role: infrakr-test-production-ec2-role
  - 태그: Service=test, Env=alpha
- ✅ **infrakr-test-ap-1**
  - 인스턴스 타입: t3.micro (2 vCPU, 1GB RAM)
  - 서브넷: Private Subnet (us-west-2c)
  - 볼륨: GP3, 30GB, 암호화
  - 보안 그룹: LinuxDefault
  - IAM Role: infrakr-test-production-ec2-role
  - 태그: Service=test, Env=alpha
- ✅ **infrakr-test-alpha-0**
  - 인스턴스 타입: t3.micro (2 vCPU, 1GB RAM)
  - 서브넷: Private Subnet (us-west-2a)
  - 볼륨: GP3, 30GB, 암호화
  - 보안 그룹: LinuxDefault
  - IAM Role: infrakr-test-alpha-ec2-role
  - 태그: Service=test, Env=alpha
- ✅ **infrakr-test-alpha-1**
  - 인스턴스 타입: t3.micro (2 vCPU, 1GB RAM)
  - 서브넷: Private Subnet (us-west-2c)
  - 볼륨: GP3, 30GB, 암호화
  - 보안 그룹: LinuxDefault
  - IAM Role: infrakr-test-alpha-ec2-role
  - 태그: Service=test, Env=alpha


### 3.5 로드 밸런서 (생성)
- ✅ **Application Load Balancer**: `infrakr-test-ap-alb`
  - 타입: Internet-facing (Public)
  - 서브넷: Public Subnets (2개 AZ)
  - 보안 그룹: WebAll
- ✅ **Target Group**: `infrakr-test-ap-tg`
  - 프로토콜: HTTP
  - 포트: 80
  - 헬스 체크: HTTP 200, 경로 `/`, 30초 간격
  - 타겟: infrakr-test-ap-0, infrakr-test-ap-1 (웹 서버 인스턴스)
- ✅ **ALB Listener**: HTTP (포트 80), HTTPS (포트 443, *.cocone.co.kr, *.cocone-m.com 인증서 사용)

- ✅ **Application Load Balancer**: `infrakr-test-alpha-alb`
  - 타입: Internet-facing (Public)
  - 서브넷: Public Subnets (2개 AZ)
  - 보안 그룹: WebAll
- ✅ **Target Group**: `infrakr-test-alpha-tg`
  - 프로토콜: HTTP
  - 포트: 80
  - 헬스 체크: HTTP 200, 경로 `/`, 30초 간격
  - 타겟: infrakr-test-alpha-0, infrakr-test-alpha-1 (웹 서버 인스턴스)
- ✅ **ALB Listener**: HTTP (포트 80), HTTPS (포트 443, *.cocone.co.kr, *.cocone-m.com 인증서 사용)

### 3.6 VPN 연결 (생성)
- ✅ **Customer Gateway**
  - Fortigate 공인 IP 주소 등록
  - BGP ASN 설정 (정적 라우팅 사용 시 선택사항)
- ✅ **VPN Gateway**
  - VPC에 연결된 가상 프라이빗 게이트웨이
  - VPC 생성 후 자동 연결
- ✅ **VPN Connection**
  - Customer Gateway와 VPN Gateway 간 Site-to-Site VPN 연결
  - 정적 라우팅 사용 (static_routes_only = true)
- ✅ **VPN Connection Route**
  - 원격 네트워크 CIDR 등록 (10.15.0.0/16)
- ✅ **라우팅 테이블 라우트**
  - 모든 Route Table에 10.15.0.0/16 → VPN Gateway 라우트 추가

### 3.7 S3 및 CloudFront (생성)
- ✅ **S3 Bucket**: `infrakr-test-s3` (또는 지정된 이름)
  - 버전 관리: 비활성화
  - 퍼블릭 접근 차단: 활성화 (CloudFront OAC를 통해서만 접근)
  - CloudFront Origin Access Control (OAC) 사용
- ✅ **S3 Bucket Policy**: CloudFront OAC를 통한 접근만 허용
- ✅ **CloudFront Origin Access Control (OAC)**: S3 버킷 접근 제어
- ✅ **CloudFront Distribution**: `infrakr-test-cdn` (또는 지정된 이름)
  - Origin: S3 버킷
  - 커스텀 도메인: `infrakr-test.cocone.co.kr` (또는 지정된 도메인)
  - SSL 인증서: us-east-1 리전의 *.cocone.co.kr 인증서 사용
  - IPv6 지원: 활성화
  - 캐시 정책: 기본 캐시 동작 (GET, HEAD만 캐시)
  - 가격 클래스: PriceClass_All (모든 엣지 로케이션)
---

## 4. 주요 설정값

### 4.1 AWS 설정
- **리전**: us-west-2 (오레곤)
- **프로필**: kr-Infra
- **VPC CIDR**: 10.160.0.0/16
- **가용 영역**: us-west-2a, us-west-2c

### 4.2 네트워크 CIDR
- **Public Subnets**: 
  - 10.160.1.0/24 (us-west-2a)
  - 10.160.2.0/24 (us-west-2c)
- **Private Subnets**:
  - 10.160.10.0/24 (us-west-2a)
  - 10.160.20.0/24 (us-west-2c)

### 4.3 EC2 설정
- **AMI**: Amazon Linux 2023 (동적 조회)
- **키 페어**: infra-nopass
- **볼륨 타입**: GP3
- **볼륨 암호화**: 활성화

### 4.4 공통 태그
```hcl
Project     = "infrakr-test"
ManagedBy   = "terraform"
Service     = "test"
ChorusCost_Tag1 = "infra-kr"
```

---

## 5. 프로비저닝 절차

### 5.1 사전 준비사항
1. ✅ AWS CLI 프로필 설정 확인
   ```bash
   aws configure list-profiles
   # kr-Infra 프로필이 존재하는지 확인
   ```

2. ✅ AWS 자격 증명 확인
   ```bash
   aws sts get-caller-identity --profile kr-Infra
   # InfraKR 계정 정보가 나오는지 확인
   ```

3. ✅ VPC CIDR 확인
   - VPC CIDR (10.160.0.0/16)이 다른 VPC와 겹치지 않는지 확인
   - 서브넷 CIDR이 올바르게 설정되었는지 확인

4. ✅ EC2 키 페어 확인
   - `infra-nopass` 키 페어가 오레곤 리전에 존재하는지 확인

5. ✅ ACM 인증서 생성 (선제 작업 필요)
   
   **ALB용 인증서 (us-west-2 리전):**
   - **InfraKR 계정**에서 us-west-2 리전 선택
   - AWS 콘솔 → Certificate Manager → us-west-2 리전
   - "인증서 요청" 클릭
   - 도메인 이름 입력:
     - `*.cocone.co.kr` (첫 번째 인증서)
     - `*.cocone-m.com` (두 번째 인증서, 별도로 요청)
   - 검증 방법: DNS 검증 선택
   - **cocone(base계정)의 Route53**에서 CNAME 레코드 추가하여 검증
   - 검증 완료 후 생성된 인증서 ARN 확인
   - `terraform.tfvars` 파일의 `certificate_arns`에 ARN 추가
   
   **CloudFront용 인증서 (us-east-1 리전):**
   - **InfraKR 계정**에서 **us-east-1 리전** 선택 (중요!)
   - AWS 콘솔 → Certificate Manager → us-east-1 리전
   - "인증서 요청" 클릭
   - 도메인 이름 입력: `*.cocone.co.kr`
   - 검증 방법: DNS 검증 선택
   - **cocone(base계정)의 Route53**에서 CNAME 레코드 추가하여 검증
   - 검증 완료 후 생성된 인증서 ARN 확인
   - `terraform.tfvars` 파일의 `ssl_certificate_arn`에 ARN 추가

### 5.2 Terraform 실행 절차

#### Step 1: 디렉토리 이동
```bash
cd /Users/kwak_donggyu/terraform/infrakr
```

#### Step 2: Terraform 초기화
```bash
terraform init
```

#### Step 3: 실행 계획 확인
```bash
terraform plan -var-file="environments/oregon/terraform.tfvars"
```

**확인 사항:**
- 생성될 리소스 목록 확인
- VPC 및 서브넷이 data source로 올바르게 참조되는지 확인
- 예상 비용 확인 (특히 EC2, ALB)

#### Step 4: 프로비저닝 실행
```bash
terraform apply -var-file="environments/oregon/terraform.tfvars"
```

**주의사항:**
- `yes` 입력 전에 생성될 리소스를 다시 한 번 확인
- 특히 EC2 인스턴스와 ALB는 비용이 발생하므로 주의

#### Step 5: 결과 확인
```bash
# 생성된 리소스 확인
terraform show

# Output 값 확인 (있다면)
terraform output
```

### 5.3 프로비저닝 후 검증

1. **EC2 인스턴스 상태 확인**
   ```bash
   aws ec2 describe-instances \
     --profile kr-Infra \
     --region us-west-2 \
     --filters "Name=tag:Project,Values=infrakr-test" \
     --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' \
     --output table
   ```

2. **ALB 상태 확인**
   ```bash
   # AP ALB 확인
   aws elbv2 describe-load-balancers \
     --profile kr-Infra \
     --region us-west-2 \
     --query 'LoadBalancers[?LoadBalancerName==`infrakr-test-ap-alb`]' \
     --output table
   
   # Alpha ALB 확인
   aws elbv2 describe-load-balancers \
     --profile kr-Infra \
     --region us-west-2 \
     --query 'LoadBalancers[?LoadBalancerName==`infrakr-test-alpha-alb`]' \
     --output table
   ```

3. **SSM 접속 테스트**
   ```bash
   aws ssm start-session \
     --profile kr-Infra \
     --region us-west-2 \
     --target <instance-id>
   ```

---

## 6. 리소스 의존성 및 생성 순서

Terraform이 자동으로 의존성을 해결하지만, 개념적 순서는 다음과 같습니다:

1. **VPC 및 네트워크 리소스 생성**
   - VPC, Internet Gateway, 서브넷, Elastic IP, NAT Gateway, Route Tables 생성
   - 기본 라우트 생성 (0.0.0.0/0 → IGW/NAT Gateway)

2. **보안 그룹 생성**
   - VPC ID 필요

3. **IAM Role 및 Instance Profile 생성**
   - EC2 인스턴스에 필요

4. **EC2 인스턴스 생성**
   - VPC, 서브넷, 보안 그룹, IAM Instance Profile 필요

5. **로드 밸런서 생성**
   - VPC, 서브넷, 보안 그룹 필요
   - EC2 인스턴스 ID 필요 (타겟 그룹 연결)

6. **S3 버킷 생성**
   - 버킷 이름만 필요 (다른 리소스와 독립적)

7. **CloudFront Distribution 생성**
   - S3 버킷 정보 필요 (Origin 설정)
   - us-east-1 리전의 ACM 인증서 필요

8. **VPN 연결 생성**
   - Customer Gateway, VPN Gateway, VPN Connection 생성
   - 라우팅 테이블에 VPN 라우트 추가

9. **S3 버킷 정책 업데이트**
   - CloudFront Distribution ARN 필요 (순환 참조 해결)

---

## 7. 주의사항 및 고려사항

### 7.1 비용 관련
- **EC2 인스턴스**: t3.micro (4개) - 시간당 과금
- **ALB**: 시간당 과금 + 데이터 전송 비용 (2개 ALB)
- **EBS 볼륨**: GP3 볼륨 4개 (30GB x 4)
- **NAT Gateway**: 시간당 과금 (2개, 약 $0.045/시간 × 2 = $0.09/시간)
- **Elastic IP**: NAT Gateway와 연결되어 있으면 비용 발생 안 함
- **VPN Gateway**: 시간당 과금 (약 $0.05/시간)
- **S3 버킷**: 스토리지 비용 (GB당) + 요청 비용 (PUT, GET 등)
- **CloudFront**: 데이터 전송 비용 (GB당) + 요청 비용 (HTTP/HTTPS 요청당)

### 7.2 보안 관련
- SSH 접속은 특정 NAT Gateway 및 사무실 IP만 허용 (보안 강화)
- EC2 인스턴스는 Private Subnet에 배치되어 직접 인터넷 접근 불가
- SSM Session Manager를 통한 접속 권장
- LinuxDefault 보안 그룹은 다양한 서비스 포트를 허용하지만, 대부분 내부 네트워크(10.0.0.0/8)에서만 접근 가능

### 7.3 VPC 및 네트워크 리소스
- VPC, 서브넷, NAT Gateway 등이 InfraKR 계정에서 직접 생성됨
- NAT Gateway는 시간당 과금되므로 비용 발생 (약 $0.045/시간 × 2개 = $0.09/시간)
- Elastic IP는 NAT Gateway와 연결되어 있으면 비용 발생 안 함
- VPC CIDR (10.160.0.0/16)이 다른 VPC와 겹치지 않도록 주의

### 7.4 리전 및 가용 영역
- 모든 리소스는 오레곤 리전 (us-west-2)에 생성
- 가용 영역은 us-west-2a, us-west-2c 사용
- 키 페어도 동일 리전에 존재해야 함

---

## 8. 문제 해결 가이드

### 8.1 VPC 생성 실패
- VPC CIDR가 다른 VPC와 겹치지 않는지 확인
- 서브넷 CIDR이 VPC CIDR 범위 내에 있는지 확인
- 가용 영역이 올바른지 확인 (us-west-2a, us-west-2c)
- IAM 권한이 충분한지 확인 (VPC, 서브넷, NAT Gateway 생성 권한)

### 8.2 EC2 인스턴스 생성 실패
- 서브넷에 충분한 IP 주소가 있는지 확인
- 키 페어가 존재하는지 확인
- IAM Role 권한이 충분한지 확인

### 8.3 ALB 생성 실패
- 퍼블릭 서브넷이 최소 2개 이상인지 확인
- 보안 그룹 규칙이 올바른지 확인

### 8.4 CloudFront 생성 실패
- S3 버킷이 올바르게 생성되었는지 확인
- us-east-1 리전의 ACM 인증서가 존재하는지 확인 (CloudFront는 us-east-1만 지원)
- 커스텀 도메인의 Route53 레코드가 올바르게 설정되었는지 확인

### 8.5 S3 버킷 정책 오류
- CloudFront Distribution ARN이 올바른지 확인
- 순환 참조 문제는 Terraform이 자동으로 해결하지만, 생성 순서 확인 필요

### 8.6 VPN 연결 오류
- Customer Gateway IP 주소가 올바른지 확인
- VPN Gateway가 VPC에 올바르게 연결되었는지 확인
- 라우팅 테이블에 VPN 라우트가 추가되었는지 확인
- Fortigate에서 VPN 터널 설정이 완료되었는지 확인
- VPN Connection 터널 정보 확인 (Terraform outputs 사용)

---

## 9. S3 및 CloudFront 사용 가이드

### 9.1 EC2에서 S3로 이미지 업로드
EC2 인스턴스에서 S3 버킷으로 이미지 파일을 업로드하는 방법:

1. **EC2 인스턴스 접속**
   ```bash
   aws ssm start-session --profile kr-Infra --region us-west-2 --target <instance-id>
   ```

2. **이미지 파일 업로드**
   ```bash
   aws s3 cp image.jpg s3://infrakr-test-s3/images/image.jpg --content-type image/jpeg
   ```

3. **CloudFront를 통해 접근**
   ```
   https://infrakr-test.cocone.co.kr/images/image.jpg
   ```

자세한 내용은 `S3_UPLOAD_GUIDE.md` 파일을 참고하세요.

### 9.2 IAM Role의 S3 접근 권한
- EC2 인스턴스는 IAM Role을 통해 S3 버킷에 접근할 수 있습니다
- 정책 이름: `infrakr-test-s3-{버킷이름}`
- 권한: `s3:ListAllMyBuckets`, `s3:*` (특정 버킷에 대해)

## 10. 향후 확장 계획 (선택사항)

### 추가 가능한 리소스
- CloudWatch 알람 및 대시보드
- RDS 데이터베이스
- 추가 S3 버킷 (다른 용도)
- CloudFront 추가 배포


## 11. 체크리스트

프로비저닝 전 확인사항:
- [ ] AWS 프로필 설정 완료
- [ ] 키 페어 존재 확인
- [ ] Terraform 버전 확인 (>= 1.0)
- [ ] terraform.tfvars 파일 검토
- [ ] ALB용 ACM 인증서 생성 (us-west-2 리전)
- [ ] CloudFront용 ACM 인증서 생성 (us-east-1 리전, 중요!)
- [ ] Route53 레코드 설정 (커스텀 도메인용)
- [ ] VPN 설정 정보 확인 (Customer Gateway IP 주소)

프로비저닝 후 확인사항:
- [ ] 모든 리소스 정상 생성 확인
- [ ] EC2 인스턴스 접속 테스트
- [ ] ALB 헬스 체크 정상 동작 확인
- [ ] SSM 접속 테스트
- [ ] VPN 연결 상태 확인 (VPN Connection이 available 상태인지)
- [ ] VPN 터널 정보 확인 (Terraform outputs)
- [ ] Fortigate에서 VPN 터널 설정 완료
- [ ] 사무실 네트워크(10.15.0.0/16)와 통신 테스트
- [ ] S3 버킷 접근 테스트 (EC2에서)
- [ ] CloudFront 배포 상태 확인
- [ ] CloudFront URL로 이미지 접근 테스트
- [ ] 태그 정확성 확인

---

## 12. 참고 자료

- [Terraform AWS Provider 문서](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS RAM 공유 가이드](https://docs.aws.amazon.com/ram/)
- [Amazon Linux 2023 문서](https://docs.aws.amazon.com/linux/al2023/)

