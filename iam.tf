resource "aws_iam_role" "jenkins_role" {
  name = "jenkins_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  path               = "/"
}

resource "aws_iam_role" "jenkins_execution_role" {
  name = "jenkins_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  path               = "/"
}

resource "aws_iam_policy" "jenkins_container_policy" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite"
      ],
      "Effect": "Allow",
      "Resource": "${aws_efs_file_system.jenkins_home_efs.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "jenkins_task_execution_policy" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
  EOF
}



resource "aws_iam_policy_attachment" "attachment1" {
  name       = "attachment_policy1"
  roles      = [aws_iam_role.jenkins_role.id]
  policy_arn = aws_iam_policy.jenkins_container_policy.arn
}

resource "aws_iam_policy_attachment" "attachment2" {
  name       = "attachment_policy1"
  roles      = [aws_iam_role.jenkins_execution_role.id]
  policy_arn = aws_iam_policy.jenkins_task_execution_policy.arn
}
