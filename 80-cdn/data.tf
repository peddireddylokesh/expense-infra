data "aws_cloudfront_cache_policy" "noCache" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "cacheEnable" {
  name = "Managed-CachingOptimized"
}

data "aws_ssm_parameter" "cdn_acm_cert" {
  name = "/expense/dev/cdn_acm_cert_arn"
}
