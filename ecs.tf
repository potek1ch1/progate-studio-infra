
// ECSクラスター
resource "aws_ecs_cluster" "progate_ecs_cluster" {
  name = "progate-ecs-cluster"

  tags = {
    Name = "ProgateECSCluster"
  }
}

// ECSタスク定義
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
      image     = "koheiota0811/aws-progate:rebuild-2"
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
          name : "BASE_URL"
          value : "https://phantom-frame.potekichi.net"
        },
        {
          name : "NEXT_PUBLIC_APP_URL"
          value : "https://phantom-frame.potekichi.net"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "ProgateTaskDefinition"
  }
}

// ECSサービス
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


// ECSタスク実行ロール
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

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
}


// ECSタスク実行ロールポリシーアタッチメント
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


