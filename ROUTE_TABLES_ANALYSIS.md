# Route Tables 분석 및 설계

## 현재 상태

### Public Route Table (1개)
```
Route Table: infrakr-test-public-rt
├── 0.0.0.0/0 → Internet Gateway (IGW)
└── (로컬 라우트는 자동으로 추가됨: 10.160.0.0/16 → local)
```

### Private Route Tables (2개)
```
Route Table: infrakr-test-private-rt-a (us-west-2a)
├── 0.0.0.0/0 → NAT Gateway (us-west-2a)
└── (로컬 라우트는 자동으로 추가됨: 10.160.0.0/16 → local)

Route Table: infrakr-test-private-rt-c (us-west-2c)
├── 0.0.0.0/0 → NAT Gateway (us-west-2c)
└── (로컬 라우트는 자동으로 추가됨: 10.160.0.0/16 → local)
```

---

## 추가해야 할 라우팅 규칙

### 1. 사무실 대역 (10.15.0.0/16) - VPN Gateway를 통한 접근
- **목적지**: 10.15.0.0/16
- **타겟**: VPN Gateway (VGW)
- **적용 대상**: Public Route Table, Private Route Tables (모두)
- **목적**: 사무실 네트워크에서 InfraKR VPC로 접근

### 2. 베이스 계정 VPC (10.71.0.0/16) - VPC Peering을 통한 접근
- **목적지**: 10.71.0.0/16
- **타겟**: VPC Peering Connection
- **적용 대상**: Public Route Table, Private Route Tables (모두)
- **목적**: 베이스 계정(cocone) VPC와 통신

---

## 최종 Route Tables 구조 (목표)

### Public Route Table
```
Route Table: infrakr-test-public-rt
├── 10.160.0.0/16 → local (자동)
├── 0.0.0.0/0 → Internet Gateway
├── 10.15.0.0/16 → VPN Gateway (추가 필요)
└── 10.71.0.0/16 → VPC Peering Connection (추가 필요)
```

### Private Route Tables
```
Route Table: infrakr-test-private-rt-a
├── 10.160.0.0/16 → local (자동)
├── 0.0.0.0/0 → NAT Gateway (us-west-2a)
├── 10.15.0.0/16 → VPN Gateway (추가 필요)
└── 10.71.0.0/16 → VPC Peering Connection (추가 필요)

Route Table: infrakr-test-private-rt-c
├── 10.160.0.0/16 → local (자동)
├── 0.0.0.0/0 → NAT Gateway (us-west-2c)
├── 10.15.0.0/16 → VPN Gateway (추가 필요)
└── 10.71.0.0/16 → VPC Peering Connection (추가 필요)
```

---

## 구현 방법 결정

### VPC Peering 및 VPN 연결 관리 방식

**결정: VPC Peering과 VPN 연결은 AWS 콘솔에서 수동으로 관리**

**이유:**
- 베이스 계정의 VPC가 현재 Terraform으로 관리되지 않음
- 크로스 계정/크로스 리전 Peering의 경우 양쪽 계정에서 작업이 필요하여 Terraform으로 자동화하기 복잡
- VPN 연결의 경우 Fortigate 장비에서 수동 설정이 필요하므로 AWS 측만 Terraform으로 관리하는 것의 이점이 제한적
- 추후 베이스 계정에서 네트워크 관련 부분을 Terraform으로 관리하게 되면 그때 통합 관리

**현재 Terraform 관리 범위:**
- VPC, 서브넷, IGW, NAT Gateway, Route Tables (기본 네트워크 인프라)
- 기본 라우트: 0.0.0.0/0 → IGW (Public), 0.0.0.0/0 → NAT Gateway (Private)

**콘솔에서 수동 관리:**
- VPC Peering Connection 생성/수락
- Route Tables에 추가 라우트 (10.71.0.0/16 → Peering, 10.15.0.0/16 → VPN Gateway)
- VPN Gateway, Customer Gateway, VPN Connection 설정

---

## 필요한 리소스 및 정보

### VPN Gateway 관련
- **현재 상태**: InfraKR 계정 오레곤 리전에 고객 게이트웨이가 없음
- **필요한 작업**:
  1. **AWS 측 (Terraform으로 가능)**:
     - VPN Gateway 생성 (또는 기존 VGW 사용)
     - Customer Gateway 생성 (Fortigate의 공인 IP 필요)
     - VPN Connection 생성 (Site-to-Site VPN)
     - VGW Attachment (VPC에 VPN Gateway 연결)
     - Route Tables에 10.15.0.0/16 라우트 추가
  2. **Fortigate 측 (수동 작업 필요)**:
     - VPN 터널 설정
     - 라우팅 설정
     - 보안 정책 설정
     - **Terraform으로는 불가능** - Fortigate 장비에서 직접 설정 필요

### VPC Peering 관련
- **Peer VPC ID**: vpc-a9dc35c0 (베이스 계정 cocone, 서울 리전)
- **Peer Region**: ap-northeast-2 (서울)
- **VPC CIDR**: 10.71.0.0/16
- **Terraform으로 가능**:
  - VPC Peering Connection 요청 생성
  - Route Tables에 10.71.0.0/16 라우트 추가
  - **크로스 계정/크로스 리전의 경우**:
    - InfraKR 계정에서 Peering 요청 생성
    - 베이스 계정(cocone)에서 Peering 수락 (Terraform 또는 수동)
    - 양쪽 계정 모두 라우트 추가 필요

