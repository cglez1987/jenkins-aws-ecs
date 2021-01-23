resource "aws_lb" "app_elb" {
  name               = join("", ["ALB-", var.app_name])
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.elb_security_group.id]
  subnets            = module.vpc.public_subnets
  tags = {
    "app" = var.app_name
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_elb.arn
  port              = 8080
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

resource "aws_lb_target_group" "app_target_group" {
  deregistration_delay = 30
  port                 = 8080
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = module.vpc.vpc_id

  health_check {
    path                = "/login"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 4
    timeout             = 5
  }
}

resource "aws_ecs_cluster" "jenkins_ecs_cluster" {
  name = "jenkins_ecs_cluster"
}

resource "aws_ecs_task_definition" "jenkins_task" {
  family                   = var.app_name
  task_role_arn            = aws_iam_role.jenkins_role.arn
  execution_role_arn       = aws_iam_role.jenkins_execution_role.arn
  requires_compatibilities = ["FARGATE", "EC2"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  container_definitions    = <<EOF
[
  {
    "name": "jenkins",
    "image": "jenkins/jenkins:lts",
    "portMappings": [
      {
        "containerPort": 8080
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.jenkins_log_group.id}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "jenkins"
      }
    },
    "mountPoints": [
        {
            "sourceVolume": "jenkins-home",
            "containerPath": "/var/jenkins_home"
        }
    ]
  }
]
EOF
  volume {
    name = "jenkins-home"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.jenkins_home_efs.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.jenkins_home_efs_access_point.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "jenkins_service" {
  name             = "jenkins-service"
  depends_on       = [aws_lb.app_elb]
  cluster          = aws_ecs_cluster.jenkins_ecs_cluster.id
  task_definition  = aws_ecs_task_definition.jenkins_task.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  load_balancer {
    target_group_arn = aws_lb_target_group.app_target_group.arn
    container_name   = "jenkins"
    container_port   = 8080
  }
  network_configuration {
    assign_public_ip = true
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.jenkins_master_security_group.id]
  }
}

resource "aws_efs_file_system" "jenkins_home_efs" {
  encrypted = true
  tags = {
    "name" = "jenkins"
  }
}

resource "aws_efs_mount_target" "jenkins_home_efs_mount_target1" {
  file_system_id  = aws_efs_file_system.jenkins_home_efs.id
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.efs_security_group.id]
}

resource "aws_efs_mount_target" "jenkins_home_efs_mount_target2" {
  file_system_id  = aws_efs_file_system.jenkins_home_efs.id
  subnet_id       = module.vpc.public_subnets[1]
  security_groups = [aws_security_group.efs_security_group.id]
}

resource "aws_efs_access_point" "jenkins_home_efs_access_point" {
  file_system_id = aws_efs_file_system.jenkins_home_efs.id
  posix_user {
    uid = 1000
    gid = 1000
  }
  root_directory {
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
    path = "/jenkins-home"
  }
}

resource "aws_cloudwatch_log_group" "jenkins_log_group" {
  name              = "jenkins-log-group"
  retention_in_days = 1
}


