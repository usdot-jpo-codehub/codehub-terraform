locals {
  search_security_groups = ["sg-00546d6e3e8efe42d"]
  search_port            = 9200
  search_image           = "797335914619.dkr.ecr.us-east-1.amazonaws.com/dev-codehub/codehub-search:latest"
}

resource "aws_lb" "codehub_prod_search_lb" {
  name               = "codehub-prod-search-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = "${local.search_security_groups}"
  subnets            = "${local.prod_private_subnets}"
}

resource "aws_lb_listener" "codehub_prod_search_lb_listener" {
  load_balancer_arn = "${aws_lb.codehub_prod_search_lb.arn}"
  port              = "${local.search_port}"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.codehub_prod_search_tg_1.arn}"
  }
}

resource "aws_lb_target_group" "codehub_prod_search_tg_1" {
  name        = "codehub-prod-search-tg-1"
  port        = "${local.search_port}"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${local.prod_vpc_id}"
  depends_on  = ["aws_lb.codehub_prod_search_lb"]
}

resource "aws_ecs_task_definition" "codehub_prod_search_taskdef" {
  family                = "codehub-prod-search-taskdef"
  container_definitions = <<EOF
    [
      {
        "name": "codehub-prod-search",
        "image": "${local.search_image}",
        "cpu": 256,
        "memory": 512,
        "essential": true,
        "portMappings": [
          {
            "containerPort": ${local.search_port},
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

resource "aws_ecs_service" "codehub_prod_search" {
  name            = "codehub-prod-search"
  cluster         = "${aws_ecs_cluster.codehub_prod_cluster.id}"
  task_definition = "${aws_ecs_task_definition.codehub_prod_search_taskdef.arn}"
  desired_count   = 1

  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.codehub_prod_search_tg_1.arn}"
    container_name   = "codehub-prod-search"
    container_port   = "${local.search_port}"
  }

  network_configuration {
    security_groups = "${local.search_security_groups}"
    subnets         = "${local.prod_private_subnets}"
  }
}

