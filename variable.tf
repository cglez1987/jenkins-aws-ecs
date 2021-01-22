variable "aws_region" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets_cidr" {
  type = list(string)
}
