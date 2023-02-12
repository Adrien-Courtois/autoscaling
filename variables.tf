variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
}

variable "vpc_name" {
  type        = string
  description = "Nom de notre VPC"
  default     = "upjv-cloud"
}

variable "app_name" {
  type        = string
  description = "Nom de l'application"
  default     = "restaurant"
}
