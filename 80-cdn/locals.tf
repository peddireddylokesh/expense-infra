locals {
  https_certificate_arn = data.aws_ssm_parameter.cdn_acm_cert.value
}
