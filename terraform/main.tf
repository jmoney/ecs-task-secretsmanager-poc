terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.29.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"

    default_tags {
        tags = {
            owner = "jmoney"
            type = "poc"
            repo = "https://github.com/jmoney/secrets-manager-poc"
        }
    }
}

data "aws_vpc" "vpc" {
    tags = {
        Name = "${var.vpc_name}"
    }
}

# Define the IAM role for the ECS task
resource "aws_iam_role" "task_role" {
    name = "task-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                        Service = "ecs-tasks.amazonaws.com"
                }
            }
        ]
    })

    inline_policy {
        name = "task-role-policy"
        policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
                {
                    Action = [
                        "secretsmanager:GetSecretValue",
                    ]
                    Effect = "Allow"
                    Resource = [
                        "*",
                    ]
                },
                {
                    Action = [
                        "kms:Decrypt",
                    ]
                    Effect = "Allow"
                    Resource = [
                        "*",
                    ]   
                },
                {
                    Action = [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents",
                    ]
                    Effect = "Allow"
                    Resource = [
                        "arn:aws:logs:*:*:*",
                    ]
                }
            ]
        })
    }
}

resource "aws_secretsmanager_secret" "secret_key" {
    name_prefix = "secrets-manager-poc"
}

resource "aws_secretsmanager_secret_version" "secert_value" {
    secret_id = aws_secretsmanager_secret.secret_key.id
    secret_string = "hello world"
}

# Define the ECS task definition
resource "aws_ecs_task_definition" "secrets_manager_poc" {
    depends_on = [ aws_secretsmanager_secret_version.secert_value ]

    family                   = "secrets-manager-poc"
    execution_role_arn = aws_iam_role.task_role.arn
    task_role_arn = aws_iam_role.task_role.arn
    requires_compatibilities = ["EC2"]
    container_definitions    = jsonencode([{
            name      = "secrets-manager-poc"
            image     = "ghcr.io/jmoney/secrets-manager-poc:latest"
            cpu       = 256
            memory    = 512
            essential = true
            entrypoint = [
                "/app/main"
            ]
            environment = [
                {
                    name = "VISIBLE_SECRET"
                    valueFrom = aws_secretsmanager_secret.secret_key.arn
                }
            ]
            secrets = [
                {
                    name = "SECRET"
                    valueFrom = aws_secretsmanager_secret.secret_key.arn
                }
            ]
            logConfiguration = {
                logDriver = "awslogs"
                "options": {
                    "awslogs-group": "secrets-manager-poc",
                    "awslogs-region": "us-east-1",
                    "awslogs-create-group": "true",
                    "awslogs-stream-prefix": "logs"
                }
                secretOptions = []
            }
    }])
}