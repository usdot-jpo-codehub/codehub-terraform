locals {
  api_security_groups = ["sg-07c4054e6ca310400"]
  api_port            = 3000
  api_image           = "797335914619.dkr.ecr.us-east-1.amazonaws.com/dev-codehub/codehub-api:latest"
}

resource "aws_lb" "codehub_prod_api_lb" {
  name               = "codehub-prod-api-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = "${local.api_security_groups}"
  subnets            = "${local.prod_private_subnets}"
}

resource "aws_lb_listener" "codehub_prod_api_lb_listener" {
  load_balancer_arn = "${aws_lb.codehub_prod_api_lb.arn}"
  port              = "${local.api_port}"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.codehub_prod_api_tg_1.arn}"
  }
}

resource "aws_lb_target_group" "codehub_prod_api_tg_1" {
  name        = "codehub-prod-api-tg-1"
  port        = "${local.api_port}"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${local.prod_vpc_id}"
  depends_on  = ["aws_lb.codehub_prod_api_lb"]
}

resource "aws_ecs_task_definition" "codehub_prod_api_taskdef" {
  family                = "codehub-prod-api-taskdef"
  container_definitions = <<EOF
    [
      {
        "name": "codehub-prod-api",
        "image": "${local.api_image}",
        "cpu": 256,
        "memory": 512,
        "essential": true,
        "portMappings": [
          {
            "containerPort": ${local.api_port},
            "protocol": "tcp"
          }
        ]
      }
    ]
    EOF

  task_role_arn            = "${local.prod_task_role_arn}"
  execution_role_arn       = "${local.prod_execution_role_arn}"
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_service" "codehub_prod_api" {
  name            = "codehub-prod-api"
  cluster         = "${aws_ecs_cluster.codehub_prod_cluster.id}"
  task_definition = "${aws_ecs_task_definition.codehub_prod_api_taskdef.arn}"
  desired_count   = 1

  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.codehub_prod_api_tg_1.arn}"
    container_name   = "codehub-prod-api"
    container_port   = "${local.api_port}"
  }

  network_configuration {
    security_groups = "${local.api_security_groups}"
    subnets         = "${local.prod_private_subnets}"
  }
}

