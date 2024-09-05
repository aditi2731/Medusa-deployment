resource "aws_ecs_cluster" "medusa_cluster" {
  name = "medusa-cluster"
}

resource "aws_ecs_task_definition" "medusa_task" {
  family                   = "medusa-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "medusa",
      image     = "medusajs/medusa:latest",
      cpu       = 256,
      memory    = 512,
      essential = true,
      portMappings = [{
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }],
      environment = [
        { name = "DATABASE_URL", value = "your-database-url" }
      ]
    }
  ])
}

resource "aws_ecs_service" "medusa_service" {
  name            = "medusa-service"
  cluster         = aws_ecs_cluster.medusa_cluster.id
  task_definition = aws_ecs_task_definition.medusa_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id,aws_subnet.public_subnet_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.medusa_target_group.arn
    container_name   = "medusa" # Must match the container name in the ECS task definition
    container_port   = 80       # Ensure this is the correct port used in the container definition
  }

  #scheduling_strategy = "REPLICA"  # For ECS services, set scheduling strategy
}
