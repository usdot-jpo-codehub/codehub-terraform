locals {
  ui_security_groups = ["sg-05c26dc635daecd3a"]
  ui_port            = 80
  ui_image           = "797335914619.dkr.ecr.us-east-1.amazonaws.com/dev-codehub/codehub-ui:latest"
}

resource "aws_lb" "codehub_prod_ui_lb" {
  name               = "codehub-prod-ui-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = "${local.ui_security_groups}"
  subnets            = "${local.prod_private_subnets}"
}

resource "aws_lb_listener" "codehub_prod_ui_lb_listener" {
  load_balancer_arn = "${aws_lb.codehub_prod_ui_lb.arn}"
  port              = "${local.ui_port}"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.codehub_prod_ui_tg_1.arn}"
  }
}

resource "aws_lb_target_group" "codehub_prod_ui_tg_1" {
  name        = "codehub-prod-ui-tg-1"
  port        = "${local.ui_port}"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${local.prod_vpc_id}"
  depends_on  = ["aws_lb.codehub_prod_ui_lb"]
}

resource "aws_ecs_task_definition" "codehub_prod_ui_taskdef" {
  family                = "codehub-prod-ui-taskdef"
  container_definitions = <<EOF
    [
      {
        "name": "codehub-prod-ui",
        "image": "${local.ui_image}",
        "cpu": 256,
        "memory": 512,
        "essential": true,
        "portMappings": [
          {
            "containerPort": ${local.ui_port},
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

resource "aws_ecs_service" "codehub_prod_ui" {
  name            = "codehub-prod-ui"
  cluster         = "${aws_ecs_cluster.codehub_prod_cluster.id}"
  task_definition = "${aws_ecs_task_definition.codehub_prod_ui_taskdef.arn}"
  desired_count   = 1

  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.codehub_prod_ui_tg_1.arn}"
    container_name   = "codehub-prod-ui"
    container_port   = "${local.ui_port}"
  }

  network_configuration {
    security_groups = "${local.ui_security_groups}"
    subnets         = "${local.prod_private_subnets}"
  }
}

