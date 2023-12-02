output "task_definition" {
    value = aws_ecs_task_definition.secrets_manager_poc.arn
}