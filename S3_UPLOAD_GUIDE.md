# EC2에서 S3로 이미지 업로드 가이드

## 개요
EC2 인스턴스에서 S3 버킷으로 이미지 파일을 업로드하고, CloudFront를 통해 접근하는 방법을 안내합니다.

## 사전 준비
1. Terraform으로 인프라 배포 완료
2. EC2 인스턴스에 IAM Role이 연결되어 있어야 함 (S3 접근 권한 포함)
3. AWS CLI가 EC2 인스턴스에 설치되어 있어야 함

## 단계별 가이드

### 1. EC2 인스턴스 접속
SSM Session Manager를 사용하여 EC2 인스턴스에 접속합니다.

```bash
# AWS CLI로 인스턴스 ID 확인
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=infrakr-test-ap-0" \
  --query "Reservations[*].Instances[*].[InstanceId]" \
  --output text

# SSM Session Manager로 접속
aws ssm start-session --target <INSTANCE_ID>
```

### 2. 이미지 파일 준비
EC2 인스턴스에 이미지 파일을 업로드합니다.

**방법 1: 로컬에서 SCP로 전송 (권장)**
```bash
# 로컬 터미널에서 실행
# EC2 인스턴스의 호스트명을 사용하여 전송
scp ~/Downloads/kwakdonggyu.jpg infra@infrakr-test-ap-0.cocone:/home/infra/

# 또는 IP 주소를 사용하는 경우
scp ~/Downloads/kwakdonggyu.jpg infra@<EC2_PUBLIC_IP>:/home/infra/
```

**EC2 인스턴스에서 파일 확인 및 이동**
```bash
# EC2 인스턴스에 접속한 후 실행
# 업로드된 파일 확인
ll /home/infra/

# 필요시 root 디렉토리로 이동 (선택사항)
mv /home/infra/kwakdonggyu.jpg /root/

# 파일 확인
ll /root/kwakdonggyu.jpg
```

**방법 2: EC2에서 직접 다운로드**
```bash
# EC2 인스턴스 내에서 실행
curl -o image.jpg https://example.com/image.jpg
# 또는 wget 사용
wget https://example.com/image.jpg
```

**방법 3: 간단한 테스트 이미지 생성**
```bash
# EC2 인스턴스 내에서 실행 (ImageMagick이 설치되어 있는 경우)
convert -size 800x600 xc:blue -pointsize 72 -fill white -gravity center \
  -annotate +0+0 "Test Image" test-image.jpg
```

### 3. S3 버킷 이름 확인
Terraform output에서 S3 버킷 이름을 확인합니다.

```bash
# Terraform 디렉토리에서 실행
terraform output

# 또는 직접 확인
aws s3 ls | grep infrakr-test
```

### 4. S3로 이미지 업로드
AWS CLI를 사용하여 이미지를 S3 버킷의 `images/` 디렉토리에 업로드합니다.

**기본 업로드 명령어**
```bash
# EC2 인스턴스에서 실행
# Content-Type을 명시하여 업로드 (권장)
aws s3 cp /root/kwakdonggyu.jpg s3://infrakr-test-s3/images/kwakdonggyu.jpg \
  --content-type image/jpeg

# 또는 /home/infra/ 경로에 있는 경우
aws s3 cp /home/infra/kwakdonggyu.jpg s3://infrakr-test-s3/images/kwakdonggyu.jpg \
  --content-type image/jpeg
```

**업로드 확인**
```bash
# S3 버킷의 images 디렉토리 내용 확인
aws s3 ls s3://infrakr-test-s3/images/

# 특정 파일 확인
aws s3 ls s3://infrakr-test-s3/images/kwakdonggyu.jpg
```

**여러 이미지 업로드**
```bash
# 디렉토리 전체 업로드
aws s3 cp /path/to/images/ s3://infrakr-test-s3/images/ --recursive \
  --exclude "*" --include "*.jpg" --include "*.png"
```

### 5. CloudFront를 통해 접근
업로드한 이미지를 CloudFront URL로 접근합니다.

