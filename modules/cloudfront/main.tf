# ============================================================================
# CloudFront 모듈 - CDN (Content Delivery Network)
# ============================================================================
# 전 세계 사용자에게 빠른 콘텐츠 제공을 위한 CloudFront 배포
# S3 버킷의 정적 웹 콘텐츠를 전 세계 엣지 로케이션에 캐시하여 제공

# ============================================================================
# Origin Access Control (OAC) - Origin 접근 제어
# ============================================================================
# S3 버킷에 대한 접근을 제어하는 최신 방식 (OAI의 후속)
# CloudFront만 S3 버킷에 접근할 수 있도록 설정
# 
# 참고: OAC는 OAI(Origin Access Identity)의 후속 기술로,
# 더 유연하고 강력한 보안 기능을 제공합니다.
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.distribution_name}-oac"  # OAC 이름
  description                       = "OAC for ${var.distribution_name}"  # 설명
  origin_access_control_origin_type = "s3"  # S3 버킷용 OAC
  signing_behavior                  = "always"  # 항상 서명 요구
  signing_protocol                  = "sigv4"  # AWS Signature Version 4 사용
}

# ============================================================================
# CloudFront Distribution (CloudFront 배포)
# ============================================================================
# 전 세계 엣지 로케이션에 콘텐츠를 배포하는 메인 리소스
# 사용자 요청을 가장 가까운 엣지 로케이션에서 처리하여 지연 시간 최소화
resource "aws_cloudfront_distribution" "main" {
  # ==========================================================================
  # Origin 설정 (원본 서버)
  # ==========================================================================
  # CloudFront가 콘텐츠를 가져올 원본 서버 설정
  # S3 버킷을 Origin으로 사용하며 OAC를 통해 접근
  origin {
    domain_name              = var.s3_bucket_regional_domain_name  # S3 버킷 리전 도메인
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id  # OAC ID
    origin_id                = var.s3_bucket_id  # Origin 식별자 (고유해야 함)

    # 주의: OAC를 사용할 때는 s3_origin_config를 사용하지 않음
    # OAC와 OAI는 동시에 사용할 수 없음
  }

  # ==========================================================================
  # 기본 설정
  # ==========================================================================
  enabled             = true  # 배포 활성화
  is_ipv6_enabled     = true  # IPv6 지원 활성화
  comment             = var.distribution_name  # 배포 설명
  default_root_object = "index.html"  # 루트 경로(/) 요청 시 반환할 기본 파일

  # ==========================================================================
  # 커스텀 도메인 설정
  # ==========================================================================
  # CloudFront 기본 도메인 대신 사용자 정의 도메인 사용
  # SSL 인증서와 Route53 레코드가 필요함
  aliases = [var.custom_domain]  # 커스텀 도메인 (예: infrakr-test-cdn.cocone.co.kr)

  # ==========================================================================
  # Default Cache Behavior (기본 캐시 동작)
  # ==========================================================================
  # 모든 요청에 적용되는 기본 캐싱 규칙
  # 
  # 참고: forwarded_values는 레거시 설정입니다.
  # 최신 방식은 cache_policy_id와 origin_request_policy_id를 사용하는 것이지만,
  # 현재 설정도 정상 작동합니다.
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]  # 허용된 HTTP 메서드
    cached_methods   = ["GET", "HEAD"]  # 캐시할 HTTP 메서드 (GET, HEAD만 캐시)
    target_origin_id = var.s3_bucket_id  # 타겟 Origin ID

    # 레거시 캐시 설정 (최신 방식: cache_policy_id 사용 권장)
    forwarded_values {
      query_string = false  # 쿼리 문자열을 Origin으로 전달하지 않음
      cookies {
        forward = "none"  # 쿠키를 Origin으로 전달하지 않음
      }
    }

    viewer_protocol_policy = "redirect-to-https"  # HTTP 요청을 HTTPS로 리다이렉트
    min_ttl                = 0  # 최소 캐시 시간 (초) - 0 = 즉시 만료 가능
    default_ttl            = 3600  # 기본 캐시 시간 (초) - 1시간
    max_ttl                = 86400  # 최대 캐시 시간 (초) - 24시간
    compress               = true  # Gzip 압축 활성화 (대역폭 절감)
  }

  # ==========================================================================
  # SSL/TLS 인증서 설정
  # ==========================================================================
  # 커스텀 도메인에 대한 SSL 인증서 설정
  # 
  # 중요: CloudFront는 us-east-1 리전의 ACM 인증서만 사용 가능
  # 다른 리전의 인증서는 사용할 수 없음
  viewer_certificate {
    acm_certificate_arn      = var.ssl_certificate_arn  # ACM 인증서 ARN (us-east-1)
    ssl_support_method       = "sni-only"  # SNI(Server Name Indication) 사용
    minimum_protocol_version = "TLSv1.2_2021"  # 최소 TLS 버전 (보안 강화)
  }

  # ==========================================================================
  # 지리적 제한 설정
  # ==========================================================================
  # 특정 국가/지역의 접근을 제한할 수 있음
  # 현재는 제한 없음 (모든 국가에서 접근 가능)
  restrictions {
    geo_restriction {
      restriction_type = "none"  # 제한 없음 (모든 국가 허용)
    }
  }

  # ==========================================================================
  # 가격 클래스 설정
  # ==========================================================================
  # CloudFront 엣지 로케이션 선택에 따른 가격 차이
  # PriceClass_All: 모든 엣지 로케이션 사용 (가장 빠름, 가장 비쌈)
  # PriceClass_200: 북미, 유럽, 아시아 주요 지역만 사용
  # PriceClass_100: 북미, 유럽만 사용 (가장 저렴)
  price_class = "PriceClass_All"  # 모든 엣지 로케이션 사용

  tags = merge(var.tags, {
    Name = var.distribution_name
  })
}
