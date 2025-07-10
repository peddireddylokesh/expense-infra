variable "project_name" {
  default = "expense"
}

variable "environment" {
  default = "dev"
}

variable "common_tags" {
  default = {
    Project     = "expense"
    Environment = "dev"
    Terraform   = "true"
  }
}

variable "domain_name" {
  default = "lokeshportfo.site"
}

variable "zone_id" {
  default = "Z05980581AEP4E42A8ADN"
}
