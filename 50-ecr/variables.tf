variable "project_name" {
    default = "expense"
}

variable "environment" {
    default = "dev"
}

variable "common_tags" {
    default = {
        Project = "expense"
        Environment = "dev"
        Terraform = "true"
    }
}

variable "zone_id" {
    default = "Z00188163RC0DY3NOAH3R"
}

variable "domain_name" {
    default = "lokeshportfo.site"
}