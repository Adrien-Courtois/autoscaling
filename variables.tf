variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "ami_names" {
  type        = list(any)
  description = "tableau de nom des AMI"
}

variable "ami_owners" {
  type        = string
  description = "Owner des AMI"
}

variable "vpc_name" {
  type        = string
  description = "Nom de notre VPC"
}

variable "app_name" {
  type        = string
  description = "Nom de l'application"
}
