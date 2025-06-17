resource "aws_ssm_parameter" "https_certificate_arn" {
  name      = "/${var.project_name}/${var.environment}/https_certificate_arn"
  type      = "String"
  value     = data.aws_acm_certificate.https_cert.arn
  overwrite = true
}
