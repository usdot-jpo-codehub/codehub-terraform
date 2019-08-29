locals {
  kindred_security_groups = ["sg-0cb726a88410cb227"]
  kindred_port            = 8082
  kindred_image           = "797335914619.dkr.ecr.us-east-1.amazonaws.com/codehub-kindred:09f48b9"
}

resource "aws_lb" "codehub_prod_kindred_lb" {
  name               = "codehub-prod-kindred-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = "${local.kindred_security_groups}"
  subnets            = "${local.prod_private_subnets}"
}

resource "aws_lb_listener" "codehub_prod_kindred_lb_listener" {
  load_balancer_arn = "${aws_lb.codehub_prod_kindred_lb.arn}"
  port              = "${local.kindred_port}"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.codehub_prod_kindred_tg_1.arn}"
  }
}

resource "aws_lb_target_group" "codehub_prod_kindred_tg_1" {
  name        = "codehub-prod-kindred-tg-1"
  port        = "${local.kindred_port}"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${local.prod_vpc_id}"
  depends_on  = ["aws_lb.codehub_prod_kindred_lb"]
}

resource "aws_ecs_task_definition" "codehub_prod_kindred_taskdef" {
  family                = "codehub-prod-kindred-taskdef"
  container_definitions = <<EOF
    [
      {
        "name": "codehub-prod-kindred",
        "image": "${local.kindred_image}",
        "cpu": 256,
        "memory": 512,
        "essential": true,
        "portMappings": [
          {
            "containerPort": ${local.kindred_port},
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

resource "aws_ecs_service" "codehub_prod_kindred" {
  name            = "codehub-prod-kindred"
  cluster         = "${aws_ecs_cluster.codehub_prod_cluster.id}"
  task_definition = "${aws_ecs_task_definition.codehub_prod_kindred_taskdef.arn}"
  desired_count   = 1

  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.codehub_prod_kindred_tg_1.arn}"
    container_name   = "codehub-prod-kindred"
    container_port   = "${local.kindred_port}"
  }

  network_configuration {
    security_groups = "${local.kindred_security_groups}"
    subnets         = "${local.prod_private_subnets}"
  }
}

