terraform {
  required_version = ">=0.12.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.22"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
