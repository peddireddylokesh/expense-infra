locals {
  # StringList to List
  public_subnet_ids = split(",", data.aws_ssm_parameter.public_subnet_ids.value)
  alb_ingress_sg_id = data.aws_ssm_parameter.alb_ingress_sg_id.value
  resource_name = "${var.project_name}-${var.environment}-frontend"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  https_certificate_arn = data.aws_acm_certificate.https_certificate_arn.arn
}
