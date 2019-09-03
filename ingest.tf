locals {
  ingest_security_groups = ["sg-09a73c240abbb13eb"]
  ingest_image           = "797335914619.dkr.ecr.us-east-1.amazonaws.com/codehub-ingest:db34480"
}

resource "aws_ecs_task_definition" "codehub_prod_ingest_taskdef" {
  family                = "codehub-prod-ingest-taskdef"
  container_definitions = <<EOF
    [
      {
        "name": "codehub-prod-ingest",
        "image": "${local.ingest_image}",
        "cpu": 256,
        "memory": 512,
        "essential": true
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

resource "aws_ecs_service" "codehub_prod_ingest" {
  name            = "codehub-prod-ingest"
  cluster         = "${aws_ecs_cluster.codehub_prod_cluster.id}"
  task_definition = "${aws_ecs_task_definition.codehub_prod_ingest_taskdef.arn}"
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    security_groups = "${local.ingest_security_groups}"
    subnets         = "${local.prod_private_subnets}"
  }
}