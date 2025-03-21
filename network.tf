resource "aws_vpc" "progate_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ProgateVpc"
  }
}

resource "aws_internet_gateway" "progate_igw" {
  vpc_id = aws_vpc.progate_vpc.id
  tags = {
    Name = "ProgateIGW"
  }
}

resource "aws_subnet" "progate_subnet_a" {
  vpc_id            = aws_vpc.progate_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Name = "ProgateSubnetA"
  }
}
resource "aws_subnet" "progate_subnet_b" {
  vpc_id            = aws_vpc.progate_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}b"
  tags = {
    Name = "ProgateSubnetB"
  }
}

resource "aws_route_table" "progate_route_table" {
  vpc_id = aws_vpc.progate_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.progate_igw.id
  }

  tags = {
    Name = "ProgateRouteTable"
  }
}

resource "aws_route_table_association" "progate_route_table_association_a" {
  subnet_id      = aws_subnet.progate_subnet_a.id
  route_table_id = aws_route_table.progate_route_table.id
}

resource "aws_route_table_association" "progate_route_table_association_b" {
  subnet_id      = aws_subnet.progate_subnet_b.id
  route_table_id = aws_route_table.progate_route_table.id
}

resource "aws_lb" "progate_alb" {
  name               = "progate-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.progate_lb_sg.id]
  subnets            = [aws_subnet.progate_subnet_a.id, aws_subnet.progate_subnet_b.id] # 必要に応じて複数サブネットを指定

  tags = {
    Name = "ProgateALB"
  }
}

resource "aws_lb_target_group" "progate_tg" {
  name        = "progate-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.progate_vpc.id
  target_type = "ip" # Fargate タスクの場合は "ip" を指定

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "ProgateTargetGroup"
  }
}

resource "aws_lb_listener" "progate_listener" {
  load_balancer_arn = aws_lb.progate_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.progate_tg.arn
  }
}


resource "aws_security_group" "progate_lb_sg" {
  name        = "progate-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.progate_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 全てのIPからのHTTPアクセスを許可
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # 全てのIPへの通信を許可
  }

  tags = {
    Name = "ProgateLBSecurityGroup"
  }
}

resource "aws_security_group" "progate_ecs_sg" {
  name        = "progate-ecs-sg"
  description = "Allow traffic from ALB to ECS tasks"
  vpc_id      = aws_vpc.progate_vpc.id

  # ALB からのトラフィックを許可
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.progate_lb_sg.id] # ALB のセキュリティグループからのトラフィックを許可
  }

  # ECS タスクからのアウトバウンド通信を許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ProgateECSSecurityGroup"
  }
}