```
https://infrakr-test-cdn.cocone.co.kr/images/kwakdonggyu.jpg
```

**실제 예시:**
- 업로드한 파일: `kwakdonggyu.jpg`
- S3 경로: `s3://infrakr-test-s3/images/kwakdonggyu.jpg`
- CloudFront URL: `https://infrakr-test-cdn.cocone.co.kr/images/kwakdonggyu.jpg`

**참고**: CloudFront 캐시 때문에 업로드 직후 바로 보이지 않을 수 있습니다.
- 캐시 무효화가 필요하면 AWS 콘솔에서 CloudFront 캐시 무효화 수행
- 또는 업로드 후 몇 분 대기

## 이미지 타입별 Content-Type 설정

```bash
# JPEG
aws s3 cp image.jpg s3://infrakr-test-s3/images/image.jpg --content-type image/jpeg

# PNG
aws s3 cp image.png s3://infrakr-test-s3/images/image.png --content-type image/png

# GIF
aws s3 cp image.gif s3://infrakr-test-s3/images/image.gif --content-type image/gif

# WebP
aws s3 cp image.webp s3://infrakr-test-s3/images/image.webp --content-type image/webp
```

## 문제 해결

### AWS CLI가 설치되어 있지 않은 경우
```bash
# Amazon Linux 2023
sudo dnf install -y aws-cli

# 또는 최신 버전 설치
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### 권한 오류가 발생하는 경우
- EC2 인스턴스의 IAM Role에 S3 접근 권한이 있는지 확인
- Terraform으로 IAM 정책이 올바르게 생성되었는지 확인

### CloudFront에서 이미지가 보이지 않는 경우
- S3 버킷 정책이 CloudFront OAC를 허용하는지 확인
- CloudFront Distribution이 활성화되어 있는지 확인
- 캐시 무효화 수행

## 실제 사용 예시

### 전체 프로세스 요약
```bash
# 1. 로컬에서 EC2로 파일 전송
scp ~/Downloads/kwakdonggyu.jpg infra@infrakr-test-ap-0.cocone:/home/infra/

# 2. EC2 인스턴스 접속 후 파일 확인 및 이동 (선택사항)
mv /home/infra/kwakdonggyu.jpg /root/

# 3. S3로 업로드
aws s3 cp /root/kwakdonggyu.jpg s3://infrakr-test-s3/images/kwakdonggyu.jpg \
  --content-type image/jpeg

# 4. 업로드 확인
aws s3 ls s3://infrakr-test-s3/images/

# 5. CloudFront URL로 접근
# https://infrakr-test-cdn.cocone.co.kr/images/kwakdonggyu.jpg
```

## 예제 스크립트

EC2 인스턴스에서 실행할 수 있는 간단한 업로드 스크립트:

```bash
#!/bin/bash
# upload-to-s3.sh

BUCKET_NAME="infrakr-test-s3"
IMAGE_FILE="/root/kwakdonggyu.jpg"  # 또는 /home/infra/kwakdonggyu.jpg
S3_PREFIX="images"
FILENAME="kwakdonggyu.jpg"

# 이미지 파일이 있는지 확인
if [ -f "$IMAGE_FILE" ]; then
    echo "Uploading $FILENAME to S3..."
    aws s3 cp "$IMAGE_FILE" \
        "s3://$BUCKET_NAME/$S3_PREFIX/$FILENAME" \
        --content-type image/jpeg
    
    echo "Upload complete!"
    echo "Access via CloudFront: https://infrakr-test-cdn.cocone.co.kr/$S3_PREFIX/$FILENAME"
else
    echo "Image file not found: $IMAGE_FILE"
fi
```

## 참고 사항

- S3 버킷은 CloudFront OAC를 통해서만 접근 가능 (직접 접근 차단)
- 이미지는 `images/` 디렉토리에 저장하는 것을 권장
- 파일명은 영문, 숫자, 하이픈(-), 언더스코어(_)만 사용 권장
- 대용량 파일 업로드 시 `aws s3 cp` 대신 `aws s3 sync` 사용 고려

