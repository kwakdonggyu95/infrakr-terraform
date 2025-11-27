# InfraKR Test Environment - 오레곤 리전

이 Terraform 코드는 InfraKR 계정의 오레곤 리전(us-west-2)에 테스트 환경 인프라를 구축합니다.

## 📋 목차

- [인프라 구성](#인프라-구성)
- [리소스 생성 순서](#리소스-생성-순서)
- [생성되는 리소스 목록](#생성되는-리소스-목록)
- [사용 방법](#사용-방법)
- [주요 설정값](#주요-설정값)

---

## 인프라 구성

### 네트워크
- **VPC**: 10.160.0.0/16 (InfraKR 계정에서 직접 생성)
- **Public Subnets**: 
  - us-west-2a: 10.160.1.0/24
  - us-west-2c: 10.160.2.0/24
- **Private Subnets**: 
  - us-west-2a: 10.160.10.0/24
  - us-west-2c: 10.160.20.0/24
- **Internet Gateway**: VPC와 인터넷 연결
- **NAT Gateways**: 2개 (각 Public Subnet에 1개씩)
- **Route Tables**: Public 1개, Private 2개

### 컴퓨팅
- **EC2 인스턴스**: 4개
  - AP 서버: 2개 (infrakr-test-ap-0, infrakr-test-ap-1)
  - Alpha 서버: 2개 (infrakr-test-alpha-0, infrakr-test-alpha-1)
  - 인스턴스 타입: t3.micro (2 vCPU, 1GB RAM)
  - 배치: Private Subnets (고가용성을 위해 2개 AZ에 분산)

### 로드 밸런싱
- **Application Load Balancer**: 2개
  - AP ALB: `infrakr-test-ap-alb`
  - Alpha ALB: `infrakr-test-alpha-alb`
- **Target Groups**: 2개
  - AP TG: `infrakr-test-ap-tg` (AP 서버 2개 타겟)
  - Alpha TG: `infrakr-test-alpha-tg` (Alpha 서버 2개 타겟)
- **Listeners**: 
  - HTTP (포트 80)
  - HTTPS (포트 443, SNI를 통한 다중 인증서 지원)
    - *.cocone.co.kr
    - *.cocone-m.com

### 보안
- **Security Groups**: 2개
  - LinuxDefault: EC2 인스턴스용 (다양한 서비스 포트 허용)
  - WebAll: ALB용 (HTTP/HTTPS)
- **IAM Roles**: 2개
  - infrakr-test-production-ec2-role (AP 서버용)
    - AmazonSSMManagedInstanceCore (SSM 접속용)
    - S3 접근 정책 (S3 버킷 읽기/쓰기)
  - infrakr-test-alpha-ec2-role (Alpha 서버용)
    - AmazonSSMManagedInstanceCore (SSM 접속용)
    - S3 접근 정책 (S3 버킷 읽기/쓰기)
- **IAM Instance Profiles**: 2개 (SSM Session Manager 접속용)

### 스토리지 및 CDN
- **S3 Bucket**: 정적 콘텐츠 저장 (이미지 파일 등)
  - 버킷 이름: `infrakr-test-s3` (또는 지정된 이름)
  - 퍼블릭 접근 차단: 활성화 (CloudFront OAC를 통해서만 접근)
  - CloudFront Origin Access Control (OAC) 사용
- **CloudFront Distribution**: CDN 배포
  - Origin: S3 버킷
  - 커스텀 도메인: `infrakr-test.cocone.co.kr` (또는 지정된 도메인)
  - SSL 인증서: us-east-1 리전의 *.cocone.co.kr 인증서
  - IPv6 지원: 활성화

---

## 리소스 생성 순서

Terraform은 자동으로 의존성을 해결하지만, 개념적인 생성 순서는 다음과 같습니다:

### 1단계: 네트워크 인프라
```
VPC 생성
  ↓
Internet Gateway 생성 및 VPC 연결
  ↓
Public Subnets 생성 (2개)
  ↓
Private Subnets 생성 (2개)
  ↓
Elastic IPs 할당 (NAT Gateway용, 2개)
  ↓
NAT Gateways 생성 (Public Subnets에 배치, 2개)
  ↓
Route Tables 생성 및 라우팅 규칙 설정
  ↓
Route Table Associations (서브넷과 라우팅 테이블 연결)
```

### 2단계: 보안 설정
```
Security Groups 생성
  - LinuxDefault
  - WebAll
```

### 3단계: IAM 리소스
```
IAM Policy Document 생성 (EC2 Assume Role)
  ↓
IAM Role 생성 (2개)
  - infrakr-test-production-ec2-role
  - infrakr-test-alpha-ec2-role
  ↓
IAM Instance Profile 생성 (2개)
```

### 4단계: 컴퓨팅 리소스
```
EC2 인스턴스 생성 (4개)
  - infrakr-test-ap-0 (Private Subnet, AZ-a)
  - infrakr-test-ap-1 (Private Subnet, AZ-c)
  - infrakr-test-alpha-0 (Private Subnet, AZ-a)
  - infrakr-test-alpha-1 (Private Subnet, AZ-c)
```

### 5단계: 로드 밸런싱
```
Application Load Balancer 생성 (2개)
  - infrakr-test-ap-alb
  - infrakr-test-alpha-alb
  ↓
Target Group 생성 (2개)
  - infrakr-test-ap-tg
  - infrakr-test-alpha-tg
  ↓
Target Group Attachments (EC2 인스턴스 연결)
  ↓
ALB Listeners 생성
  - HTTP Listener (포트 80)
  - HTTPS Listener (포트 443, 다중 인증서)
```

### 6단계: 스토리지 및 CDN
```
S3 Bucket 생성
  ↓
CloudFront Origin Access Control (OAC) 생성
  ↓
CloudFront Distribution 생성 (S3를 Origin으로)
  ↓
S3 Bucket Policy 업데이트 (CloudFront ARN 사용)
```

---

## 생성되는 리소스 목록

### 네트워크 리소스 (총 12개)
- ✅ VPC: 1개
- ✅ Internet Gateway: 1개
- ✅ Public Subnets: 2개
- ✅ Private Subnets: 2개
- ✅ Elastic IPs: 2개
- ✅ NAT Gateways: 2개
- ✅ Route Tables: 3개 (Public 1개, Private 2개)
- ✅ Route Table Associations: 4개

### 보안 리소스 (총 2개)
- ✅ Security Groups: 2개
  - LinuxDefault
  - WebAll

### IAM 리소스 (총 4개)
- ✅ IAM Roles: 2개
  - infrakr-test-production-ec2-role
  - infrakr-test-alpha-ec2-role
- ✅ IAM Instance Profiles: 2개

### 컴퓨팅 리소스 (총 4개)
- ✅ EC2 Instances: 4개
  - infrakr-test-ap-0 (t3.micro)
  - infrakr-test-ap-1 (t3.micro)
  - infrakr-test-alpha-0 (t3.micro)
  - infrakr-test-alpha-1 (t3.micro)
- ✅ EBS Volumes: 4개 (각 인스턴스당 20GB GP3, 암호화)

### 로드 밸런싱 리소스 (총 10개)
- ✅ Application Load Balancers: 2개
- ✅ Target Groups: 2개
- ✅ Target Group Attachments: 4개 (각 TG당 2개 인스턴스)
- ✅ ALB Listeners: 4개 (각 ALB당 HTTP 1개, HTTPS 1개)

### 스토리지 및 CDN 리소스 (총 6개)
- ✅ S3 Bucket: 1개
- ✅ S3 Bucket Versioning: 1개
- ✅ S3 Bucket Public Access Block: 1개
- ✅ S3 Bucket Policy: 1개
- ✅ CloudFront Origin Access Control (OAC): 1개
- ✅ CloudFront Distribution: 1개

### IAM 정책 (추가)
- ✅ IAM Policies: 2개 (각 Role당 S3 접근 정책 1개)

**총 예상 리소스 수: 약 40개**

---

## 사용 방법

### 사전 준비사항

1. **AWS 프로필 설정 확인**
   ```bash
   aws configure list-profiles
   # kr-Infra 프로필이 존재하는지 확인
   ```

2. **AWS 자격 증명 확인**
   ```bash
   aws sts get-caller-identity --profile kr-Infra
   # InfraKR 계정 정보가 나오는지 확인
   ```

3. **EC2 키 페어 확인**
   ```bash
   aws ec2 describe-key-pairs --profile kr-Infra --region us-west-2
   # infra-nopass 키 페어가 존재하는지 확인
   ```

4. **ACM 인증서 확인** (선택사항, HTTPS 사용 시)
   
   **ALB용 인증서 (us-west-2 리전):**
   - us-west-2 리전에 *.cocone.co.kr, *.cocone-m.com 인증서가 생성되어 있어야 함
   - `terraform.tfvars`의 `certificate_arns`에 인증서 ARN이 설정되어 있어야 함
   
   **CloudFront용 인증서 (us-east-1 리전):**
   - **중요**: CloudFront는 us-east-1 리전의 인증서만 사용 가능
   - us-east-1 리전에 *.cocone.co.kr 인증서가 생성되어 있어야 함
   - `terraform.tfvars`의 `ssl_certificate_arn`에 인증서 ARN이 설정되어 있어야 함

### Terraform 실행

1. **디렉토리 이동**
   ```bash
   cd /Users/kwak_donggyu/terraform/infrakr
   ```

2. **Terraform 초기화**
   ```bash
   terraform init
   ```

3. **실행 계획 확인**
   ```bash
   terraform plan -var-file="environments/oregon/terraform.tfvars"
   ```
   
   **확인 사항:**
   - 생성될 리소스 목록 확인
   - 예상 비용 확인 (특히 EC2, ALB, NAT Gateway)
   - VPC CIDR가 다른 VPC와 겹치지 않는지 확인

4. **프로비저닝 실행**
   ```bash
   terraform apply -var-file="environments/oregon/terraform.tfvars"
   ```
   
   **주의사항:**
   - `yes` 입력 전에 생성될 리소스를 다시 한 번 확인
   - NAT Gateway는 시간당 과금되므로 주의

5. **결과 확인**
   ```bash
   # 생성된 리소스 확인
   terraform show
   
   # Output 값 확인
   terraform output
   ```

### 프로비저닝 후 검증

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

4. **S3 및 CloudFront 확인**
   ```bash
   # S3 버킷 확인
   aws s3 ls --profile kr-Infra --region us-west-2
   
   # CloudFront 배포 확인
   aws cloudfront list-distributions \
     --profile kr-Infra \
     --query 'DistributionList.Items[?Comment==`infrakr-test-cdn`]' \
     --output table
   ```

5. **EC2에서 S3 업로드 테스트**
   ```bash
   # EC2 인스턴스 접속 후
   aws s3 cp test-image.jpg s3://infrakr-test-s3/images/test-image.jpg --content-type image/jpeg
   
   # CloudFront URL로 접근 확인
   # https://infrakr-test.cocone.co.kr/images/test-image.jpg
   ```
   
   자세한 내용은 `S3_UPLOAD_GUIDE.md` 파일을 참고하세요.

---

## 주요 설정값

### AWS 설정
- **리전**: us-west-2 (오레곤)
- **프로필**: kr-Infra
- **계정**: InfraKR (611680202326)

### 네트워크 CIDR
- **VPC**: 10.160.0.0/16
- **Public Subnets**: 
  - 10.160.1.0/24 (us-west-2a)
  - 10.160.2.0/24 (us-west-2c)
- **Private Subnets**:
  - 10.160.10.0/24 (us-west-2a)
  - 10.160.20.0/24 (us-west-2c)

### EC2 설정
- **AMI**: Amazon Linux 2023 (동적 조회)
- **키 페어**: infra-nopass
- **인스턴스 타입**: t3.micro (2 vCPU, 1GB RAM)
- **볼륨 타입**: GP3
- **볼륨 크기**: 20GB
- **볼륨 암호화**: 활성화

### 공통 태그
```hcl
Project        = "infrakr-test"
ManagedBy      = "terraform"
Service        = "test"
ChorusCost_Tag1 = "infra-kr"
```

### 인스턴스별 태그
- **AP 서버**: `Env = "production"`
- **Alpha 서버**: `Env = "alpha"`

---

## 비용 예상

### 시간당 비용 (대략)
- **EC2 인스턴스**: t3.micro × 4개 ≈ $0.0084/시간
- **ALB**: 2개 ≈ $0.016/시간
- **NAT Gateway**: 2개 ≈ $0.09/시간
- **EBS 볼륨**: GP3 20GB × 4개 ≈ $0.0016/시간
- **S3 버킷**: 스토리지 비용 (GB당) + 요청 비용 (사용량에 따라)
- **CloudFront**: 데이터 전송 비용 (GB당) + 요청 비용 (사용량에 따라)
- **총 예상 (기본 인프라)**: 약 $0.116/시간 (약 $84/월)
- **참고**: S3 및 CloudFront 비용은 실제 사용량에 따라 추가 발생

### 참고사항
- NAT Gateway는 시간당 과금되므로 사용하지 않을 때는 제거 권장
- 데이터 전송 비용은 별도로 발생
- 실제 비용은 사용량에 따라 달라질 수 있음

---

## 주요 변경사항

- ✅ **리전**: 오레곤 (us-west-2)
- ✅ **VPC 생성 방식**: cocone 계정 공유 → InfraKR 계정 직접 생성
- ✅ **네이밍**: infrakr-test 접두사 사용
- ✅ **OS**: Amazon Linux 2023 사용
- ✅ **인스턴스**: AP 서버 2개, Alpha 서버 2개 (총 4개)
- ✅ **로드 밸런서**: AP/Alpha 분리 (각각 ALB 1개)
- ✅ **인증서**: 다중 인증서 지원 (SNI)
- ✅ **S3 버킷**: 정적 콘텐츠 저장소 추가
- ✅ **CloudFront**: CDN 배포 추가 (S3와 연동)
- ✅ **IAM Role**: S3 접근 권한 추가

---

## 문제 해결

### VPC 생성 실패
- VPC CIDR가 다른 VPC와 겹치지 않는지 확인
- IAM 권한이 충분한지 확인

### EC2 인스턴스 생성 실패
- 서브넷에 충분한 IP 주소가 있는지 확인
- 키 페어가 존재하는지 확인
- IAM Role 권한이 충분한지 확인

### ALB 생성 실패
- 퍼블릭 서브넷이 최소 2개 이상인지 확인
- 보안 그룹 규칙이 올바른지 확인
- 인증서 ARN이 올바른지 확인 (HTTPS 리스너)

### CloudFront 생성 실패
- S3 버킷이 올바르게 생성되었는지 확인
- us-east-1 리전의 ACM 인증서가 존재하는지 확인 (CloudFront는 us-east-1만 지원)
- 커스텀 도메인의 Route53 레코드가 올바르게 설정되었는지 확인

### S3 접근 오류
- EC2 인스턴스의 IAM Role에 S3 접근 정책이 연결되어 있는지 확인
- S3 버킷 정책이 CloudFront OAC를 허용하는지 확인
- CloudFront Distribution이 활성화되어 있는지 확인

---

## 참고 자료

- [Terraform AWS Provider 문서](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Amazon Linux 2023 문서](https://docs.aws.amazon.com/linux/al2023/)
- [AWS ALB 다중 인증서 (SNI)](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/listener-authenticate-users.html)
- [S3 업로드 가이드](S3_UPLOAD_GUIDE.md) - EC2에서 S3로 이미지 업로드 방법
- [AWS CloudFront 문서](https://docs.aws.amazon.com/cloudfront/)
- [AWS S3 문서](https://docs.aws.amazon.com/s3/)