---

## 고려사항

### 1. VPN Gateway 및 VPN 연결
- **현재 상태**: InfraKR 계정 오레곤 리전에 고객 게이트웨이 없음
- **구현 방법**:
  - **AWS 측**: Terraform으로 VPN Gateway, Customer Gateway, VPN Connection 생성 가능
  - **Fortigate 측**: 수동 설정 필요 (VPN 터널, 라우팅, 보안 정책)
- **필요한 정보**:
  - Fortigate의 공인 IP 주소
  - VPN 터널 설정 정보 (BGP ASN, Pre-shared Key 등)
- **비용**: VPN Gateway는 시간당 과금 (약 $0.05/시간)

### 2. VPC Peering
- **Peer VPC ID**: vpc-a9dc35c0 (확인됨)
- **크로스 리전 Peering**: 
  - InfraKR (us-west-2) ↔ 베이스 계정 (ap-northeast-2)
  - 양쪽 계정에서 설정 필요
- **구현 방법**:
  - **InfraKR 계정**: Terraform으로 Peering 요청 생성 + 라우트 추가
  - **베이스 계정**: Peering 수락 + 라우트 추가 (Terraform 또는 수동)
- **양방향 라우팅**: 
  - InfraKR → 베이스 계정 (10.71.0.0/16): InfraKR에서 설정
  - 베이스 계정 → InfraKR (10.160.0.0/16): 베이스 계정에서 설정 필요

### 3. 라우팅 우선순위
- 더 구체적인 CIDR (10.15.0.0/16, 10.71.0.0/16)이 0.0.0.0/0보다 우선
- AWS는 가장 구체적인 라우트를 선택하므로 문제없음

### 4. 보안
- VPC Peering은 보안 그룹 규칙으로 추가 제어 가능
- VPN Gateway는 VPN 연결이 설정되어 있어야 작동

---

## 현재 구현 방식

**VPC Peering 및 VPN 연결은 AWS 콘솔에서 수동으로 관리합니다.**

**Terraform으로 관리되는 리소스:**
- VPC, 서브넷, IGW, NAT Gateway
- 기본 Route Tables (0.0.0.0/0 → IGW/NAT Gateway)

**콘솔에서 수동으로 추가해야 할 라우트:**
- Public Route Table: 10.71.0.0/16 → VPC Peering Connection
- Private Route Tables: 10.71.0.0/16 → VPC Peering Connection
- Public Route Table: 10.15.0.0/16 → VPN Gateway (VGW)
- Private Route Tables: 10.15.0.0/16 → VPN Gateway (VGW)

**추후 개선 방향:**
- 베이스 계정에서 네트워크 관련 부분을 Terraform으로 관리하게 되면, 베이스 계정의 networking 모듈에 InfraKR Peering을 추가하여 통합 관리 가능

---

## 수동 작업 가이드

### VPC Peering 설정 (콘솔에서 수동 작업)

**1. VPC Peering Connection 생성**
- AWS 콘솔 → VPC → Peering Connections → Create Peering Connection
- Requester VPC: InfraKR VPC (10.160.0.0/16)
- Accepter VPC: 베이스 계정 VPC (vpc-a9dc35c0, 10.71.0.0/16)
- Accepter Account: 942224853988
- Accepter Region: ap-northeast-2

**2. 베이스 계정에서 Peering 수락**
- 베이스 계정 콘솔에서 Peering Connection 수락

**3. Route Tables에 라우트 추가**

**InfraKR 계정 (콘솔에서 수동 추가):**
- Public Route Table: 10.71.0.0/16 → VPC Peering Connection
- Private Route Tables: 10.71.0.0/16 → VPC Peering Connection

**베이스 계정 (콘솔에서 수동 추가):**
- Public Route Table: 10.160.0.0/16 → VPC Peering Connection
- Private Route Tables: 10.160.0.0/16 → VPC Peering Connection

### VPN 연결 설정 (콘솔에서 수동 작업)

**1. AWS 측 리소스 생성 (콘솔)**
- VPN Gateway 생성 및 VPC에 연결
- Customer Gateway 생성 (Fortigate 공인 IP)
- VPN Connection 생성 (Site-to-Site VPN)

**2. Route Tables에 라우트 추가 (콘솔)**
- Public Route Table: 10.15.0.0/16 → VPN Gateway
- Private Route Tables: 10.15.0.0/16 → VPN Gateway

**3. Fortigate 설정 (수동 작업)**
- VPN 터널 설정
- 라우팅 설정
- 보안 정책 설정

---

## 추후 개선 방향

베이스 계정에서 네트워크 관련 부분을 Terraform으로 관리하게 되면:
- 베이스 계정의 `networking` 모듈에 InfraKR Peering 추가
- 베이스 계정에서 Peering 요청 생성 및 라우트 관리
- InfraKR 계정에서는 Peering 수락만 처리
- 모든 네트워크 연결을 베이스 계정에서 중앙 관리

