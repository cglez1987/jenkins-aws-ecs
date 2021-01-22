module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>2.64.0"

  name = var.vpc_name

  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = var.public_subnets_cidr

  tags = {
    stage = var.vpc_name
  }
}


resource "aws_security_group" "elb_security_group" {
  name = "ELB-SG"
  vpc_id = module.vpc.default_vpc_id
  ingress {
    description = "Access from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins_master_security_group" {
  name = "Jenkins-SG"
  vpc_id = module.vpc.default_vpc_id
  ingress {
    description = "Access from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.elb_security_group.id]
  }
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
