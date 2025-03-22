
resource "aws_ecs_cluster" "progate_ecs_cluster" {
  name = "progate-ecs-cluster"

  tags = {
    Name = "ProgateECSCluster"
  }
}

resource "aws_ecs_task_definition" "progate_td" {
  family                   = "progete-ecs-task"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = [var.lounch_type]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "progate-container"
      image     = "koheiota0811/aws-progate:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name: "BASE_URL"
          value: "https://phantom-frame.potekichi.net"
        },
        {
          name: "NEXT_PUBLIC_APP_URL"
          value: "https://phantom-frame.potekichi.net"
        }
      ]
    }
  ])

  tags = {
    Name = "ProgateTaskDefinition"
  }
}

resource "aws_ecs_service" "progate_service" {
  name            = "progate-service"
  cluster         = aws_ecs_cluster.progate_ecs_cluster.id
  task_definition = aws_ecs_task_definition.progate_td.arn
  desired_count   = var.desired_count
  launch_type     = var.lounch_type

  network_configuration {
    subnets          = [aws_subnet.progate_subnet_a.id, aws_subnet.progate_subnet_b.id]
    security_groups  = [aws_security_group.progate_ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.progate_tg.arn
    container_name   = "progate-container"
    container_port   = 3000
  }

  tags = {
    Name = "ProgateService"
  }
}


