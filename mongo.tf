locals {
  mongo_security_groups = ["sg-08fabf4b8e245f97d"]
  mongo_port            = 27017
  mongo_image           = "797335914619.dkr.ecr.us-east-1.amazonaws.com/codehub-mongo:600d7f1"
}

resource "aws_lb" "codehub_prod_mongo_lb" {
  name               = "codehub-prod-mongo-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = "${local.mongo_security_groups}"
  subnets            = "${local.prod_private_subnets}"
}

resource "aws_lb_listener" "codehub_prod_mongo_lb_listener" {
  load_balancer_arn = "${aws_lb.codehub_prod_mongo_lb.arn}"
  port              = "${local.mongo_port}"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.codehub_prod_mongo_tg_1.arn}"
  }
}

resource "aws_lb_target_group" "codehub_prod_mongo_tg_1" {
  name        = "codehub-prod-mongo-tg-1"
  port        = "${local.mongo_port}"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${local.prod_vpc_id}"
  depends_on  = ["aws_lb.codehub_prod_mongo_lb"]
}

resource "aws_ecs_task_definition" "codehub_prod_mongo_taskdef" {
  family                = "codehub-prod-mongo-taskdef"
  container_definitions = <<EOF
    [
      {
        "name": "codehub-prod-mongo",
        "image": "${local.mongo_image}",
        "cpu": 256,
        "memory": 512,
        "essential": true,
        "portMappings": [
          {
            "containerPort": ${local.mongo_port},
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

resource "aws_ecs_service" "codehub_prod_mongo" {
  name            = "codehub-prod-mongo"
  cluster         = "${aws_ecs_cluster.codehub_prod_cluster.id}"
  task_definition = "${aws_ecs_task_definition.codehub_prod_mongo_taskdef.arn}"
  desired_count   = 1

  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.codehub_prod_mongo_tg_1.arn}"
    container_name   = "codehub-prod-mongo"
    container_port   = "${local.mongo_port}"
  }

  network_configuration {
    security_groups = "${local.mongo_security_groups}"
    subnets         = "${local.prod_private_subnets}"
  }
}

